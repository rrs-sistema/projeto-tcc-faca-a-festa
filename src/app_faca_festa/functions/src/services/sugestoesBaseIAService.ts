import { admin } from "../shared/firebaseAdmin";
import { SugestaoBaseIA } from "../types";

const COLLECTION_IA_SUGESTOES_BASE = "ia_sugestoes_base";
const MODULO_CALCULADORA = "calculadora";
const STATUS_APROVADOS = new Set(["aprovada", "aprovado", "publicada", "publicado"]);

export async function buscarSugestoesBaseCalculadora(params: {
  tipoEvento?: string;
  perfilFesta?: string;
  limit?: number;
}): Promise<SugestaoBaseIA[]> {
  const tipoEvento = normalizeToken(params.tipoEvento ?? "");
  const perfilFesta = normalizeToken(params.perfilFesta ?? "");
  const limit = params.limit ?? 12;

  const db = admin.firestore();

  // Estratégia segura: consulta simples por módulo e filtros complementares em memória.
  // Isso evita depender de índices compostos quando há filtros por arrays, perfil, tipo e ordem.
  const snapshot = await db
    .collection(COLLECTION_IA_SUGESTOES_BASE)
    .where("modulo", "==", MODULO_CALCULADORA)
    .limit(100)
    .get();

  const sugestoes = snapshot.docs
    .map((doc) => normalizarSugestaoBase(doc.id, doc.data() as Record<string, unknown>))
    .filter((sugestao) => podeUsarComoContextoIA(sugestao));

  const filtradas = sugestoes.filter((sugestao) => {
    return (
      aceitaValor(sugestao.tipo_evento, tipoEvento) &&
      aceitaValor(sugestao.perfis_festa, perfilFesta)
    );
  });

  const genericas = sugestoes.filter((sugestao) => {
    return (
      sugestao.tipo_evento.includes("todos") ||
      sugestao.perfis_festa.includes("todos") ||
      sugestao.tipo_evento.includes("geral") ||
      sugestao.perfis_festa.includes("geral")
    );
  });

  const baseFinal = filtradas.length > 0
    ? filtradas
    : genericas.length > 0
      ? genericas
      : sugestoes;

  return ordenarSugestoes(baseFinal).slice(0, limit);
}

function normalizarSugestaoBase(
  id: string,
  data: Record<string, unknown>,
): SugestaoBaseIA {
  return {
    id: asString(data.id, id),
    titulo: asString(data.titulo),
    descricao: asString(data.descricao),
    modulo: normalizeToken(asString(data.modulo, MODULO_CALCULADORA)),
    tema: normalizeToken(asString(data.tema, "geral")),
    tipo_evento: asStringArray(data.tipo_evento ?? data.tipoEvento),
    perfis_festa: asStringArray(data.perfis_festa ?? data.perfisFesta),
    categoria: normalizeToken(asString(data.categoria, "geral")),
    prioridade: normalizeToken(asString(data.prioridade, "media")),
    gatilhos: asRecord(data.gatilhos),
    tags: asStringArray(data.tags),
    ativo: asBool(data.ativo, true),
    excluido: asBool(data.excluido ?? data.deleted ?? data.deletado, false),
    ordem: asNumber(data.ordem),

    // Campos de versionamento/rastreabilidade editorial.
    versao: Math.max(1, asNumber(data.versao ?? data.version, 1)),
    origem: normalizeToken(asString(data.origem ?? data.source, "legado")),
    revisado_por: asString(
      data.revisado_por ?? data.revisadoPor ?? data.reviewed_by,
      "",
    ),
    data_revisao: asIsoDateString(data.data_revisao ?? data.dataRevisao ?? data.reviewed_at),
    data_publicacao: asIsoDateString(
      data.data_publicacao ?? data.dataPublicacao ?? data.published_at,
    ),
    status_revisao: normalizeStatusRevisao(
      data.status_revisao ?? data.statusRevisao ?? data.review_status,
    ),
    observacao_revisao: asString(
      data.observacao_revisao ?? data.observacaoRevisao ?? data.review_note,
      "",
    ),
  };
}

function podeUsarComoContextoIA(sugestao: SugestaoBaseIA): boolean {
  if (!sugestao.ativo || sugestao.excluido) return false;

  // Compatibilidade com documentos antigos: status ausente vira "aprovada" no normalizador.
  if (!STATUS_APROVADOS.has(sugestao.status_revisao)) return false;

  if (sugestao.data_publicacao) {
    const publishedAt = Date.parse(sugestao.data_publicacao);
    if (Number.isFinite(publishedAt) && publishedAt > Date.now()) {
      return false;
    }
  }

  return true;
}

function ordenarSugestoes(sugestoes: SugestaoBaseIA[]): SugestaoBaseIA[] {
  return [...sugestoes].sort((a, b) => {
    const prioridadeCompare = pesoPrioridade(b.prioridade) - pesoPrioridade(a.prioridade);

    if (prioridadeCompare !== 0) {
      return prioridadeCompare;
    }

    const ordemCompare = a.ordem - b.ordem;
    if (ordemCompare !== 0) return ordemCompare;

    return b.versao - a.versao;
  });
}

function aceitaValor(lista: string[], valor: string): boolean {
  if (!valor) return true;
  if (lista.length === 0) return true;
  return lista.includes(valor) || lista.includes("todos") || lista.includes("geral");
}

function pesoPrioridade(prioridade: string): number {
  switch (normalizeToken(prioridade)) {
    case "critica":
      return 4;
    case "alta":
      return 3;
    case "media":
      return 2;
    case "baixa":
      return 1;
    default:
      return 0;
  }
}

function asString(value: unknown, fallback = ""): string {
  if (value === undefined || value === null) return fallback;
  return String(value).trim();
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;

  if (typeof value === "string") {
    const normalized = value.replace(",", ".").replace(/[^0-9.-]/g, "");
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  return fallback;
}

function asBool(value: unknown, fallback = false): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  if (typeof value === "string") {
    const normalized = normalizeToken(value);
    if (["true", "1", "sim", "s", "yes", "y"].includes(normalized)) return true;
    if (["false", "0", "nao", "não", "n", "no"].includes(normalized)) return false;
  }
  return fallback;
}

function asStringArray(value: unknown): string[] {
  if (Array.isArray(value)) {
    return [
      ...new Set(
        value
          .map((item) => normalizeToken(String(item)))
          .filter(Boolean),
      ),
    ];
  }

  if (typeof value === "string") {
    return [
      ...new Set(
        value
          .split(",")
          .map((item) => normalizeToken(item))
          .filter(Boolean),
      ),
    ];
  }

  return [];
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }

  return {};
}

function asIsoDateString(value: unknown): string | null {
  if (!value) return null;

  if (value instanceof Date && Number.isFinite(value.getTime())) {
    return value.toISOString();
  }

  try {
    const maybeTimestamp = value as { toDate?: () => Date };
    const date = maybeTimestamp.toDate?.();
    if (date instanceof Date && Number.isFinite(date.getTime())) {
      return date.toISOString();
    }
  } catch (_) {
    // Ignora e tenta os demais formatos.
  }

  if (typeof value === "number") {
    const date = new Date(value);
    return Number.isFinite(date.getTime()) ? date.toISOString() : null;
  }

  if (typeof value === "string") {
    const trimmed = value.trim();
    if (!trimmed) return null;

    const parsed = new Date(trimmed);
    return Number.isFinite(parsed.getTime()) ? parsed.toISOString() : trimmed;
  }

  return null;
}

function normalizeStatusRevisao(value: unknown): string {
  const normalized = normalizeToken(asString(value, "aprovada"));
  return normalized || "aprovada";
}

function normalizeToken(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_")
    .replace(/-/g, "_");
}
