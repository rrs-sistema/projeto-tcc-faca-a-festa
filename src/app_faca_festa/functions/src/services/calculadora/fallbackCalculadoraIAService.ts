import {
  CalculadoraIARequest,
  AnaliseCalculadoraIAResponse,
  SugestaoCalculadoraIAResponse,
  SugestaoBaseIA,
  TipoSugestao,
  PrioridadeSugestao,
} from "../../types/calculadoraIA.types";


import { clamp } from "../../validators";

import {
  PROMPT_CALCULADORA_IA_NAME,
  PROMPT_CALCULADORA_IA_VERSION,
} from "../../ia/calculadora/prompt";

export function buildFallbackAnalysis(
  request: CalculadoraIARequest,
  sugestoesBase: SugestaoBaseIA[] = [],
): AnaliseCalculadoraIAResponse {
  const custoTotal = request.custo_total_estimado ?? 0;
  const orcamento = request.orcamento_disponivel ?? null;
  const diferenca = orcamento === null ? 0 : custoTotal - orcamento;
  const acimaDoOrcamento = orcamento !== null && diferenca > 0;
  const duracaoHoras = request.duracao_horas ?? 4;
  const criancas = request.criancas ?? 0;
  const totalInformado = request.total_informado ?? 0;
  const percentualCriancas = totalInformado > 0 ? criancas / totalInformado : 0;
  const perfil = (request.perfil_festa ?? "padrão").toLowerCase();

  const sugestoes: SugestaoCalculadoraIAResponse[] = [];

  if (acimaDoOrcamento) {
    sugestoes.push({
      id: "fallback_orcamento_acima",
      titulo: "Revisar custo total da festa",
      descricao: `A estimativa está acima do orçamento informado em aproximadamente R$ ${diferenca.toFixed(2)}.`,
      tipo: "economia",
      prioridade: "alta",
      item_relacionado: null,
      impacto_estimado: diferenca,
    });
  }

  if (perfil.includes("premium") && acimaDoOrcamento) {
    sugestoes.push({
      id: "fallback_perfil_premium",
      titulo: "Comparar com perfil Padrão",
      descricao: "O perfil Premium aumenta a margem e o custo médio. Compare com uma simulação Padrão antes de converter em orçamento.",
      tipo: "planejamento",
      prioridade: "media",
      item_relacionado: null,
      impacto_estimado: 0,
    });
  }

  if (duracaoHoras >= 5) {
    sugestoes.push({
      id: "fallback_duracao_bebidas",
      titulo: "Atenção para bebidas",
      descricao: "Eventos com 5 horas ou mais exigem maior atenção a água, sucos e bebidas em geral.",
      tipo: "alerta",
      prioridade: "media",
      item_relacionado: "Bebidas",
      impacto_estimado: 0,
    });
  }

  if (percentualCriancas >= 0.35) {
    sugestoes.push({
      id: "fallback_criancas",
      titulo: "Evento com forte presença de crianças",
      descricao: "Considere reforçar sucos, descartáveis, lembrancinhas e opções infantis no planejamento.",
      tipo: "melhoria",
      prioridade: "media",
      item_relacionado: null,
      impacto_estimado: 0,
    });
  }

  const maiorItem = [...(request.itens ?? [])]
    .sort((a, b) => (b.custo_estimado ?? 0) - (a.custo_estimado ?? 0))[0];

  if (maiorItem && (maiorItem.custo_estimado ?? 0) > 0) {
    sugestoes.push({
      id: "fallback_maior_item",
      titulo: "Maior impacto no orçamento",
      descricao: `${maiorItem.nome} é um dos itens com maior impacto financeiro na simulação.`,
      tipo: "planejamento",
      prioridade: "baixa",
      item_relacionado: maiorItem.nome ?? '',
      impacto_estimado: maiorItem.custo_estimado ?? 0,
    });
  }

  incluirSugestoesBaseNoFallback(sugestoes, sugestoesBase);

  const indiceEconomia = acimaDoOrcamento ? 45 : 82;
  const indiceRisco = clamp((duracaoHoras >= 5 ? 45 : 25) + (percentualCriancas >= 0.35 ? 10 : 0), 0, 100);
  const indiceConforto = clamp(perfil.includes("premium") ? 88 : perfil.includes("econ") ? 62 : 76, 0, 100);
  const sugestoesFinais = sugestoes.slice(0, 8);

  const dataProcessamento = new Date().toISOString();

  return {
    titulo: "Análise inteligente da festa",

    resumo: acimaDoOrcamento
      ? "A simulação apresenta boa estrutura, mas precisa de revisão financeira antes de virar orçamento."
      : "A simulação está coerente com os dados informados e pode ser comparada com outros cenários.",

    indice_economia: indiceEconomia,
    indice_risco_faltar_itens: indiceRisco,
    indice_conforto: indiceConforto,

    custo_total_estimado: custoTotal,
    orcamento_disponivel: orcamento,
    diferenca_orcamento: diferenca,

    data_analise: dataProcessamento,

    sugestoes: sugestoesFinais,

    diagnostico_financeiro: acimaDoOrcamento
      ? "O custo estimado ultrapassa o orçamento informado."
      : "O custo estimado está compatível com o orçamento informado ou não há orçamento definido.",

    diagnostico_consumo:
      "A análise considera convidados equivalentes, duração e itens selecionados na calculadora.",

    recomendacao_final: acimaDoOrcamento
      ? "Compare uma versão Padrão ou Econômica antes de aprovar a simulação."
      : "A simulação pode ser salva, comparada e aprovada para orçamento.",

    pontos_de_atencao: sugestoesFinais
      .map((item) => item.titulo)
      .slice(0, 5),

    proximas_acoes: [
      "Comparar com outro perfil de festa",
      "Revisar os itens com maior custo",
      "Aprovar a melhor simulação",
      "Transformar a simulação aprovada em orçamento",
    ],

    fonte: "fallback_local",

    // Versionamento do schema
    versao_schema: PROMPT_CALCULADORA_IA_VERSION,

    // Versionamento do prompt
    nome_prompt: PROMPT_CALCULADORA_IA_NAME,
    versao_prompt: PROMPT_CALCULADORA_IA_VERSION,

    // No fallback local puro, nenhuma sugestão base da IA generativa foi usada diretamente
    ids_sugestoes_base_utilizadas: [],
    versoes_sugestoes_base_utilizadas: {},
    total_sugestoes_base_utilizadas: 0,

    // Rastreabilidade técnica
    modelo_ia_utilizado: "fallback_local_regras_v1",
    data_processamento: dataProcessamento,
  };
}

function incluirSugestoesBaseNoFallback(
  sugestoes: SugestaoCalculadoraIAResponse[],
  sugestoesBase: SugestaoBaseIA[],
): void {
  const idsExistentes = new Set(sugestoes.map((item) => item.id));

  for (const sugestaoBase of sugestoesBase) {
    if (sugestoes.length >= 8) return;
    if (idsExistentes.has(sugestaoBase.id)) continue;

    sugestoes.push({
      id: sugestaoBase.id,
      titulo: sugestaoBase.titulo,
      descricao: sugestaoBase.descricao,
      tipo: mapCategoriaBaseParaTipoResposta(sugestaoBase.categoria),
      prioridade: mapPrioridadeBaseParaPrioridadeResposta(sugestaoBase.prioridade),
      item_relacionado: sugestaoBase.tema || null,
      impacto_estimado: 0,
    });

    idsExistentes.add(sugestaoBase.id);
  }
}

function mapCategoriaBaseParaTipoResposta(categoria: string): TipoSugestao {
  switch (categoria) {
    case "economia":
    case "financeiro":
      return "economia";
    case "alerta":
    case "consumo":
      return "alerta";
    case "cardapio":
    case "decoracao":
    case "fornecedor":
    case "organizacao":
    case "geral":
      return "planejamento";
    default:
      return "planejamento";
  }
}

function mapPrioridadeBaseParaPrioridadeResposta(prioridade: string): PrioridadeSugestao {
  switch (prioridade) {
    case "critica":
    case "alta":
      return "alta";
    case "baixa":
      return "baixa";
    default:
      return "media";
  }
}
