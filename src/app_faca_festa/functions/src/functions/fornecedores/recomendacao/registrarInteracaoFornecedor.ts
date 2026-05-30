import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { registrarInteracaoFornecedorService } from "../../../services/fornecedores/fornecedorInteracaoService";
import { RegistrarInteracaoFornecedorPayload } from "../../../types/fornecedorRecomendacao.types";

const DEFAULT_REGION = "southamerica-east1";

export const registrarInteracaoFornecedor = onCall(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const payload = normalizarPayload(request.data);

    if (!payload.idEvento || !payload.idFornecedor || !payload.acao) {
      throw new HttpsError(
        "invalid-argument",
        "idEvento, idFornecedor e acao são obrigatórios.",
      );
    }

    try {
      const result = await registrarInteracaoFornecedorService({
        uid: request.auth.uid,
        payload,
      });

      return {
        ok: true,
        ...result,
      };
    } catch (error) {
      logger.error("Erro ao registrar interação de fornecedor.", {
        uid: request.auth.uid,
        payload,
        erro: error instanceof Error ? error.message : String(error),
      });

      throw new HttpsError(
        "internal",
        error instanceof Error ? error.message : "Erro interno ao registrar interação.",
      );
    }
  },
);

function normalizarPayload(data: unknown): RegistrarInteracaoFornecedorPayload {
  const raw = isRecord(data) ? data : {};

  return {
    idEvento: asString(raw.idEvento ?? raw.id_evento ?? raw.eventoId),
    idFornecedor: asString(raw.idFornecedor ?? raw.id_fornecedor ?? raw.fornecedorId),
    acao: asString(raw.acao),
    tipoEventoId: asNullableString(raw.tipoEventoId ?? raw.tipo_evento_id),
    tipoEventoNome: asNullableString(raw.tipoEventoNome ?? raw.tipo_evento_nome),
    tipoEventoSlug: asNullableString(raw.tipoEventoSlug ?? raw.tipo_evento_slug),
    cidade: asNullableString(raw.cidade),
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

function asNullableString(value: unknown): string | null {
  const text = asString(value);
  return text || null;
}
