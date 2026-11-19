import { HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { DocumentData, Timestamp } from "firebase-admin/firestore";
import { admin } from "./firebaseAdmin";

export function exigeMfaNoLogin(perfil: DocumentData): boolean {
  return perfil.tipo === "A" || perfil.tipo === "F" || perfil.mfa_login_opcional === true;
}

export function referenciaSessaoMfa(uid: string, autenticadaEm: number) {
  return admin.firestore().collection("mfa_sessoes").doc(uid)
    .collection("autenticacoes").doc(String(autenticadaEm));
}

export async function sessaoMfaVerificada(auth: CallableRequest["auth"]): Promise<boolean> {
  const autenticadaEm = auth?.token.auth_time;
  if (!auth?.uid || typeof autenticadaEm !== "number" ||
      !Number.isSafeInteger(autenticadaEm) || autenticadaEm <= 0) return false;
  const dados = (await referenciaSessaoMfa(auth.uid, autenticadaEm).get()).data();
  return dados?.expiraEm instanceof Timestamp && dados.expiraEm.toMillis() > Date.now();
}

export async function exigirMfaDaRequisicao(request: CallableRequest): Promise<void> {
  if (!request.auth) return; // A autorização própria de cada endpoint trata visitantes.
  const perfil = (await admin.firestore().collection("usuarios").doc(request.auth.uid).get()).data();
  if (!perfil || perfil.ativo === false) {
    throw new HttpsError("permission-denied", "A conta não está disponível.");
  }
  if (exigeMfaNoLogin(perfil) && !await sessaoMfaVerificada(request.auth)) {
    throw new HttpsError("permission-denied", "Confirme a verificação em duas etapas para continuar.",
      { motivo: "mfa-obrigatorio" });
  }
}
