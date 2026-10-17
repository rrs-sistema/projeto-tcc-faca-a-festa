import { financeiroCalculadora } from "../../services/calculadora/financeiroCalculadoraService";
import { CalculadoraIARequest, SugestaoBaseIA } from "../../types/calculadoraIA.types";

/**
 * Nome estável do prompt usado pela calculadora inteligente.
 * Não altere este identificador a cada ajuste de texto; altere apenas quando mudar o propósito do prompt.
 */
export const PROMPT_CALCULADORA_IA_NAME = "calculadora_festa_analise_ia";

/**
 * Versão do prompt.
 * Incremente quando mudar regras, critérios, tom, formato esperado ou estratégia de análise.
 */
export const PROMPT_CALCULADORA_IA_VERSION = "1.7.0";

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
    "Analise o cardápio e os gastos existentes em planejamento. Quantidade confirmada não significa comprada.",
    "Não some novamente o custo completo de itens já contemplados no orçamento. Use custo_projetado e saldo_apos_planejamento fornecidos.",
    "Se a estimativa estiver incompleta ou o orçamento não estiver carregado, explique a limitação e não conclua que a festa cabe no limite.",
    "Explique a participação entre alternativas, o rendimento e o arredondamento de embalagens fornecidos em planejamento.regras_em_uso. Esses fatores já foram aplicados pelo motor; não aplique novamente.",
    "Divisão entre alternativas e ajuste pela duração só existem se explicitamente ativados na regra. Uma festa longa não implica várias refeições; use numero_servicos informado por item.",
    "Referências por pessoa não comprovam suficiência. Diferencie alimento cru, seco e pronto; quando o estado ou o papel na refeição não estiver definido, peça essa informação antes de julgar a porção adequada.",
    "Perfis e pesos de convidados são premissas do aplicativo, não necessidades nutricionais validadas. Reduzir porções ou reserva não demonstra economia viável nem preserva automaticamente a suficiência.",
    "Referências contextuais possuem papel, estado, fonte e faixa culinária. consumo_min/consumo_max não são intervalos estatísticos. Se ajustar_por_perfil for false, não sugira reaplicar multiplicador de quantidade.",
    "Quando origem for consumo_observado, explique o número de eventos e a natureza retrospectiva da mediana. Não invente medições, sobra, falta, aprendizado estatístico ou garantia de suficiência. Rendimento medido se aplica à receita informada, não a todo alimento com o mesmo nome.",
    "Diferencie gastos existentes, valores contratados e pagos. Cobertura de serviço é uma associação explícita do organizador, não uma confirmação de pagamento.",
    "Quando recomendar ajustar um item, preencha item_relacionado com o nome exato de um item calculado para permitir abrir sua edição no aplicativo.",
    "Não invente consumo para itens sem regra. Oriente o organizador a configurar a porção e a composição da refeição.",
    "Quando origem for proposta_contextual, trate a porção e a divisão entre acompanhamentos como proposta inicial explícita, não aprendizado de consumo ou comprovação de suficiência. Use as escolhas de proposta_respostas; não reaplique o fator_composicao já calculado.",
    "Se proposta_apenas_servir for true, a quantidade é pronta para servir e ainda não define compra crua ou fruta inteira. Não converta usando uma perda presumida. Faça somente a pergunta material sobre compra pronta ou rendimento medido. Preço ausente limita custo, não impede propor quantidades; não invente preço nem alegue ter pesquisado valores.",
    "Pode retornar sugestoes vazias quando não houver ajustes relevantes. Não crie alertas artificiais.",
    "Não apresente percentuais de risco, conforto, probabilidade de falta ou confiança: não há modelo calibrado para esses números. Descreva pendências verificáveis. Os campos legados de índices serão zerados pelo servidor e não representam probabilidades.",
    "Para financeiro, use planejamento.compras_restantes como contrato conciliado; se completo não for true, não conclua suficiência do limite. Diferencie compra restante e custo da necessidade total.",
    "Cada refeição pode ter público próprio em planejamento.operacao.refeicoes. Não aplique o total do evento a uma refeição com público específico.",
    "Restrições alimentares e ingredientes não podem ser inferidos pelo nome do prato. Use os grupos declarados, suas porções destinadas e a conferência de ingredientes, preparo e contato cruzado. Não certifique segurança alimentar nem ausência de alergênicos.",
    "Pendências alimentares impedem afirmar que todos os grupos estão atendidos, mesmo que o financeiro esteja completo. Não some novamente porções destinadas aos grupos: elas já fazem parte da quantidade calculada.",
    "O estoque possui lotes e reservas por destino. Não desconte o saldo total de um lote em cada refeição. A lista conciliada já inclui apenas as reservas do destino.",
    "Consumo observado exige data do consumo, recência e revisão de valores atípicos. Erro retrospectivo é uma medição, não probabilidade de falta nem comprovação de desempenho futuro.",
    "Retorne exclusivamente JSON válido no schema solicitado.",
  ].join("\n");
}

export function buildInput(
  request: CalculadoraIARequest,
  sugestoesBase: SugestaoBaseIA[] = [],
): string {
  const itensOrdenados = [...(request.itens ?? request.itens_calculados ?? request.itensCalculados ?? [])]
    .sort((a, b) => (asNumber(b.custo_estimado ?? b.custoEstimado) - asNumber(a.custo_estimado ?? a.custoEstimado)));

  const financeiro = financeiroCalculadora(request);
  const orcamentoDisponivel = financeiro.orcamento;
  const custoTotalEstimado = financeiro.custo;
  const custoSimulacao = asNumber(request.custo_total_estimado ?? request.custoTotalEstimado);

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
    planejamento: request.planejamento ?? {},
    financeiro: {
      orcamento_disponivel: orcamentoDisponivel,
      custo_total_estimado: custoTotalEstimado,
      custo_simulacao: custoSimulacao,
      estimativa_incompleta: financeiro.incompleto,
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
