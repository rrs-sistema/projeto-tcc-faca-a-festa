import { PROMPT_CALCULADORA_IA_NAME, PROMPT_CALCULADORA_IA_VERSION } from "../../ia/calculadora/prompt";
import { ANALISE_CALCULADORA_IA_SCHEMA_VERSION } from "../../ia/calculadora/schema";
import { AnaliseCalculadoraIAResponse, FonteAnaliseCalculadoraIA, SugestaoBaseIA } from "../../types/calculadoraIA.types";

export interface RastreabilidadeCalculadoraIAParams {
  sugestoesBase: SugestaoBaseIA[];
  modeloIAUtilizado: string;
  fonte: FonteAnaliseCalculadoraIA;
  dataProcessamento?: Date;
}

export interface RastreabilidadeCalculadoraIA {
  nome_prompt: string;
  versao_prompt: string;
  versao_schema: string;
  ids_sugestoes_base_utilizadas: string[];
  versoes_sugestoes_base_utilizadas: Record<string, number>;
  total_sugestoes_base_utilizadas: number;
  modelo_ia_utilizado: string;
  data_processamento: string;
}

export function montarRastreabilidadeCalculadoraIA(
  params: RastreabilidadeCalculadoraIAParams,
): RastreabilidadeCalculadoraIA {
  const sugestoesBase = params.sugestoesBase ?? [];
  const idsSugestoes = sugestoesBase
    .map((sugestao) => sugestao.id)
    .filter((id) => id.trim().length > 0);

  return {
    nome_prompt: PROMPT_CALCULADORA_IA_NAME,
    versao_prompt: PROMPT_CALCULADORA_IA_VERSION,
    versao_schema: ANALISE_CALCULADORA_IA_SCHEMA_VERSION,
    ids_sugestoes_base_utilizadas: idsSugestoes,
    versoes_sugestoes_base_utilizadas: sugestoesBase.reduce<Record<string, number>>(
      (acc, sugestao) => {
        if (sugestao.id.trim().length > 0) {
          acc[sugestao.id] = Math.max(1, Number(sugestao.versao) || 1);
        }
        return acc;
      },
      {},
    ),
    total_sugestoes_base_utilizadas: idsSugestoes.length,
    modelo_ia_utilizado: params.modeloIAUtilizado || params.fonte,
    data_processamento: (params.dataProcessamento ?? new Date()).toISOString(),
  };
}

/**
 * Aplica a rastreabilidade depois da IA responder.
 * Assim, a IA não precisa conhecer nem preencher versão de prompt/schema/modelo/sugestões.
 */
export function aplicarRastreabilidadeAnalise(
  analise: Partial<AnaliseCalculadoraIAResponse> & Record<string, unknown>,
  params: RastreabilidadeCalculadoraIAParams,
): AnaliseCalculadoraIAResponse {
  const rastreabilidade = montarRastreabilidadeCalculadoraIA(params);

  return {
    titulo: asString(analise.titulo, "Análise inteligente"),
    resumo: asString(analise.resumo, "Análise gerada com base na simulação da calculadora."),
    indice_economia: clampNumber(analise.indice_economia, 0, 100),
    indice_risco_faltar_itens: clampNumber(analise.indice_risco_faltar_itens, 0, 100),
    indice_conforto: clampNumber(analise.indice_conforto, 0, 100),
    custo_total_estimado: asNumber(analise.custo_total_estimado),
    orcamento_disponivel: nullableNumber(analise.orcamento_disponivel),
    diferenca_orcamento: asNumber(analise.diferenca_orcamento),
    data_analise: asString(analise.data_analise, new Date().toISOString()),
    sugestoes: normalizarSugestoesIA(analise.sugestoes),
    diagnostico_financeiro: asString(analise.diagnostico_financeiro),
    diagnostico_consumo: asString(analise.diagnostico_consumo),
    recomendacao_final: asString(analise.recomendacao_final),
    pontos_de_atencao: asStringArray(analise.pontos_de_atencao),
    proximas_acoes: asStringArray(analise.proximas_acoes),
    fonte: params.fonte,
    ...rastreabilidade,
  };
}

function normalizarSugestoesIA(value: unknown): AnaliseCalculadoraIAResponse["sugestoes"] {
  if (!Array.isArray(value)) return [];

  return value.slice(0, 8).map((item, index) => {
    const record = asRecord(item);
    const titulo = asString(record.titulo, `Sugestão ${index + 1}`);

    return {
      id: asString(record.id, gerarIdSeguro(titulo, index)),
      titulo,
      descricao: asString(record.descricao),
      tipo: normalizarTipoSugestao(record.tipo),
      prioridade: normalizarPrioridade(record.prioridade),
      item_relacionado: nullableString(record.item_relacionado ?? record.itemRelacionado),
      impacto_estimado: asNumber(record.impacto_estimado ?? record.impactoEstimado),
    };
  });
}

function normalizarTipoSugestao(value: unknown): AnaliseCalculadoraIAResponse["sugestoes"][number]["tipo"] {
  const normalized = normalizeToken(asString(value, "planejamento"));
  if (["economia", "alerta", "melhoria", "excesso", "falta", "planejamento"].includes(normalized)) {
    return normalized as AnaliseCalculadoraIAResponse["sugestoes"][number]["tipo"];
  }
  return "planejamento";
}

function normalizarPrioridade(value: unknown): AnaliseCalculadoraIAResponse["sugestoes"][number]["prioridade"] {
  const normalized = normalizeToken(asString(value, "media"));
  if (["baixa", "media", "alta"].includes(normalized)) {
    return normalized as AnaliseCalculadoraIAResponse["sugestoes"][number]["prioridade"];
  }
  return "media";
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function asString(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  const text = String(value).trim();
  return text.length > 0 && text !== "null" ? text : fallback;
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", ".").replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function clampNumber(value: unknown, min: number, max: number): number {
  const parsed = asNumber(value, min);
  return Math.max(min, Math.min(max, parsed));
}

function nullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  return asNumber(value);
}

function nullableString(value: unknown): string | null {
  const text = asString(value);
  return text.length > 0 ? text : null;
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asString(item))
    .filter((item) => item.length > 0);
}

function gerarIdSeguro(titulo: string, index: number): string {
  const normalized = normalizeToken(titulo).replace(/[^a-z0-9_]/g, "");
  return normalized || `sugestao_${index + 1}`;
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
