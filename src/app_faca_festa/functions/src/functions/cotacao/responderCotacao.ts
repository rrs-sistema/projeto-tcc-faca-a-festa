import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";

const REGION = "southamerica-east1";
const MAX_OBS = 2000;
const MAX_CONDICAO = 500;

/**
 * Fornecedor responde/recusa a cotação e, se todos responderam,
 * atualiza o status da cotação pai (sem depender de rules no client).
 */
export const responderCotacao = onCall(
  {
    region: REGION,
    timeoutSeconds: 45,
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["F", "A"]);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const idCotacao = texto(data.idCotacao ?? data.id_cotacao);
    const aceitou = Boolean(data.aceitou ?? data.aceitar);
    const condicao = texto(data.condicaoPagamento ?? data.condicao_pagamento).slice(
      0,
      MAX_CONDICAO,
    );
    const observacao = texto(
      data.observacaoFornecedor ?? data.observacao_fornecedor ?? data.observacao,
    ).slice(0, MAX_OBS);

    if (!idCotacao) {
      throw new HttpsError("invalid-argument", "Cotação inválida.");
    }

    const idFornecedor =
      perfil.tipo === "A"
        ? texto(data.idFornecedor ?? data.id_fornecedor) || perfil.uid
        : perfil.uid;

    const db = admin.firestore();
    const cotacaoRef = db.collection("cotacao").doc(idCotacao);
    const cotacaoSnap = await cotacaoRef.get();
    if (!cotacaoSnap.exists) {
      throw new HttpsError("not-found", "Cotação não encontrada.");
    }

    const statusAtual = texto(cotacaoSnap.data()?.status).toLowerCase();
    if (statusAtual === "concluida" || statusAtual === "cancelada") {
      throw new HttpsError(
        "failed-precondition",
        "Esta cotação não aceita mais respostas.",
      );
    }

    const fornecedorRef = cotacaoRef.collection("fornecedores").doc(idFornecedor);
    const fornecedorSnap = await fornecedorRef.get();
    if (!fornecedorSnap.exists) {
      throw new HttpsError(
        "permission-denied",
        "Você não participa desta cotação.",
      );
    }

    const prazo = parsePrazo(data.prazoEntrega ?? data.prazo_entrega);

    try {
      await fornecedorRef.update({
        status: aceitou ? "respondido" : "recusado",
        prazo_entrega: prazo ? Timestamp.fromDate(prazo) : null,
        condicao_pagamento: condicao,
        observacao_fornecedor: observacao,
        data_resposta: FieldValue.serverTimestamp(),
        respondido: true,
      });

      const todosSnap = await cotacaoRef.collection("fornecedores").get();
      const todosResponderam = todosSnap.docs.every((d) => {
        const s = texto(d.data().status).toLowerCase();
        return s === "respondido" || s === "recusado";
      });
      const algumRespondeu = todosSnap.docs.some((d) => {
        const s = texto(d.data().status).toLowerCase();
        return s === "respondido" || s === "recusado";
      });

      if (todosResponderam) {
        await cotacaoRef.update({
          status: "respondida",
          data_resposta_completa: FieldValue.serverTimestamp(),
        });
      } else if (algumRespondeu) {
        await cotacaoRef.update({
          status: "parcial",
        });
      }

      return { ok: true, aceitou, statusCotacao: todosResponderam ? "respondida" : "parcial" };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Falha ao responder cotação", {
        uid: perfil.uid,
        idCotacao,
        erro: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError("internal", "Não foi possível enviar a resposta.");
    }
  },
);

function texto(value: unknown): string {
  return String(value ?? "").trim();
}

function parsePrazo(raw: unknown): Date | null {
  if (raw == null || raw === "") return null;
  if (typeof raw === "string" || typeof raw === "number") {
    const parsed = new Date(raw);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  return null;
}
