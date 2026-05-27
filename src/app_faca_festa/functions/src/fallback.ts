import { CalculadoraIARequest, AnaliseCalculadoraIAResponse, SugestaoCalculadoraIAResponse } from "./types";
import { ANALISE_CALCULADORA_IA_SCHEMA_VERSION } from "./schema";
import { clamp } from "./validators";

export function buildFallbackAnalysis(request: CalculadoraIARequest): AnaliseCalculadoraIAResponse {
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

  const maiorItem = [...(request.itens ?? [])].sort((a, b) => (b.custo_estimado ?? 0) - (a.custo_estimado ?? 0))[0];
  if (maiorItem && (maiorItem.custo_estimado ?? 0) > 0) {
    sugestoes.push({
      id: "fallback_maior_item",
      titulo: "Maior impacto no orçamento",
      descricao: `${maiorItem.nome} é um dos itens com maior impacto financeiro na simulação.`,
      tipo: "planejamento",
      prioridade: "baixa",
      item_relacionado: maiorItem.nome,
      impacto_estimado: maiorItem.custo_estimado ?? 0,
    });
  }

  const indiceEconomia = acimaDoOrcamento ? 45 : 82;
  const indiceRisco = clamp((duracaoHoras >= 5 ? 45 : 25) + (percentualCriancas >= 0.35 ? 10 : 0), 0, 100);
  const indiceConforto = clamp(perfil.includes("premium") ? 88 : perfil.includes("econ") ? 62 : 76, 0, 100);

  return {
    titulo: "Análise inteligente da festa",
    resumo: acimaDoOrcamento ?
      "A simulação apresenta boa estrutura, mas precisa de revisão financeira antes de virar orçamento." :
      "A simulação está coerente com os dados informados e pode ser comparada com outros cenários.",
    indice_economia: indiceEconomia,
    indice_risco_faltar_itens: indiceRisco,
    indice_conforto: indiceConforto,
    custo_total_estimado: custoTotal,
    orcamento_disponivel: orcamento,
    diferenca_orcamento: diferenca,
    data_analise: new Date().toISOString(),
    sugestoes: sugestoes.slice(0, 8),
    diagnostico_financeiro: acimaDoOrcamento ?
      "O custo estimado ultrapassa o orçamento informado." :
      "O custo estimado está compatível com o orçamento informado ou não há orçamento definido.",
    diagnostico_consumo: "A análise considera convidados equivalentes, duração e itens selecionados na calculadora.",
    recomendacao_final: acimaDoOrcamento ?
      "Compare uma versão Padrão ou Econômica antes de aprovar a simulação." :
      "A simulação pode ser salva, comparada e aprovada para orçamento.",
    pontos_de_atencao: sugestoes.map((item) => item.titulo).slice(0, 5),
    proximas_acoes: [
      "Comparar com outro perfil de festa",
      "Revisar os itens com maior custo",
      "Aprovar a melhor simulação",
      "Transformar a simulação aprovada em orçamento",
    ],
    fonte: "fallback_local",
    versao_schema: ANALISE_CALCULADORA_IA_SCHEMA_VERSION,
  };
}
