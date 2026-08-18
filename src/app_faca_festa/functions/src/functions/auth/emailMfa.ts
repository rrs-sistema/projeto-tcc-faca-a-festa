import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import {
  exigirLoginComSenha,
  exigirUsuarioAutenticado,
} from "../../shared/auth";
import {
  SECRETS_SMTP,
  enviarEmailCodigo,
  isSmtpNaoConfigurado,
} from "../../shared/emailCodigo";
import { admin } from "../../shared/firebaseAdmin";

const REGION = "southamerica-east1";
const CODIGO_EXPIRA_EM_MINUTOS = 10;
const MAX_TENTATIVAS = 5;
const INTERVALO_REENVIO_MS = 45 * 1000;
const PASSWORD_RESET_SECRET = defineSecret("PASSWORD_RESET_SECRET");

type CodigoData = {
  codigo?: unknown;
};

export const solicitarCodigoEmailMfa = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
    secrets: [...SECRETS_SMTP, PASSWORD_RESET_SECRET],
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    await exigirLoginComSenha(perfil.uid);

    const record = await admin.auth().getUser(perfil.uid);
    const email = (record.email ?? "").trim().toLowerCase();
    if (!email) {
      throw new HttpsError(
        "failed-precondition",
        "Sua conta não possui e-mail para receber o código.",
      );
    }

    const referencia = referenciaEmail(perfil.uid);
    const atual = await referencia.get();
    const enviadoEm = atual.data()?.enviadoEm as Timestamp | undefined;
    if (
      enviadoEm &&
      Date.now() - enviadoEm.toMillis() < INTERVALO_REENVIO_MS
    ) {
      return {
        ok: true,
        emailMascarado: mascararEmail(email),
        message: "Já enviamos um código recentemente. Aguarde um instante.",
      };
    }

    const codigo = crypto.randomInt(100000, 1000000).toString();
    const expiraEm = Timestamp.fromMillis(
      Date.now() + CODIGO_EXPIRA_EM_MINUTOS * 60 * 1000,
    );

    await referencia.set({
      uid: perfil.uid,
      email,
      codigoHash: hashCodigo(email, codigo),
      tentativas: 0,
      usado: false,
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
      enviadoEm: Timestamp.now(),
      expiraEm,
    });

    try {
      await enviarEmailCodigo({
        para: email,
        assunto: "Código de verificação - Faça a Festa",
        texto:
          `Seu código de verificação é ${codigo}.\n\n` +
          `Ele expira em ${CODIGO_EXPIRA_EM_MINUTOS} minutos.`,
        html:
          "<p>Seu código de verificação é:</p>" +
          `<p style="font-size:28px;font-weight:700;letter-spacing:4px">${codigo}</p>` +
          `<p>Ele expira em ${CODIGO_EXPIRA_EM_MINUTOS} minutos.</p>`,
      });
    } catch (error) {
      console.error("[emailMfa] Erro ao enviar código:", error);
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
      emailMascarado: mascararEmail(email),
      message: "Enviamos um código para o e-mail da sua conta.",
    };
  },
);

export const confirmarEmailMfa = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
    secrets: [PASSWORD_RESET_SECRET],
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    await exigirLoginComSenha(perfil.uid);
    const codigo = normalizarCodigo((request.data as CodigoData).codigo);
    await validarCodigoEmail(perfil.uid, codigo);

    await admin.firestore().collection("usuarios").doc(perfil.uid).set(
      {
        mfa_email_ativo: true,
        mfa_totp_ativo: false,
        mfa_metodo: "email",
      },
      { merge: true },
    );

    return { ok: true };
  },
);

export const verificarEmailMfa = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
    secrets: [PASSWORD_RESET_SECRET],
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    await exigirLoginComSenha(perfil.uid);
    const codigo = normalizarCodigo((request.data as CodigoData).codigo);
    await validarCodigoEmail(perfil.uid, codigo);
    return { ok: true };
  },
);

function referenciaEmail(uid: string) {
  return admin.firestore().collection("mfa_email_codes").doc(uid);
}

async function validarCodigoEmail(uid: string, codigo: string): Promise<void> {
  if (codigo.length !== 6) {
    throw new HttpsError("invalid-argument", "Informe o código de 6 dígitos.");
  }

  const referencia = referenciaEmail(uid);
  const snapshot = await referencia.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Solicite um novo código.");
  }

  const dados = snapshot.data() ?? {};
  const email = typeof dados.email === "string" ? dados.email : "";
  const usado = dados.usado === true;
  const tentativas = Number(dados.tentativas ?? 0);
  const expiraEm = dados.expiraEm as Timestamp | undefined;
  const codigoHash = typeof dados.codigoHash === "string" ? dados.codigoHash : "";

  if (!email || usado) {
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
  if (codigoHash !== hashCodigo(email, codigo)) {
    await referencia.update({
      tentativas: admin.firestore.FieldValue.increment(1),
    });
    throw new HttpsError("permission-denied", "Código incorreto.");
  }

  await referencia.update({
    usado: true,
    usadoEm: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function hashCodigo(email: string, codigo: string): string {
  const secret = PASSWORD_RESET_SECRET.value().trim();
  if (!secret) {
    throw new HttpsError(
      "failed-precondition",
      "Verificação por e-mail ainda não configurada no servidor.",
    );
  }
  return crypto
    .createHash("sha256")
    .update(`${email}:${codigo}:${secret}`)
    .digest("hex");
}

function normalizarCodigo(value: unknown): string {
  return typeof value === "string" ? value.replace(/\D/g, "") : "";
}

function mascararEmail(email: string): string {
  const [usuario, dominio] = email.split("@");
  if (!usuario || !dominio) return email;
  const prefixo = usuario.slice(0, 2);
  return `${prefixo}***@${dominio}`;
}
