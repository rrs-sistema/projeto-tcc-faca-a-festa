import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { exigirLoginComSenha, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";
import { registrarAuditTrailSeguro } from "../auditoria/auditTrailService";
import {
  cifrarTexto,
  decifrarTexto,
  gerarSecretTotp,
  montarOtpauthUrl,
  verificarTotp,
} from "../../shared/totp";

const REGION = "southamerica-east1";
const ISSUER = "Faça a Festa";
const MAX_TENTATIVAS = 5;
const PASSWORD_RESET_SECRET = defineSecret("PASSWORD_RESET_SECRET");

type CodigoData = {
  codigo?: unknown;
};

export const iniciarTotpMfa = onCall(
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

    const chave = exigirChaveMestra();
    const secret = gerarSecretTotp();
    const record = await admin.auth().getUser(perfil.uid);
    const email = (record.email ?? "").trim().toLowerCase();

    await referenciaTotp(perfil.uid).set(
      {
        uid: perfil.uid,
        secretCifrado: cifrarTexto(secret, chave),
        pendente: true,
        ativo: false,
        tentativas: 0,
        atualizadoEm: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await registrarAuditTrailSeguro({
      acao: "MFA_TOTP_INICIADO",
      operacao: "created",
      entidadeTipo: "acesso",
      entidadeId: perfil.uid,
      entidadeNome: email,
      actorUid: perfil.uid,
      actorAuthType: request.auth?.uid ? "unknown" : "unauthenticated",
      documentPath: `mfa_totp/${perfil.uid}`,
      after: {
        fluxo: "mfa_totp",
        status: "configuracao_iniciada",
      },
    });

    return {
      ok: true,
      secret,
      otpauthUrl: montarOtpauthUrl({ secret, email, issuer: ISSUER }),
      issuer: ISSUER,
    };
  },
);

export const confirmarTotpMfa = onCall(
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

    await validarCodigoTotp(perfil.uid, codigo, { exigirPendente: true });

    await referenciaTotp(perfil.uid).set(
      {
        pendente: false,
        ativo: true,
        tentativas: 0,
        confirmadoEm: admin.firestore.FieldValue.serverTimestamp(),
        atualizadoEm: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await admin.firestore().collection("usuarios").doc(perfil.uid).set(
      {
        mfa_totp_ativo: true,
        mfa_email_ativo: false,
        mfa_metodo: "totp",
      },
      { merge: true },
    );

    await registrarAuditTrailSeguro({
      acao: "MFA_TOTP_CONFIRMADO",
      operacao: "updated",
      entidadeTipo: "acesso",
      entidadeId: perfil.uid,
      actorUid: perfil.uid,
      actorAuthType: request.auth?.uid ? "unknown" : "unauthenticated",
      documentPath: `usuarios/${perfil.uid}`,
      before: { mfa_metodo: "nenhum" },
      after: { mfa_metodo: "totp", mfa_totp_ativo: true },
    });

    return { ok: true };
  },
);

export const verificarTotpMfa = onCall(
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

    await validarCodigoTotp(perfil.uid, codigo, { exigirPendente: false });

    await referenciaTotp(perfil.uid).update({
      tentativas: 0,
      verificadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    await registrarAuditTrailSeguro({
      acao: "MFA_TOTP_VERIFICADO",
      operacao: "updated",
      entidadeTipo: "acesso",
      entidadeId: perfil.uid,
      actorUid: perfil.uid,
      actorAuthType: request.auth?.uid ? "unknown" : "unauthenticated",
      documentPath: `mfa_totp/${perfil.uid}`,
      before: { fluxo: "mfa_totp", status: "pendente" },
      after: { fluxo: "mfa_totp", status: "verificado" },
    });

    return { ok: true };
  },
);

function referenciaTotp(uid: string) {
  return admin.firestore().collection("mfa_totp").doc(uid);
}

async function validarCodigoTotp(
  uid: string,
  codigo: string,
  opcoes: { exigirPendente: boolean },
): Promise<void> {
  if (codigo.length !== 6) {
    throw new HttpsError("invalid-argument", "Informe o código de 6 dígitos.");
  }

  const referencia = referenciaTotp(uid);
  const snapshot = await referencia.get();
  if (!snapshot.exists) {
    throw new HttpsError("failed-precondition", "Configure o autenticador.");
  }

  const dados = snapshot.data() ?? {};
  const ativo = dados.ativo === true;
  const pendente = dados.pendente === true;
  const tentativas = Number(dados.tentativas ?? 0);
  const secretCifrado = typeof dados.secretCifrado === "string"
    ? dados.secretCifrado
    : "";

  if (opcoes.exigirPendente && !pendente) {
    throw new HttpsError(
      "failed-precondition",
      "Gere um novo QR Code para continuar.",
    );
  }

  if (!opcoes.exigirPendente && !ativo) {
    throw new HttpsError(
      "failed-precondition",
      "O autenticador ainda não foi confirmado.",
    );
  }

  if (tentativas >= MAX_TENTATIVAS) {
    throw new HttpsError(
      "resource-exhausted",
      "Muitas tentativas. Aguarde e tente novamente.",
    );
  }

  if (!secretCifrado) {
    throw new HttpsError("failed-precondition", "Configure o autenticador.");
  }

  let secret = "";
  try {
    secret = decifrarTexto(secretCifrado, exigirChaveMestra());
  } catch (error) {
    console.error("[totpMfa] Falha ao decifrar segredo:", error);
    throw new HttpsError("internal", "Não foi possível validar o código.");
  }

  if (!verificarTotp(secret, codigo)) {
    await referencia.update({
      tentativas: admin.firestore.FieldValue.increment(1),
      atualizadoEm: Timestamp.now(),
    });
    throw new HttpsError("permission-denied", "Código incorreto.");
  }
}

function exigirChaveMestra(): string {
  const chave = PASSWORD_RESET_SECRET.value().trim();
  if (!chave) {
    throw new HttpsError(
      "failed-precondition",
      "Autenticador ainda não configurado no servidor.",
    );
  }
  return chave;
}

function normalizarCodigo(value: unknown): string {
  return typeof value === "string" ? value.replace(/\D/g, "") : "";
}
