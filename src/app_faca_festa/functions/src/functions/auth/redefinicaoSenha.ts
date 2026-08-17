import * as crypto from "crypto";
import * as nodemailer from "nodemailer";
import { defineSecret } from "firebase-functions/params";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { admin } from "../../shared/firebaseAdmin";

const CODIGO_EXPIRA_EM_MINUTOS = 10;
const MAX_TENTATIVAS = 5;
const DEFAULT_REGION = "southamerica-east1";

const SMTP_HOST = defineSecret("SMTP_HOST");
const SMTP_PORT = defineSecret("SMTP_PORT");
const SMTP_USER = defineSecret("SMTP_USER");
const SMTP_PASS = defineSecret("SMTP_PASS");
const SMTP_FROM = defineSecret("SMTP_FROM");
const PASSWORD_RESET_SECRET = defineSecret("PASSWORD_RESET_SECRET");

type SolicitarCodigoData = {
  email?: unknown;
};

type RedefinirSenhaData = {
  email?: unknown;
  codigo?: unknown;
  novaSenha?: unknown;
};

export const solicitarCodigoRedefinicaoSenha = onCall(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
    secrets: [
      SMTP_HOST,
      SMTP_PORT,
      SMTP_USER,
      SMTP_PASS,
      SMTP_FROM,
      PASSWORD_RESET_SECRET,
    ],
  },
  async (request) => {
    const data = request.data as SolicitarCodigoData;
    const email = normalizarEmail(data.email);
    if (!email) {
      throw new HttpsError("invalid-argument", "Informe um e-mail válido.");
    }

    const codigo = gerarCodigo();
    const codigoHash = hashCodigo(email, codigo);
    const expiraEm = Timestamp.fromMillis(
      Date.now() + CODIGO_EXPIRA_EM_MINUTOS * 60 * 1000,
    );

    try {
      const usuario = await admin.auth().getUserByEmail(email);

      await admin
        .firestore()
        .collection("password_reset_codes")
        .doc(email)
        .set({
          uid: usuario.uid,
          email,
          codigoHash,
          tentativas: 0,
          usado: false,
          criadoEm: admin.firestore.FieldValue.serverTimestamp(),
          expiraEm,
        });

      await enviarEmailCodigo(email, codigo);
    } catch (error) {
      if (isAuthUserNotFound(error)) {
        return {
          ok: true,
          message:
            "Se o e-mail estiver cadastrado, enviaremos um código de redefinição.",
        };
      }

      console.error("[redefinicaoSenha] Erro ao solicitar código:", error);
      if (isSmtpNaoConfigurado(error)) {
        throw new HttpsError(
          "failed-precondition",
          "Envio de e-mail ainda não configurado no servidor.",
        );
      }

      throw new HttpsError(
        "internal",
        "Não foi possível enviar o código agora. Tente novamente.",
      );
    }

    return {
      ok: true,
      message:
        "Se o e-mail estiver cadastrado, enviaremos um código de redefinição.",
    };
  },
);

export const redefinirSenhaComCodigo = onCall(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
    secrets: [PASSWORD_RESET_SECRET],
  },
  async (request) => {
    const data = request.data as RedefinirSenhaData;
    const email = normalizarEmail(data.email);
    const codigo = normalizarCodigo(data.codigo);
    const novaSenha = normalizarSenha(data.novaSenha);

    if (!email || codigo.length !== 6) {
      throw new HttpsError("invalid-argument", "Código inválido.");
    }

    if (novaSenha.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "A nova senha deve ter pelo menos 6 caracteres.",
      );
    }

    const referencia = admin
      .firestore()
      .collection("password_reset_codes")
      .doc(email);

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(referencia);
      if (!snapshot.exists) {
        throw new HttpsError("not-found", "Solicite um novo código.");
      }

      const dados = snapshot.data();
      const uid = texto(dados?.uid);
      const usado = dados?.usado === true;
      const tentativas = Number(dados?.tentativas ?? 0);
      const expiraEm = dados?.expiraEm as Timestamp | undefined;

      if (!uid || usado) {
        throw new HttpsError("failed-precondition", "Solicite um novo código.");
      }

      if (!expiraEm || expiraEm.toMillis() < Date.now()) {
        throw new HttpsError("deadline-exceeded", "Código expirado.");
      }

      if (tentativas >= MAX_TENTATIVAS) {
        throw new HttpsError(
          "resource-exhausted",
          "Muitas tentativas. Solicite um novo código.",
        );
      }

      const codigoHash = texto(dados?.codigoHash);
      if (codigoHash !== hashCodigo(email, codigo)) {
        transaction.update(referencia, {
          tentativas: admin.firestore.FieldValue.increment(1),
        });
        throw new HttpsError("permission-denied", "Código incorreto.");
      }

      await admin.auth().updateUser(uid, { password: novaSenha });
      transaction.update(referencia, {
        usado: true,
        usadoEm: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return {
      ok: true,
      message: "Senha redefinida com sucesso.",
    };
  },
);

function normalizarEmail(value: unknown): string {
  return texto(value).trim().toLowerCase();
}

function normalizarCodigo(value: unknown): string {
  return texto(value).replace(/\D/g, "");
}

function normalizarSenha(value: unknown): string {
  return texto(value).trim();
}

function texto(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function gerarCodigo(): string {
  return crypto.randomInt(100000, 1000000).toString();
}

function hashCodigo(email: string, codigo: string): string {
  const secret = PASSWORD_RESET_SECRET.value();
  return crypto
    .createHash("sha256")
    .update(`${email}:${codigo}:${secret}`)
    .digest("hex");
}

function isAuthUserNotFound(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code?: unknown }).code === "auth/user-not-found"
  );
}

function isSmtpNaoConfigurado(error: unknown): boolean {
  return error instanceof Error && error.message.includes("SMTP não configurado");
}

async function enviarEmailCodigo(email: string, codigo: string): Promise<void> {
  const host = SMTP_HOST.value().trim();
  const port = Number(SMTP_PORT.value().trim() || "587");
  const user = SMTP_USER.value().trim();
  const pass = SMTP_PASS.value().replace(/\s/g, "");
  const from = (SMTP_FROM.value() || user).trim();

  if (!host || !user || !pass || !from) {
    throw new Error(
      "SMTP não configurado. Defina SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS e SMTP_FROM.",
    );
  }

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });

  await transporter.sendMail({
    from,
    to: email,
    subject: "Código para redefinir sua senha - Faça a Festa",
    text:
      `Seu código para redefinir a senha é ${codigo}.\n\n` +
      `Ele expira em ${CODIGO_EXPIRA_EM_MINUTOS} minutos.`,
    html:
      "<p>Seu código para redefinir a senha é:</p>" +
      `<p style="font-size:28px;font-weight:700;letter-spacing:4px">${codigo}</p>` +
      `<p>Ele expira em ${CODIGO_EXPIRA_EM_MINUTOS} minutos.</p>`,
  });
}
