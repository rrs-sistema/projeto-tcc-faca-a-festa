import { HttpsError } from "firebase-functions/v2/https";
import { CalculadoraIARequest, AnaliseCalculadoraIAResponse } from "./types/calculadoraIA.types";
import {
  PROMPT_CALCULADORA_IA_NAME,
  PROMPT_CALCULADORA_IA_VERSION,
} from "./ia/calculadora/prompt";

import {
  ANALISE_CALCULADORA_IA_SCHEMA_VERSION,
} from "./ia/calculadora/schema";
const MAX_ITENS_DEFAULT = 60;

export function toNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

export function toNullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = toNumber(value, Number.NaN);
  return Number.isFinite(parsed) ? parsed : null;
}

export function toStringOrUndefined(value: unknown): string | undefined {
  if (value === null || value === undefined) return undefined;
  const text = String(value).trim();
  return text.length > 0 ? text : undefined;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function validateAndNormalizePayload(data: unknown): CalculadoraIARequest {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new HttpsError("invalid-argument", "Payload inválido para análise da calculadora.");
  }

  const raw = data as Record<string, unknown>;
  const itensRaw = Array.isArray(raw.itens) ? raw.itens : [];
  const maxItens = Number(process.env.AI_MAX_ITENS ?? MAX_ITENS_DEFAULT);

  const itens = itensRaw.slice(0, maxItens).map((item, index) => {
    const map = item && typeof item === "object" ? item as Record<string, unknown> : {};
    return {
      id_item_resultado: toStringOrUndefined(map.id_item_resultado) ?? `item_${index + 1}`,
      nome: toStringOrUndefined(map.nome) ?? "Item sem nome",
      categoria: toStringOrUndefined(map.categoria) ?? "Geral",
      tipo_item: toStringOrUndefined(map.tipo_item),
      publico_alvo: toStringOrUndefined(map.publico_alvo),
      unidade: toStringOrUndefined(map.unidade) ?? "un",
      quantidade: toNumber(map.quantidade, 0),
      quantidade_por_convidado_equivalente: toNumber(map.quantidade_por_convidado_equivalente, 0),
      valor_unitario_medio: toNumber(map.valor_unitario_medio, 0),
      custo_estimado: toNumber(map.custo_estimado, 0),
      regra_aplicada: toStringOrUndefined(map.regra_aplicada),
    };
  });

  const custoTotalEstimado = toNumber(raw.custo_total_estimado, itens.reduce((acc, item) => acc + (item.custo_estimado ?? 0), 0));

  return {
    id_calculo: toStringOrUndefined(raw.id_calculo),
    id_evento: toStringOrUndefined(raw.id_evento),
    id_usuario: toStringOrUndefined(raw.id_usuario),
    nome_evento: toStringOrUndefined(raw.nome_evento),
    tipo_evento: toStringOrUndefined(raw.tipo_evento) ?? "Evento social",
    perfil_festa: toStringOrUndefined(raw.perfil_festa) ?? "Padrão",
    perfil_festa_tipo: toStringOrUndefined(raw.perfil_festa_tipo),
    adultos: Math.round(toNumber(raw.adultos, 0)),
    criancas: Math.round(toNumber(raw.criancas, 0)),
    bebes: Math.round(toNumber(raw.bebes, 0)),
    total_informado: Math.round(toNumber(raw.total_informado, 0)),
    total_equivalente: toNumber(raw.total_equivalente, 0),
    total_equivalente_arredondado: Math.round(toNumber(raw.total_equivalente_arredondado, 0)),
    duracao_horas: Math.round(toNumber(raw.duracao_horas, 4)),
    margem: toNullableNumber(raw.margem) ?? 0,
    orcamento_disponivel: toNullableNumber(raw.orcamento_disponivel),
    custo_total_estimado: custoTotalEstimado,
    itens,
  };
}

export function normalizeAIResponse(
  raw: Partial<AnaliseCalculadoraIAResponse>,
  request: CalculadoraIARequest,
  fonte: "ia_generativa" | "fallback_local",
): AnaliseCalculadoraIAResponse {
  const orcamento = request.orcamento_disponivel ?? null;
  const custoTotal = request.custo_total_estimado ?? 0;
  const diferenca = orcamento === null ? 0 : custoTotal - orcamento;

  return {
    titulo: raw.titulo || "Análise inteligente da festa",
    resumo: raw.resumo || "Análise gerada com base na simulação da calculadora.",
    indice_economia: clamp(toNumber(raw.indice_economia, 70), 0, 100),
    indice_risco_faltar_itens: clamp(
      toNumber(raw.indice_risco_faltar_itens, 30),
      0,
      100,
    ),
    indice_conforto: clamp(toNumber(raw.indice_conforto, 70), 0, 100),
    custo_total_estimado: toNumber(raw.custo_total_estimado, custoTotal),
    orcamento_disponivel:
      raw.orcamento_disponivel === undefined
        ? orcamento
        : toNullableNumber(raw.orcamento_disponivel),
    diferenca_orcamento: toNumber(raw.diferenca_orcamento, diferenca),
    data_analise: raw.data_analise || new Date().toISOString(),

    sugestoes: Array.isArray(raw.sugestoes)
      ? raw.sugestoes.slice(0, 8).map((sugestao, index) => ({
        id: sugestao.id || `ia_${index + 1}`,
        titulo: sugestao.titulo || "Sugestão inteligente",
        descricao:
          sugestao.descricao ||
          "Revise este ponto no planejamento do evento.",
        tipo: sugestao.tipo || "planejamento",
        prioridade: sugestao.prioridade || "media",
        item_relacionado: sugestao.item_relacionado ?? null,
        impacto_estimado: toNumber(sugestao.impacto_estimado, 0),
      }))
      : [],

    diagnostico_financeiro:
      raw.diagnostico_financeiro || "Diagnóstico financeiro não informado.",
    diagnostico_consumo:
      raw.diagnostico_consumo || "Diagnóstico de consumo não informado.",
    recomendacao_final:
      raw.recomendacao_final ||
      "Revise a simulação e compare com outros cenários antes de converter em orçamento.",
    pontos_de_atencao: Array.isArray(raw.pontos_de_atencao)
      ? raw.pontos_de_atencao.slice(0, 8)
      : [],
    proximas_acoes: Array.isArray(raw.proximas_acoes)
      ? raw.proximas_acoes.slice(0, 8)
      : [],

    fonte,

    // Schema
    versao_schema:
      raw.versao_schema || ANALISE_CALCULADORA_IA_SCHEMA_VERSION,

    // Rastreabilidade do prompt
    nome_prompt:
      raw.nome_prompt || PROMPT_CALCULADORA_IA_NAME,

    versao_prompt:
      raw.versao_prompt || PROMPT_CALCULADORA_IA_VERSION,

    // Rastreabilidade das sugestões base
    ids_sugestoes_base_utilizadas: Array.isArray(
      raw.ids_sugestoes_base_utilizadas,
    )
      ? raw.ids_sugestoes_base_utilizadas.map(String)
      : [],

    versoes_sugestoes_base_utilizadas:
      raw.versoes_sugestoes_base_utilizadas &&
        typeof raw.versoes_sugestoes_base_utilizadas === "object" &&
        !Array.isArray(raw.versoes_sugestoes_base_utilizadas)
        ? raw.versoes_sugestoes_base_utilizadas as Record<string, number>
        : {},

    total_sugestoes_base_utilizadas:
      raw.total_sugestoes_base_utilizadas === undefined
        ? Array.isArray(raw.ids_sugestoes_base_utilizadas)
          ? raw.ids_sugestoes_base_utilizadas.length
          : 0
        : toNumber(raw.total_sugestoes_base_utilizadas, 0),

    // Rastreabilidade técnica
    modelo_ia_utilizado:
      raw.modelo_ia_utilizado || "nao_informado",

    data_processamento:
      raw.data_processamento || new Date().toISOString(),
  };
}
