import { HttpsError } from "firebase-functions/v2/https";
import { Firestore } from "firebase-admin/firestore";
import { PerfilAuth } from "../../shared/auth";

/**
 * Gerente = responsável autorizado pelo evento (dono id_usuario) ou
 * solicitante do orçamento. Admin de plataforma NÃO recebe custos privados
 * de fornecedor automaticamente; aqui só acessa fatos do evento pagador.
 */
export async function exigirAcessoFinanceiroEvento(
  db: Firestore,
  perfil: PerfilAuth,
  idEvento: string,
  opcoes?: { idOrcamento?: string; permitirAdminEvento?: boolean },
): Promise<{ idEvento: string; idOrcamento?: string }> {
  if (!idEvento) {
    throw new HttpsError("invalid-argument", "Informe o evento.");
  }

  const eventoSnap = await db.collection("evento").doc(idEvento).get();
  if (!eventoSnap.exists) {
    throw new HttpsError("not-found", "Evento não encontrado.");
  }

  const dono = String(eventoSnap.data()?.id_usuario ?? "");
  const isDono = dono === perfil.uid;
  const isAdminPlataforma = perfil.tipo === "A";

  if (opcoes?.idOrcamento) {
    const orcSnap = await db.collection("orcamento").doc(opcoes.idOrcamento).get();
    if (!orcSnap.exists) {
      throw new HttpsError("not-found", "Orçamento não encontrado.");
    }
    const data = orcSnap.data() ?? {};
    if (String(data.id_evento ?? "") !== idEvento) {
      throw new HttpsError(
        "failed-precondition",
        "Orçamento não pertence a este evento.",
      );
    }
    const solicitante = String(data.id_solicitante ?? "");
    if (isDono || solicitante === perfil.uid) {
      return { idEvento, idOrcamento: opcoes.idOrcamento };
    }
    if (isAdminPlataforma && opcoes.permitirAdminEvento !== false) {
      // Admin vê fatos do evento (não custos privados de fornecedor).
      return { idEvento, idOrcamento: opcoes.idOrcamento };
    }
    throw new HttpsError(
      "permission-denied",
      "Sem autorização financeira neste evento.",
    );
  }

  if (isDono || (isAdminPlataforma && opcoes?.permitirAdminEvento !== false)) {
    return { idEvento };
  }

  throw new HttpsError(
    "permission-denied",
    "Sem autorização financeira neste evento.",
  );
}
