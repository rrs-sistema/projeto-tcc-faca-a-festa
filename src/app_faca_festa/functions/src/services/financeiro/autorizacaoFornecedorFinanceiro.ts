import { HttpsError } from "firebase-functions/v2/https";
import { Firestore } from "firebase-admin/firestore";
import { PerfilAuth } from "../../shared/auth";

/**
 * Financeiro privado do fornecedor: somente o proprietário (uid == idFornecedor).
 * Organizador, outro fornecedor e admin de plataforma NÃO recebem acesso automático.
 */
export async function exigirAcessoFinanceiroFornecedor(
  db: Firestore,
  perfil: PerfilAuth,
  idFornecedor: string,
): Promise<void> {
  exigirVinculoFinanceiroFornecedor(perfil.uid, idFornecedor);
  const snap = await db.collection("fornecedor").doc(idFornecedor).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Fornecedor não encontrado.");
  }
}

export function exigirVinculoFinanceiroFornecedor(uid: string, idFornecedor: string): void {
  if (!idFornecedor) {
    throw new HttpsError("invalid-argument", "Informe o fornecedor.");
  }
  if (uid !== idFornecedor) {
    throw new HttpsError(
      "permission-denied",
      "Sem autorização para o financeiro privado deste fornecedor.",
    );
  }
}
