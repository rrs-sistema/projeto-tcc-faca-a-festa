import { CalculadoraIARequest, SugestaoBaseIA } from "../../types";

/**
 * Nome estável do prompt usado pela calculadora inteligente.
 * Não altere este identificador a cada ajuste de texto; altere apenas quando mudar o propósito do prompt.
 */
export const PROMPT_CALCULADORA_IA_NAME = "calculadora_festa_analise_ia";

/**
 * Versão do prompt.
 * Incremente quando mudar regras, critérios, tom, formato esperado ou estratégia de análise.
 */
export const PROMPT_CALCULADORA_IA_VERSION = "1.1.0";

export function buildInstructions(): string {
  return [
    "Você é um assistente especialista em planejamento financeiro e operacional de festas sociais.",
    "Seu papel é interpretar os dados calculados pelo sistema Faça a Festa e orientar o organizador.",
    "Não recalcule quantidades do zero e não invente preços fora dos dados enviados.",
    "Use os dados recebidos no payload como fonte de verdade para números, custos, quantidades e orçamento.",
    "Use as sugestões base do sistema como referência curada para orientar a análise, sem copiá-las mecanicamente.",
    "Não invente regras internas do sistema Faça a Festa que não estejam no payload ou nas sugestões base.",
    "Adapte as sugestões base ao contexto do evento, considerando tipo de evento, perfil da festa, orçamento, adultos, crianças, bebês, duração e itens calculados.",
    "Quando houver muitas crianças, avalie sucos, água, descartáveis, lembrancinhas e itens infantis.",
    "Quando a duração for alta, avalie risco de faltar bebidas e itens de recepção.",
    "Quando o custo estiver acima do orçamento, sugira economia sem comprometer os itens essenciais.",
    "Evite linguagem exagerada. Seja profissional, claro e direto.",
    "Não invente campos de rastreabilidade técnica. A Cloud Function preencherá versão do prompt, versão do schema, modelo utilizado e sugestões base usadas.",
    "Retorne exclusivamente JSON válido no schema solicitado.",
  ].join("\n");
}

export function buildInput(
  request: CalculadoraIARequest,
  sugestoesBase: SugestaoBaseIA[] = [],
): string {
  const itensOrdenados = [...(request.itens ?? request.itens_calculados ?? request.itensCalculados ?? [])]
    .sort((a, b) => (asNumber(b.custo_estimado ?? b.custoEstimado) - asNumber(a.custo_estimado ?? a.custoEstimado)));

  const orcamentoDisponivel = nullableNumber(
    request.orcamento_disponivel ?? request.orcamentoDisponivel,
  );
  const custoTotalEstimado = asNumber(
    request.custo_total_estimado ?? request.custoTotalEstimado ?? request.custo_estimado ?? request.custoEstimado,
  );

  return JSON.stringify({
    contexto: {
      produto: "Faça a Festa",
      modulo: "Calculadora inteligente de festa",
      objetivo_ia: "Apoiar decisão de planejamento, economia, consumo e próximas ações.",
      regra_importante: "A IA interpreta dados já calculados; ela não é o motor matemático da calculadora.",
      prompt_nome: PROMPT_CALCULADORA_IA_NAME,
      prompt_versao: PROMPT_CALCULADORA_IA_VERSION,
    },
    evento: {
      id_calculo: request.id_calculo ?? request.idCalculo ?? request.id,
      id_evento: request.id_evento ?? request.idEvento,
      nome_evento: request.nome_evento ?? request.nomeEvento,
      tipo_evento: request.tipo_evento ?? request.tipoEvento,
      perfil_festa: request.perfil_festa ?? request.perfilFesta,
      perfil_festa_tipo: request.perfil_festa_tipo ?? request.perfilFestaTipo,
      duracao_horas: request.duracao_horas ?? request.duracaoHoras,
      margem: request.margem,
    },
    convidados: {
      adultos: request.adultos,
      criancas: request.criancas ?? request.crianças,
      bebes: request.bebes ?? request.bebês,
      total_informado: request.total_informado ?? request.totalInformado ?? request.total_convidados ?? request.totalConvidados,
      total_equivalente: request.total_equivalente ?? request.totalEquivalente ?? request.convidados_equivalentes ?? request.convidadosEquivalentes,
      total_equivalente_arredondado: request.total_equivalente_arredondado ?? request.totalEquivalenteArredondado,
    },
    financeiro: {
      orcamento_disponivel: orcamentoDisponivel,
      custo_total_estimado: custoTotalEstimado,
      diferenca_orcamento: orcamentoDisponivel === null
        ? 0
        : custoTotalEstimado - orcamentoDisponivel,
    },
    itens_calculados: itensOrdenados.map((item) => ({
      id_item_resultado: item.id_item_resultado ?? item.idItemResultado,
      nome: item.nome,
      categoria: item.categoria,
      tipo_item: item.tipo_item ?? item.tipoItem,
      publico_alvo: item.publico_alvo ?? item.publicoAlvo,
      unidade: item.unidade,
      quantidade: item.quantidade,
      quantidade_por_convidado_equivalente: item.quantidade_por_convidado_equivalente ?? item.quantidadePorConvidadoEquivalente,
      valor_unitario_medio: item.valor_unitario_medio ?? item.valorUnitarioMedio,
      custo_estimado: item.custo_estimado ?? item.custoEstimado,
      regra_aplicada: item.regra_aplicada ?? item.regraAplicada,
    })),
    sugestoes_base_do_sistema: sugestoesBase.slice(0, 12).map((sugestao) => ({
      id: sugestao.id,
      versao: sugestao.versao,
      titulo: sugestao.titulo,
      descricao: sugestao.descricao,
      tema: sugestao.tema,
      categoria: sugestao.categoria,
      prioridade: sugestao.prioridade,
      gatilhos: sugestao.gatilhos,
      tags: sugestao.tags,
      origem: sugestao.origem,
      status_revisao: sugestao.status_revisao,
      data_publicacao: sugestao.data_publicacao,
    })),
    instrucoes_de_uso_das_sugestoes_base: [
      "Use as sugestões base como referência curada do produto.",
      "Priorize sugestões compatíveis com tipo de evento, perfil da festa e orçamento.",
      "Adapte o texto ao contexto real do usuário.",
      "Não transforme sugestão base em regra matemática nova.",
      "Não crie custos ou quantidades que não estejam nos dados calculados.",
    ],
    saida_esperada: {
      titulo: "string",
      resumo: "string curta e executiva",
      indice_economia: "number 0-100",
      indice_risco_faltar_itens: "number 0-100",
      indice_conforto: "number 0-100",
      sugestoes: "até 8 sugestões objetivas",
      diagnostico_financeiro: "texto curto",
      diagnostico_consumo: "texto curto",
      recomendacao_final: "texto curto",
      pontos_de_atencao: "lista curta",
      proximas_acoes: "lista curta",
    },
  });
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", ".").replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function nullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  return asNumber(value);
}
