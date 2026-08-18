import { HttpsError } from "firebase-functions/v2/https";
import { admin } from "./firebaseAdmin";

export type PerfilAuth = {
  uid: string;
  tipo: string;
  ativo: boolean;
};

export async function exigirUsuarioAutenticado(
  uid: string | undefined,
): Promise<PerfilAuth> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }

  const snapshot = await admin.firestore().collection("usuarios").doc(uid).get();
  if (!snapshot.exists) {
    throw new HttpsError("permission-denied", "Perfil não encontrado.");
  }

  const data = snapshot.data() ?? {};
  const ativo = data.ativo !== false;
  if (!ativo) {
    throw new HttpsError("permission-denied", "Esta conta está desativada.");
  }

  const tipo = typeof data.tipo === "string" ? data.tipo.trim() : "";
  return { uid, tipo, ativo };
}

export function exigirTipo(perfil: PerfilAuth, tipos: string[]): void {
  if (!tipos.includes(perfil.tipo)) {
    throw new HttpsError(
      "permission-denied",
      "Você não tem permissão para esta ação.",
    );
  }
}

export async function exigirLoginComSenha(uid: string): Promise<void> {
  const record = await admin.auth().getUser(uid);
  const temSenha = record.providerData.some(
    (provider) => provider.providerId === "password",
  );
  if (!temSenha) {
    throw new HttpsError(
      "failed-precondition",
      "Esta verificação é exclusiva do login com e-mail e senha.",
    );
  }
}

