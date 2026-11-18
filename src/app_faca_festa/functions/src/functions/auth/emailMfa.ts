import { createHash, randomInt, timingSafeEqual } from "crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { registrarAuditTrailSeguro } from "../auditoria/auditTrailService";
import { SECRETS_SMTP, enviarEmailCodigo, isSmtpNaoConfigurado } from "../../shared/emailCodigo";
import { admin } from "../../shared/firebaseAdmin";
import {
  chaveMfa, codigoSeisDigitos, confirmarVerificacaoMfa, DadosMfa,
  exigirCadastroPermitido, exigirMetodoAtivo, lerPerfilMfa, obterSessaoMfa, OPCOES_MFA,
  PASSWORD_RESET_SECRET, referenciaPerfilMfa, temMetodo,
} from "./mfaSessao";

const CODIGO_EXPIRA_EM_MINUTOS = 10;
const MAX_TENTATIVAS = 5;
const INTERVALO_REENVIO_MS = 45 * 1000;

export const solicitarCodigoEmailMfa = onCall<DadosMfa>(
  { ...OPCOES_MFA, secrets: [...SECRETS_SMTP, PASSWORD_RESET_SECRET] },
  async (request) => {
    const sessao = await obterSessaoMfa(request);
    const { uid } = sessao;
    const emailDaConta = await obterEmail(uid);
    const referencia = referenciaEmail(uid);
    const codigo = randomInt(0, 1000000).toString().padStart(6, "0");
    const { email, codigoHash } = await admin.firestore().runTransaction(async (tx) => {
      const perfil = await lerPerfilMfa(tx, uid);
      const ativo = temMetodo(perfil, "email");
      if (!ativo) exigirCadastroPermitido(perfil, "email", sessao, request.data?.autorizacao);
      const vinculo = ativo ? (await tx.get(referenciaVinculoEmail(uid))).data() : undefined;
      const email = vinculo?.email ?? emailDaConta;
      const atual = (await tx.get(referencia)).data();
      const enviadoEm = atual?.enviadoEm as Timestamp | undefined;
      const agora = Date.now();
      if (enviadoEm && agora - enviadoEm.toMillis() < INTERVALO_REENVIO_MS) {
        return { email, codigoHash: null };
      }
      const codigoHash = hashCodigo(email, codigo);
      tx.set(referencia, {
        uid, email, codigoHash, finalidade: ativo ? "login" : "cadastro",
        tentativas: 0, usado: false, criadoEm: FieldValue.serverTimestamp(),
        enviadoEm: Timestamp.fromMillis(agora),
        expiraEm: Timestamp.fromMillis(agora + CODIGO_EXPIRA_EM_MINUTOS * 60 * 1000),
      });
      return { email, codigoHash };
    });
    const emailMascarado = mascararEmail(email);
    if (!codigoHash) {
      return { ok: true, emailMascarado, message: "Um código foi solicitado recentemente. Aguarde um instante." };
    }

    try {
      await enviarEmailCodigo({
        para: email,
        assunto: "Código de verificação - Faça a Festa",
        texto: "Seu código de verificação é " + codigo + ".\n\nEle expira em 10 minutos.",
        html: "<p>Seu código de verificação é:</p>" +
          '<p style="font-size:28px;font-weight:700;letter-spacing:4px">' + codigo + "</p>" +
          "<p>Ele expira em 10 minutos.</p>",
      });
    } catch (error) {
      console.error("[emailMfa] Erro ao enviar código:", error);
      await admin.firestore().runTransaction(async (tx) => {
        const atual = (await tx.get(referencia)).data();
        if (atual?.codigoHash === codigoHash && atual.usado !== true) tx.delete(referencia);
      });
      if (isSmtpNaoConfigurado(error)) {
        throw new HttpsError("failed-precondition", "Envio de e-mail ainda não configurado no servidor.");
      }
      throw new HttpsError("internal", "Não foi possível enviar o código agora. Tente novamente.");
    }

    await auditarEmail(uid, "MFA_EMAIL_CODIGO_SOLICITADO", "codigo_enviado");
    return { ok: true, emailMascarado, message: "Enviamos um código para o e-mail da sua conta." };
  },
);

export const confirmarEmailMfa = onCall<DadosMfa>(OPCOES_MFA, (request) =>
  conferirEmail(request, true),
);

export const verificarEmailMfa = onCall<DadosMfa>(OPCOES_MFA, (request) =>
  conferirEmail(request, false),
);

async function conferirEmail(
  request: Parameters<typeof obterSessaoMfa>[0],
  cadastro: boolean,
) {
  const sessao = await obterSessaoMfa(request);
  const { uid } = sessao;
  const codigo = codigoSeisDigitos(request.data?.codigo);
  const emailDaConta = await obterEmail(uid);
  const perfilRef = referenciaPerfilMfa(uid);
  const referencia = referenciaEmail(uid);
  const vinculoRef = referenciaVinculoEmail(uid);
  const valido = await admin.firestore().runTransaction(async (tx) => {
    const perfil = await lerPerfilMfa(tx, uid);
    if (cadastro) {
      exigirCadastroPermitido(perfil, "email", sessao, request.data?.autorizacao);
    } else {
      exigirMetodoAtivo(perfil, "email");
    }
    const vinculo = cadastro ? undefined : (await tx.get(vinculoRef)).data();
    const email = vinculo?.email ?? emailDaConta;
    const dados = (await tx.get(referencia)).data();
    const finalidade = cadastro ? "cadastro" : "login";
    if (!dados || dados.email !== email || dados.usado ||
        (dados.finalidade && dados.finalidade !== finalidade)) {
      throw new HttpsError("failed-precondition", "Solicite um novo código.");
    }
    const expiraEm = dados.expiraEm as Timestamp | undefined;
    if (!expiraEm || expiraEm.toMillis() <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "Código expirado.");
    }
    const tentativas = Number(dados.tentativas ?? 0);
    if (tentativas >= MAX_TENTATIVAS) {
      throw new HttpsError("resource-exhausted", "Muitas tentativas. Solicite um novo código.");
    }
    const hash = typeof dados.codigoHash === "string" ? dados.codigoHash : "";
    if (!/^[a-f0-9]{64}$/.test(hash) || !timingSafeEqual(
      Buffer.from(hash, "hex"), Buffer.from(hashCodigo(email, codigo), "hex"),
    )) {
      tx.update(referencia, { tentativas: tentativas + 1 });
      return false;
    }
    tx.update(referencia, { usado: true, usadoEm: FieldValue.serverTimestamp() });
    // O e-mail do fator só muda por um novo vínculo confirmado pelo servidor.
    if (!vinculo) tx.set(vinculoRef, { email, confirmadoEm: FieldValue.serverTimestamp() });
    if (cadastro) {
      tx.update(perfilRef, {
        mfa_email_ativo: true,
        mfa_metodo: temMetodo(perfil, "totp") ? "totp" : "email",
      });
    }
    return true;
  });
  if (!valido) throw new HttpsError("permission-denied", "Código incorreto.");
  await auditarEmail(uid, cadastro ? "MFA_EMAIL_CONFIRMADO" : "MFA_EMAIL_VERIFICADO",
    cadastro ? "configurado" : "verificado");
  return confirmarVerificacaoMfa(sessao);
}

function referenciaEmail(uid: string) {
  return admin.firestore().collection("mfa_email_codes").doc(uid);
}

function referenciaVinculoEmail(uid: string) {
  return admin.firestore().collection("mfa_email_vinculos").doc(uid);
}

async function obterEmail(uid: string): Promise<string> {
  const record = await admin.auth().getUser(uid);
  const email = (record.email ?? "").trim().toLowerCase();
  if (!email) throw new HttpsError("failed-precondition", "Sua conta não possui e-mail para receber o código.");
  return email;
}

function hashCodigo(email: string, codigo: string): string {
  // Mantém a compatibilidade com códigos enviados antes da atualização.
  return createHash("sha256").update([email, codigo, chaveMfa()].join(":")).digest("hex");
}

function mascararEmail(email: string): string {
  const [usuario, dominio] = email.split("@");
  return usuario.slice(0, 2) + "***@" + dominio;
}

function auditarEmail(uid: string, acao: string, status: string) {
  return registrarAuditTrailSeguro({
    acao,
    operacao: status === "codigo_enviado" ? "created" : "updated",
    entidadeTipo: "acesso",
    entidadeId: uid,
    actorUid: uid,
    actorAuthType: "unknown",
    documentPath: "mfa_email_codes/" + uid,
    after: { fluxo: "mfa_email", status },
  });
}
