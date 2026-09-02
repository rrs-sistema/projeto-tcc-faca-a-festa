import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import type { AuthType } from "firebase-functions/v2/firestore";

import { admin } from "../../shared/firebaseAdmin";
import { calcularHashIntegridadeAuditoria } from "./auditIntegrity";
import { definirAcao } from "./catalogoAuditoria";

const MAX_FIELD = 80;
const MAX_VALUE = 180;
const MAX_DIFFS = 24;
const MAX_DETAIL_FIELDS = 80;
const IGNORED_FIELDS = new Set([
  "updatedAt",
  "updated_at",
  "atualizadoEm",
  "atualizado_em",
  "lastSeenAt",
  "last_seen_at",
  "fcmToken",
  "fcm_token",
  "mediaAvaliacoes",
  "media_avaliacoes",
  "totalAvaliacoes",
  "total_avaliacoes",
  "avaliacoesAtualizadasEm",
  "avaliacoes_atualizadas_em",
  "selos",
]);
const SENSITIVE_FIELD_TERMS = [
  "senha",
  "password",
  "passwd",
  "token",
  "secret",
  "segredo",
  "codigo",
  "code",
  "otp",
  "totp",
  "mfa",
  "pin",
  "apikey",
  "api_key",
  "authorization",
  "auth",
];

export type AuditTrailOperation = "created" | "updated" | "deleted";

export type AuditTrailRequest = {
  acao: string;
  operacao: AuditTrailOperation;
  entidadeTipo: string;
  entidadeId: string;
  entidadeNome?: string | null;
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
  actorUid?: string | null;
  actorAuthType?: AuthType | "unknown";
  documentPath?: string;
  sourceEventId?: string | null;
  idFornecedor?: string | null;
  idEvento?: string | null;
  idServico?: string | null;
  idCotacao?: string | null;
  idOrcamento?: string | null;
};

type ActorInfo = {
  uid: string | null;
  nome: string | null;
  email: string | null;
  tipo: string;
  authType: string;
};

function text(value: unknown): string {
  return String(value ?? "").trim();
}

function limit(value: string, max: number): string {
  if (value.length <= max) return value;
  return `${value.slice(0, max)}...`;
}

function optionalText(value: unknown, max = MAX_VALUE): string | null {
  const normalized = limit(text(value), max);
  return normalized.length > 0 ? normalized : null;
}

function safeValue(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "string") return limit(value.trim(), MAX_VALUE);
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  if (value instanceof Date) return value.toISOString();
  try {
    return limit(JSON.stringify(value), MAX_VALUE);
  } catch {
    return "";
  }
}

function canonicalValue(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "object") {
    try {
      return JSON.stringify(value);
    } catch {
      return String(value);
    }
  }
  return String(value);
}

function shouldIgnoreField(field: string): boolean {
  if (IGNORED_FIELDS.has(field)) return true;
  const normalized = field.toLowerCase().replace(/[^a-z0-9_]/g, "");
  return SENSITIVE_FIELD_TERMS.some((term) => normalized.includes(term));
}

function buildDiffs(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): Array<{ campo: string; de: string; para: string }> {
  const fields = new Set([
    ...Object.keys(before ?? {}),
    ...Object.keys(after ?? {}),
  ]);
  const diffs: Array<{ campo: string; de: string; para: string }> = [];

  for (const field of Array.from(fields).sort()) {
    if (shouldIgnoreField(field)) continue;
    const beforeValue = before?.[field];
    const afterValue = after?.[field];
    if (canonicalValue(beforeValue) === canonicalValue(afterValue)) continue;

    diffs.push({
      campo: limit(field, MAX_FIELD),
      de: safeValue(beforeValue),
      para: safeValue(afterValue),
    });

    if (diffs.length >= MAX_DIFFS) break;
  }

  return diffs;
}

function sanitizeRecord(
  data: Record<string, unknown> | undefined,
): Record<string, unknown> | undefined {
  if (!data) return undefined;
  const sanitized: Record<string, unknown> = {};
  const fields = Object.keys(data).sort().slice(0, MAX_DETAIL_FIELDS);
  for (const field of fields) {
    const key = limit(field, MAX_FIELD);
    sanitized[key] = shouldIgnoreField(field) ? "[redigido]" : safeValue(data[field]);
  }
  return sanitized;
}

function buildTechnicalDetail(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
  diffs: Array<{ campo: string; de: string; para: string }>,
): Record<string, unknown> {
  const detail: Record<string, unknown> = {
    campos_alterados: diffs.map((diff) => diff.campo),
  };
  const beforeSanitized = sanitizeRecord(before);
  const afterSanitized = sanitizeRecord(after);
  if (beforeSanitized) detail.before = beforeSanitized;
  if (afterSanitized) detail.after = afterSanitized;
  return detail;
}

function auditDocumentIdForSourceEvent(sourceEventId: string | null | undefined): string | null {
  const normalized = optionalText(sourceEventId, 180);
  if (!normalized) return null;
  const safe = normalized.replace(/[^A-Za-z0-9_-]/g, "_");
  return `trigger_${safe}`;
}

function firstText(
  data: Record<string, unknown> | undefined,
  fields: string[],
): string | null {
  for (const field of fields) {
    const value = optionalText(data?.[field]);
    if (value) return value;
  }
  return null;
}

async function resolveActor(
  actorUid: string | null | undefined,
  actorAuthType: string | undefined,
): Promise<ActorInfo> {
  const uid = optionalText(actorUid, 120);
  const authType = optionalText(actorAuthType, 40) ?? "unknown";

  if (!uid || authType === "system" || authType === "service_account") {
    return {
      uid,
      nome: null,
      email: null,
      tipo: "S",
      authType,
    };
  }

  try {
    const userSnap = await admin.firestore().collection("usuarios").doc(uid).get();
    const userData = userSnap.data() ?? {};
    return {
      uid,
      nome: firstText(userData, ["nome", "displayName"]),
      email: firstText(userData, ["email"]),
      tipo: optionalText(userData.tipo, 20) ?? "U",
      authType,
    };
  } catch (error) {
    logger.warn("auditoria.actor_lookup_failed", { uid, error });
    return {
      uid,
      nome: null,
      email: null,
      tipo: "U",
      authType,
    };
  }
}

function buildSummary(request: AuditTrailRequest): string {
  const nome = request.entidadeNome ? ` "${request.entidadeNome}"` : "";
  switch (request.operacao) {
    case "created":
      return `${request.entidadeTipo}${nome} criado no sistema.`;
    case "deleted":
      return `${request.entidadeTipo}${nome} removido do sistema.`;
    case "updated":
      return `${request.entidadeTipo}${nome} atualizado no sistema.`;
  }
}

export function firstRelevantText(
  data: Record<string, unknown> | undefined,
  fields: string[],
): string | null {
  return firstText(data, fields);
}

export async function registrarAuditTrail(
  request: AuditTrailRequest,
): Promise<void> {
  const definicao = definirAcao(request.acao);
  const actor = await resolveActor(request.actorUid, request.actorAuthType);
  const diffs = buildDiffs(request.before, request.after);

  if (request.operacao === "updated" && diffs.length === 0) {
    return;
  }

  const payload: Record<string, unknown> = {
    acao: request.acao,
    area: definicao.area,
    nivel: definicao.nivel,
    resumo: buildSummary(request),
    entidade_tipo: request.entidadeTipo,
    entidade_id: request.entidadeId,
    entidade_nome: request.entidadeNome ?? undefined,
    id_fornecedor: request.idFornecedor ?? undefined,
    id_evento: request.idEvento ?? undefined,
    id_servico: request.idServico ?? undefined,
    id_cotacao: request.idCotacao ?? undefined,
    id_orcamento: request.idOrcamento ?? undefined,
    ator_uid: actor.uid ?? undefined,
    ator_nome: actor.nome ?? undefined,
    ator_email: actor.email ?? undefined,
    ator_tipo: actor.tipo,
    ator_auth_type: actor.authType,
    mudancas: diffs.length > 0 ? diffs : undefined,
    detalhe: buildTechnicalDetail(request.before, request.after, diffs),
    visivel_fornecedor: Boolean(definicao.visivelFornecedor && request.idFornecedor),
    origem: "firestore_trigger",
    document_path: request.documentPath,
    source_event_id: request.sourceEventId ?? undefined,
    operacao: request.operacao,
    versao_schema: 2,
    algoritmo_hash: "sha256",
    criado_em: FieldValue.serverTimestamp(),
  };

  for (const key of Object.keys(payload)) {
    if (payload[key] === undefined || payload[key] === null || payload[key] === "") {
      delete payload[key];
    }
  }

  payload.hash_integridade = calcularHashIntegridadeAuditoria(payload);

  const collection = admin.firestore().collection("auditoria_eventos");
  const deterministicId = auditDocumentIdForSourceEvent(request.sourceEventId);
  if (deterministicId) {
    const ref = collection.doc(deterministicId);
    const result = await ref.create(payload).catch((error) => {
      if (error?.code === 6 || error?.code === "already-exists") {
        logger.info("auditoria.audit_trail_duplicada_ignorada", {
          sourceEventId: request.sourceEventId,
          acao: request.acao,
          entidadeTipo: request.entidadeTipo,
          entidadeId: request.entidadeId,
        });
        return null;
      }
      throw error;
    });
    if (result === null) return;
  } else {
    await collection.add(payload);
  }

  logger.info("auditoria.audit_trail_registrada", {
    acao: request.acao,
    entidadeTipo: request.entidadeTipo,
    entidadeId: request.entidadeId,
    operacao: request.operacao,
  });
}

export async function registrarAuditTrailSeguro(
  request: AuditTrailRequest,
): Promise<void> {
  try {
    await registrarAuditTrail(request);
  } catch (error) {
    logger.error("auditoria.audit_trail_falhou", {
      acao: request.acao,
      entidadeTipo: request.entidadeTipo,
      entidadeId: request.entidadeId,
      error,
    });
  }
}
