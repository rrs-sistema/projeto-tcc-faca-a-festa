import { Firestore, Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

export const MEDIDAS_FORNECEDOR = "plataforma_medidas_fornecedor";

export function restricaoVigente(medida: Record<string, unknown> | undefined, agora: string) {
  return !!medida && (medida.acao === "descredenciar" ||
    (["restringir", "suspender"].includes(String(medida.acao)) &&
      typeof medida.ate === "string" && medida.ate > agora));
}

export async function exigirNovosNegociosPermitidos(
  db: Firestore, tx: Transaction, idFornecedor: string, idsServico: unknown[],
) {
  const snap = await tx.get(db.collection(MEDIDAS_FORNECEDOR).doc(idFornecedor));
  const medida = snap.data();
  if (restricaoVigente(medida, new Date().toISOString()) &&
      (!medida?.idServico || idsServico.includes(medida.idServico))) {
    throw new HttpsError("failed-precondition",
      medida?.idServico ? "Este serviço está indisponível para novas cotações e contratações." :
        "Este fornecedor está indisponível para novas cotações e contratações.");
  }
}
