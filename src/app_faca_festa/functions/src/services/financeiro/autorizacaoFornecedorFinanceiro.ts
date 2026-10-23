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
  if (!idFornecedor) {
    throw new HttpsError("invalid-argument", "Informe o fornecedor.");
  }
  if (perfil.uid !== idFornecedor) {
    throw new HttpsError(
      "permission-denied",
      "Sem autorização para o financeiro privado deste fornecedor.",
    );
  }
  if (perfil.tipo !== "F" && perfil.tipo !== "A") {
    // Mesmo admin tipado: só passa se uid == idFornecedor (dono da conta).
    // Tipo A com outro uid já foi barrado acima.
  }
  const snap = await db.collection("fornecedor").doc(idFornecedor).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Fornecedor não encontrado.");
  }
}
