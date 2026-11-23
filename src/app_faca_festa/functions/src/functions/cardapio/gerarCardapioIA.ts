import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { HttpsError } from "firebase-functions/v2/https";

import { onCall } from "../../shared/callableComMfa";
import { admin } from "../../shared/firebaseAdmin";
import { ehGestorNosDados } from "../../shared/eventoPermissao";
import {
  chamarOpenAiCardapio,
  construirFallbackLocal,
  normalizarEntrada,
  validarENormalizarSugestao,
} from "../../services/cardapio/gerarCardapioIAService";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const DEFAULT_REGION = "southamerica-east1";

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function asString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Gera sugestão de cardápio com IA para o organizador.
 * Não persiste cardápio, agenda, convidados nem despesas.
 */
export const gerarCardapioIA = onCall(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 90,
    memory: "512MiB",
    cors: true,
    secrets: [OPENAI_API_KEY],
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Faça login para gerar o cardápio.",
      );
    }

    const raw = asRecord(request.data);
    const idEvento = asString(raw.id_evento ?? raw.idEvento);
    if (!idEvento) {
      throw new HttpsError("invalid-argument", "Informe o evento.");
    }

    const db = admin.firestore();
    const eventoSnap = await db.collection("evento").doc(idEvento).get();
    if (!eventoSnap.exists) {
      throw new HttpsError("not-found", "Evento não encontrado.");
    }

    const usuario = await db.collection("usuarios").doc(uid).get();
    const isAdmin =
      usuario.data()?.tipo === "A" && usuario.data()?.ativo !== false;
    if (!isAdmin && !ehGestorNosDados(eventoSnap.data(), uid)) {
      throw new HttpsError(
        "permission-denied",
        "Sem permissão para gerar cardápio deste evento.",
      );
    }

    let entrada;
    try {
      entrada = normalizarEntrada(raw);
    } catch (error) {
      throw new HttpsError(
        "invalid-argument",
        error instanceof Error ? error.message : "Dados inválidos.",
      );
    }

    // Não envia nomes/telefones de convidados — apenas agregados do formulário.
    const apiKey = OPENAI_API_KEY.value() || process.env.OPENAI_API_KEY;

    if (apiKey) {
      try {
        const bruto = await chamarOpenAiCardapio(entrada, apiKey);
        const validado = validarENormalizarSugestao(
          bruto,
          entrada,
          "ia_generativa",
        );
        if (validado) return validado;
        logger.warn("Sugestão IA inválida; usando fallback local.", {
          idEvento,
        });
      } catch (error) {
        logger.warn("Falha na IA generativa de cardápio; fallback local.", {
          idEvento,
          erro: error instanceof Error ? error.message : String(error),
        });
      }
    } else {
      logger.warn("OPENAI_API_KEY ausente; usando fallback local de cardápio.");
    }

    return construirFallbackLocal(entrada);
  },
);
