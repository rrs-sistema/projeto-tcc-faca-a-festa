import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { gravarMensagemSistema } from "./mensagensSistemaCotacao";

const REGION = "southamerica-east1";
const MAX_OBS = 2000;
const MAX_CONDICAO = 500;

/**
 * Fornecedor responde/recusa a cotação.
 * Quando aceita, persiste valor_cotado e redistribui nos serviços
 * (preço negociado vira base do fecharCotacao).
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
    const valorProposto = asNumber(
      data.valorProposto ?? data.valor_proposto ?? data.valorCotado ?? data.valor_cotado,
    );

    if (!idCotacao) {
      throw new HttpsError("invalid-argument", "Cotação inválida.");
    }

    if (aceitou && valorProposto <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "Informe o valor cotado (maior que zero) para aceitar.",
      );
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

    const statusForn = texto(fornecedorSnap.data()?.status).toLowerCase();
    if (
      statusForn === "fechado" ||
      statusForn === "perdeucotacao" ||
      statusForn === "cancelada"
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Esta participação na cotação não aceita mais resposta.",
      );
    }

    const prazo = parsePrazo(data.prazoEntrega ?? data.prazo_entrega);

    try {
      // Status do pai calculado no mesmo batch (evita organizador preso em "pendente").
      const todosSnap = await cotacaoRef.collection("fornecedores").get();
      const statusApos = todosSnap.docs.map((d) => {
        const id = texto(d.data().id_fornecedor) || d.id;
        if (id === idFornecedor || d.id === idFornecedor) {
          return aceitou ? "respondido" : "recusado";
        }
        return texto(d.data().status).toLowerCase();
      });
      const todosResponderam = statusApos.every(
        (s) => s === "respondido" || s === "recusado" || s === "cancelada",
      );
      const algumRespondeu = statusApos.some(
        (s) => s === "respondido" || s === "recusado",
      );
      const todosRecusaram = statusApos.every(
        (s) => s === "recusado" || s === "cancelada",
      );

      let statusCotacao = "pendente";
      if (todosRecusaram && statusApos.length > 0) {
        statusCotacao = "cancelada";
      } else if (todosResponderam) {
        statusCotacao = "respondida";
      } else if (algumRespondeu) {
        statusCotacao = "parcial";
      }

      const batch = db.batch();
      batch.update(fornecedorRef, {
        status: aceitou ? "respondido" : "recusado",
        prazo_entrega: prazo ? Timestamp.fromDate(prazo) : null,
        condicao_pagamento: condicao,
        observacao_fornecedor: observacao,
        data_resposta: FieldValue.serverTimestamp(),
        respondido: true,
        valor_cotado: aceitou ? valorProposto : FieldValue.delete(),
      });

      if (aceitou) {
        const servicosSnap = await fornecedorRef.collection("servicos").get();
        if (!servicosSnap.empty) {
          let somaAtual = 0;
          for (const doc of servicosSnap.docs) {
            const item = doc.data();
            const qtd = Math.max(1, asNumber(item.quantidade, 1));
            somaAtual += asNumber(item.valor_estimado) * qtd;
          }
          for (const doc of servicosSnap.docs) {
            const item = doc.data();
            const qtd = Math.max(1, asNumber(item.quantidade, 1));
            const atual = asNumber(item.valor_estimado) * qtd;
            const peso = somaAtual > 0 ? atual / somaAtual : 1 / servicosSnap.size;
            const subtotal = valorProposto * peso;
            const unitario = qtd > 0 ? subtotal / qtd : subtotal;
            batch.update(doc.ref, {
              valor_estimado: Number(unitario.toFixed(2)),
              subtotal: Number(subtotal.toFixed(2)),
              valor_cotado_em: FieldValue.serverTimestamp(),
            });
          }
        }
      }

      if (statusCotacao === "respondida") {
        batch.update(cotacaoRef, {
          status: "respondida",
          data_resposta_completa: FieldValue.serverTimestamp(),
        });
      } else if (statusCotacao === "parcial") {
        batch.update(cotacaoRef, { status: "parcial" });
      } else if (statusCotacao === "cancelada") {
        batch.update(cotacaoRef, {
          status: "cancelada",
          data_cancelamento: FieldValue.serverTimestamp(),
          cancelado_por: perfil.uid,
        });
      }

      await batch.commit();

      const msgSistema = aceitou
        ? `Proposta enviada: R$ ${valorProposto.toFixed(2).replace(".", ",")}` +
          (condicao ? ` · Condição: ${condicao}` : "") +
          ". O organizador fecha o negócio no app."
        : "O fornecedor recusou esta cotação.";
      await gravarMensagemSistema(db, idCotacao, idFornecedor, msgSistema);

      return { ok: true, aceitou, statusCotacao, valorCotado: aceitou ? valorProposto : null };
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

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const n = Number(value.replace(",", "."));
    return Number.isFinite(n) ? n : fallback;
  }
  return fallback;
}

function parsePrazo(raw: unknown): Date | null {
  if (raw == null || raw === "") return null;
  if (typeof raw === "string" || typeof raw === "number") {
    const parsed = new Date(raw);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  return null;
}
