import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { recomendarFornecedoresParaEventoService } from "../../../services/fornecedores/fornecedorRecomendacaoService";
import { RecomendacaoFornecedoresPayload } from "../../../types/fornecedorRecomendacao.types";

const DEFAULT_REGION = "southamerica-east1";

export const recomendarFornecedoresParaEvento = onCall(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 60,
    memory: "512MiB",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const payload = normalizarPayload(request.data);

    if (!payload.idEvento) {
      throw new HttpsError("invalid-argument", "idEvento é obrigatório.");
    }

    try {
      const recomendacoes = await recomendarFornecedoresParaEventoService({
        uid: request.auth.uid,
        payload,
      });

      return {
        ok: true,
        idEvento: payload.idEvento,
        total: recomendacoes.length,
        recomendacoes,
      };
    } catch (error) {
      logger.error("Erro ao recomendar fornecedores para evento.", {
        idEvento: payload.idEvento,
        uid: request.auth.uid,
        erro: error instanceof Error ? error.message : String(error),
      });

      if (error instanceof HttpsError) throw error;

      throw new HttpsError(
        "internal",
        error instanceof Error ? error.message : "Erro interno ao recomendar fornecedores.",
      );
    }
  },
);

function normalizarPayload(data: unknown): RecomendacaoFornecedoresPayload {
  const raw = isRecord(data) ? data : {};

  return {
    idEvento: asString(raw.idEvento ?? raw.id_evento ?? raw.eventoId),
    modoDemo: asBoolean(raw.modoDemo ?? raw.modo_demo, false),
    latitude: asNullableNumber(raw.latitude) ?? undefined,
    longitude: asNullableNumber(raw.longitude) ?? undefined,
    limite: asNullableNumber(raw.limite) ?? undefined,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value && typeof value === "object" && !Array.isArray(value));
}

function asString(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  const text = String(value).trim();
  return text.length > 0 && text !== "null" ? text : fallback;
}

function asBoolean(value: unknown, fallback = false): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const text = value.toLowerCase().trim();
    if (["true", "s", "sim", "1"].includes(text)) return true;
    if (["false", "n", "nao", "não", "0"].includes(text)) return false;
  }
  if (typeof value === "number") return value === 1;
  return fallback;
}

function asNullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", ".").replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}
