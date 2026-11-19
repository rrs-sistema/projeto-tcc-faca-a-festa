import { createHmac, timingSafeEqual } from "crypto";
import { defineSecret } from "firebase-functions/params";
import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { DocumentData, Transaction, Timestamp } from "firebase-admin/firestore";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";
import { referenciaSessaoMfa } from "../../shared/politicaMfa";

export const PASSWORD_RESET_SECRET = defineSecret("PASSWORD_RESET_SECRET");

export const OPCOES_MFA = {
  region: "southamerica-east1",
  timeoutSeconds: 30,
  memory: "256MiB" as const,
  cors: true,
  secrets: [PASSWORD_RESET_SECRET],
};

type SessaoMfa = { uid: string; autenticadaEm: number };
export type DadosMfa = { codigo?: unknown; autorizacao?: unknown };
type MetodoMfa = "totp" | "email";

export async function obterSessaoMfa(request: CallableRequest): Promise<SessaoMfa> {
  const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
  if (request.auth?.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("permission-denied", "Entre com sua conta para configurar a proteção.");
  }
  const autenticadaEm = request.auth?.token.auth_time;
  if (typeof autenticadaEm !== "number") {
    throw new HttpsError("unauthenticated", "Entre novamente na sua conta.");
  }
  return { uid: perfil.uid, autenticadaEm };
}

export function chaveMfa(): string {
  const chave = PASSWORD_RESET_SECRET.value().trim();
  if (!chave) {
    throw new HttpsError("failed-precondition", "Verificação indisponível no servidor.");
  }
  return chave;
}

export function referenciaPerfilMfa(uid: string) {
  return admin.firestore().collection("usuarios").doc(uid);
}

export async function lerPerfilMfa(tx: Transaction, uid: string): Promise<DocumentData> {
  const perfil = (await tx.get(referenciaPerfilMfa(uid))).data();
  if (!perfil || perfil.ativo === false) {
    throw new HttpsError("permission-denied", "A conta não está disponível.");
  }
  return perfil;
}

export function temMetodo(perfil: DocumentData, metodo: MetodoMfa): boolean {
  return perfil[`mfa_${metodo}_ativo`] === true;
}

export function exigirMetodoAtivo(perfil: DocumentData, metodo: MetodoMfa): void {
  if (!temMetodo(perfil, metodo)) {
    throw new HttpsError("failed-precondition", "Esse método ainda não foi cadastrado.");
  }
}

export function exigirCadastroPermitido(
  perfil: DocumentData,
  metodo: MetodoMfa,
  sessao: SessaoMfa,
  autorizacao: unknown,
): void {
  if (temMetodo(perfil, metodo)) {
    throw new HttpsError("failed-precondition", "Esse método já está cadastrado.");
  }
  if (temMetodo(perfil, "email") || temMetodo(perfil, "totp")) {
    exigirAutorizacaoMfa(sessao, autorizacao);
  }
}

export async function confirmarVerificacaoMfa(sessao: SessaoMfa) {
  // Sessões paralelas da mesma conta mantêm verificações independentes.
  await referenciaSessaoMfa(sessao.uid, sessao.autenticadaEm).set({
    expiraEm: Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000),
  });
  const expiraEm = Date.now() + 10 * 60 * 1000;
  return { ok: true, autorizacao: `${expiraEm}.${assinatura(sessao, expiraEm)}` };
}

export function exigirAutorizacaoMfa(sessao: SessaoMfa, autorizacao: unknown): void {
  const partes = typeof autorizacao === "string"
    ? /^(\d{13})\.([a-f0-9]{64})$/.exec(autorizacao)
    : null;
  if (partes) {
    const expiraEm = Number(partes[1]);
    if (expiraEm > Date.now() && timingSafeEqual(
      Buffer.from(partes[2], "hex"), Buffer.from(assinatura(sessao, expiraEm), "hex"),
    )) return;
  }
  throw new HttpsError("permission-denied", "Confirme um método cadastrado para continuar.");
}

function assinatura(sessao: SessaoMfa, expiraEm: number): string {
  return createHmac("sha256", chaveMfa())
    .update(JSON.stringify(["mfa-gestao", sessao.uid, sessao.autenticadaEm, expiraEm]))
    .digest("hex");
}

export function codigoSeisDigitos(value: unknown): string {
  const codigo = typeof value === "string" ? value.replace(/\D/g, "") : "";
  if (codigo.length !== 6) {
    throw new HttpsError("invalid-argument", "Informe o código de 6 dígitos.");
  }
  return codigo;
}
