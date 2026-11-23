/** Contrato da sugestão de cardápio gerada por IA. */
export const CARDAPIO_IA_SCHEMA_VERSION = "1.0.0";

export const UNIDADES_PERMITIDAS = ["un", "kg", "g", "l"] as const;
export const TIPOS_ITEM_PERMITIDOS = [
  "comida",
  "bebida",
  "sobremesa",
  "bolo",
  "descartavel",
  "outro",
] as const;
export const PUBLICOS_PERMITIDOS = [
  "todos",
  "adultos",
  "criancas",
  "bebes",
] as const;

export const cardapioIaSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "nome_cardapio",
    "resumo_publico",
    "justificativa",
    "premissas",
    "bebes_considerados",
    "aviso_bebes",
    "categorias",
  ],
  properties: {
    nome_cardapio: { type: "string" },
    resumo_publico: { type: "string" },
    justificativa: { type: "string" },
    premissas: {
      type: "array",
      minItems: 1,
      maxItems: 8,
      items: { type: "string" },
    },
    bebes_considerados: { type: "boolean" },
    aviso_bebes: { type: ["string", "null"] },
    categorias: {
      type: "array",
      minItems: 1,
      maxItems: 8,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["nome", "itens"],
        properties: {
          nome: { type: "string" },
          itens: {
            type: "array",
            minItems: 1,
            maxItems: 12,
            items: {
              type: "object",
              additionalProperties: false,
              required: [
                "nome",
                "tipo",
                "quantidade",
                "unidade",
                "observacao",
                "publico_alvo",
              ],
              properties: {
                nome: { type: "string" },
                tipo: { type: "string", enum: [...TIPOS_ITEM_PERMITIDOS] },
                quantidade: { type: "number", exclusiveMinimum: 0 },
                unidade: { type: "string", enum: [...UNIDADES_PERMITIDAS] },
                observacao: { type: ["string", "null"] },
                publico_alvo: {
                  type: "string",
                  enum: [...PUBLICOS_PERMITIDOS],
                },
              },
            },
          },
        },
      },
    },
  },
} as const;
