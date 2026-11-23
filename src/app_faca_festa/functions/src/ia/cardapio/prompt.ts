import { CARDAPIO_IA_SCHEMA_VERSION } from "./schema";

export const PROMPT_CARDAPIO_IA_VERSION = CARDAPIO_IA_SCHEMA_VERSION;

export type CardapioIaEntrada = {
  tipo_festa: string;
  total_pessoas: number;
  adultos?: number | null;
  criancas?: number | null;
  bebes?: number | null;
  momento_refeicao: string;
  estilo?: string | null;
  restricoes?: string | null;
  observacoes?: string | null;
  duracao_horas?: number | null;
};

export function buildInstructions(): string {
  return [
    "Você é um assistente de planejamento de festas do aplicativo Faça a Festa.",
    "Gere um cardápio coerente com comidas, bebidas e quantidades estimadas.",
    "Responda somente em JSON válido, sem markdown.",
    "",
    "Regras obrigatórias:",
    "- Considere o tipo de festa, o momento da refeição e o público informado.",
    "- Agrupe itens em categorias úteis (ex.: Bebidas, Salgados, Sobremesas).",
    "- Evite excesso de variedade e combinações desnecessárias.",
    "- Ajuste quantidades a adultos e crianças quando informados.",
    "- Itens semelhantes dividem o consumo total; não calcule cada alternativa como se todos consumissem 100%.",
    "- Diferencie compra de quantidade pronta para servir na observação, quando relevante.",
    "- Unidades permitidas: un, kg, g, l.",
    "- Tipos de item: comida, bebida, sobremesa, bolo, descartavel, outro.",
    "- Públicos: todos, adultos, criancas, bebes.",
    "- Não inclua bebidas alcoólicas por padrão.",
    "- Não invente preços, fornecedores ou informações nutricionais.",
    "- Não sugira cardápio específico para bebês sem dados adequados; se houver bebês sem detalhe, marque bebes_considerados=false e explique no aviso_bebes.",
    "- Inclua justificativa curta e premissas explícitas.",
    "- Quantidades devem ser estimativas positivas e realistas.",
    "- Nome do cardápio em português, curto e claro.",
  ].join("\n");
}

export function buildInput(entrada: CardapioIaEntrada): string {
  const linhas = [
    `Tipo de festa: ${entrada.tipo_festa}`,
    `Momento da refeição: ${entrada.momento_refeicao}`,
    `Total de pessoas servidas: ${entrada.total_pessoas}`,
  ];

  if (entrada.adultos != null) linhas.push(`Adultos: ${entrada.adultos}`);
  if (entrada.criancas != null) linhas.push(`Crianças: ${entrada.criancas}`);
  if (entrada.bebes != null) linhas.push(`Bebês: ${entrada.bebes}`);
  if (entrada.estilo) linhas.push(`Estilo: ${entrada.estilo}`);
  if (entrada.restricoes) {
    linhas.push(`Restrições/preferências: ${entrada.restricoes}`);
  }
  if (entrada.observacoes) linhas.push(`Observações: ${entrada.observacoes}`);
  if (entrada.duracao_horas != null) {
    linhas.push(`Duração estimada (horas): ${entrada.duracao_horas}`);
  }

  linhas.push("");
  linhas.push(
    "Retorne o JSON com: nome_cardapio, resumo_publico, justificativa, premissas[], bebes_considerados, aviso_bebes, categorias[{nome, itens[{nome, tipo, quantidade, unidade, observacao, publico_alvo}]}].",
  );

  return linhas.join("\n");
}
