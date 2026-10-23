import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import {
  gravarMensagemSistema,
  gravarMensagemSistemaParaFornecedores,
} from "./mensagensSistemaCotacao";

const REGION = "southamerica-east1";

/**
 * Cancela cotação (organizador) ou participação (fornecedor),
 * recalcula status pai e registra mensagem de sistema.
 */
export const cancelarCotacao = onCall(
  {
    region: REGION,
    timeoutSeconds: 45,
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O", "F", "A"]);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const idCotacao = texto(data.idCotacao ?? data.id_cotacao);
    if (!idCotacao) {
      throw new HttpsError("invalid-argument", "Cotação inválida.");
    }

    const db = admin.firestore();
    const cotacaoRef = db.collection("cotacao").doc(idCotacao);
    const cotacaoSnap = await cotacaoRef.get();
    if (!cotacaoSnap.exists) {
      throw new HttpsError("not-found", "Cotação não encontrada.");
    }

    const cotacao = cotacaoSnap.data() ?? {};
    const statusAtual = texto(cotacao.status).toLowerCase();
    if (statusAtual === "concluida" || statusAtual === "cancelada") {
      throw new HttpsError(
        "failed-precondition",
        "Esta cotação já foi finalizada.",
      );
    }

    const idSolicitante = texto(cotacao.id_usuario_solicitante);
    const ehSolicitante =
      perfil.tipo === "A" || perfil.uid === idSolicitante;

    const fornecedoresSnap = await cotacaoRef.collection("fornecedores").get();
    if (fornecedoresSnap.empty) {
      throw new HttpsError("failed-precondition", "Cotação sem fornecedores.");
    }

    try {
      const batch = db.batch();

      if (ehSolicitante) {
        const ids: string[] = [];
        for (const doc of fornecedoresSnap.docs) {
          const id = texto(doc.data().id_fornecedor) || doc.id;
          ids.push(id);
          batch.update(doc.ref, {
            status: "cancelada",
            data_cancelamento: FieldValue.serverTimestamp(),
          });
        }
        batch.update(cotacaoRef, {
          status: "cancelada",
          data_cancelamento: FieldValue.serverTimestamp(),
          cancelado_por: perfil.uid,
        });
        await batch.commit();
        await gravarMensagemSistemaParaFornecedores(
          db,
          idCotacao,
          ids,
          "Esta cotação foi cancelada pelo organizador.",
        );
        return { ok: true, escopo: "cotacao", statusCotacao: "cancelada" };
      }

      // Fornecedor cancela só a própria participação.
      if (perfil.tipo !== "F" && perfil.tipo !== "A") {
        throw new HttpsError("permission-denied", "Sem permissão para cancelar.");
      }

      const idFornecedor =
        perfil.tipo === "A"
          ? texto(data.idFornecedor ?? data.id_fornecedor) || perfil.uid
          : perfil.uid;

      const meuDoc = fornecedoresSnap.docs.find((d) => {
        const id = texto(d.data().id_fornecedor) || d.id;
        return id === idFornecedor;
      });
      if (!meuDoc) {
        throw new HttpsError("not-found", "Você não participa desta cotação.");
      }

      batch.update(meuDoc.ref, {
        status: "recusado",
        respondido: true,
        data_cancelamento: FieldValue.serverTimestamp(),
      });

      // Recalcula status pai após a própria recusa (ainda no snap em memória + override).
      const statuses = fornecedoresSnap.docs.map((d) => {
        if (d.id === meuDoc.id || texto(d.data().id_fornecedor) === idFornecedor) {
          return "recusado";
        }
        return texto(d.data().status).toLowerCase();
      });

      const todosResponderam = statuses.every(
        (s) => s === "respondido" || s === "recusado" || s === "cancelada",
      );
      const algumAceitou = statuses.some((s) => s === "respondido");
      const todosRecusaram = statuses.every(
        (s) => s === "recusado" || s === "cancelada",
      );

      let statusCotacao = "pendente";
      if (todosRecusaram) {
        statusCotacao = "cancelada";
        batch.update(cotacaoRef, {
          status: "cancelada",
          data_cancelamento: FieldValue.serverTimestamp(),
          cancelado_por: perfil.uid,
        });
      } else if (todosResponderam) {
        statusCotacao = "respondida";
        batch.update(cotacaoRef, {
          status: "respondida",
          data_resposta_completa: FieldValue.serverTimestamp(),
        });
      } else if (algumAceitou || statuses.some((s) => s === "recusado")) {
        statusCotacao = "parcial";
        batch.update(cotacaoRef, { status: "parcial" });
      }

      await batch.commit();
      await gravarMensagemSistema(
        db,
        idCotacao,
        idFornecedor,
        "O fornecedor desistiu desta cotação.",
      );

      return { ok: true, escopo: "participacao", statusCotacao };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Falha ao cancelar cotação", {
        uid: perfil.uid,
        idCotacao,
        erro: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError("internal", "Não foi possível cancelar.");
    }
  },
);

function texto(value: unknown): string {
  return String(value ?? "").trim();
}
