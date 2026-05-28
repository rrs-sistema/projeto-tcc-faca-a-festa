/**
 * Versão do contrato da análise da calculadora inteligente.
 * Incremente quando campos obrigatórios, tipos ou semântica da resposta mudarem.
 */
export const ANALISE_CALCULADORA_IA_SCHEMA_VERSION = "1.2.0";

export const analiseCalculadoraIASchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "titulo",
    "resumo",
    "indice_economia",
    "indice_risco_faltar_itens",
    "indice_conforto",
    "custo_total_estimado",
    "orcamento_disponivel",
    "diferenca_orcamento",
    "data_analise",
    "sugestoes",
    "diagnostico_financeiro",
    "diagnostico_consumo",
    "recomendacao_final",
    "pontos_de_atencao",
    "proximas_acoes",
    "fonte",
    "versao_schema",
  ],
  properties: {
    titulo: { type: "string" },
    resumo: { type: "string" },
    indice_economia: { type: "number", minimum: 0, maximum: 100 },
    indice_risco_faltar_itens: { type: "number", minimum: 0, maximum: 100 },
    indice_conforto: { type: "number", minimum: 0, maximum: 100 },
    custo_total_estimado: { type: "number", minimum: 0 },
    orcamento_disponivel: { type: ["number", "null"], minimum: 0 },
    diferenca_orcamento: { type: "number" },
    data_analise: { type: "string" },
    sugestoes: {
      type: "array",
      minItems: 0,
      maxItems: 8,
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "id",
          "titulo",
          "descricao",
          "tipo",
          "prioridade",
          "item_relacionado",
          "impacto_estimado",
        ],
        properties: {
          id: { type: "string" },
          titulo: { type: "string" },
          descricao: { type: "string" },
          tipo: {
            type: "string",
            enum: ["economia", "alerta", "melhoria", "excesso", "falta", "planejamento"],
          },
          prioridade: { type: "string", enum: ["baixa", "media", "alta"] },
          item_relacionado: { type: ["string", "null"] },
          impacto_estimado: { type: "number" },
        },
      },
    },
    diagnostico_financeiro: { type: "string" },
    diagnostico_consumo: { type: "string" },
    recomendacao_final: { type: "string" },
    pontos_de_atencao: {
      type: "array",
      minItems: 0,
      maxItems: 8,
      items: { type: "string" },
    },
    proximas_acoes: {
      type: "array",
      minItems: 0,
      maxItems: 8,
      items: { type: "string" },
    },
    fonte: { type: "string", enum: ["ia_generativa", "fallback_local", "local"] },
    versao_schema: { type: "string" },

    /** Campos preenchidos pela Cloud Function após a geração da análise. */
    nome_prompt: { type: "string" },
    versao_prompt: { type: "string" },
    ids_sugestoes_base_utilizadas: {
      type: "array",
      items: { type: "string" },
    },
    versoes_sugestoes_base_utilizadas: {
      type: "object",
      additionalProperties: { type: "number" },
    },
    total_sugestoes_base_utilizadas: { type: "number", minimum: 0 },
    modelo_ia_utilizado: { type: "string" },
    data_processamento: { type: "string" },
  },
} as const;

/** Alias mantido para facilitar uso em clients que importam o nome em caixa alta. */
export const ANALISE_CALCULADORA_IA_SCHEMA = analiseCalculadoraIASchema;
