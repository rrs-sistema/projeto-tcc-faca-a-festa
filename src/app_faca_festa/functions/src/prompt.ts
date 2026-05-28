import { CalculadoraIARequest, SugestaoBaseIA } from "./types";

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
    "Retorne exclusivamente JSON válido no schema solicitado.",
  ].join("\n");
}

export function buildInput(
  request: CalculadoraIARequest,
  sugestoesBase: SugestaoBaseIA[] = [],
): string {
  const itensOrdenados = [...(request.itens ?? [])]
    .sort((a, b) => (b.custo_estimado ?? 0) - (a.custo_estimado ?? 0));

  return JSON.stringify({
    contexto: {
      produto: "Faça a Festa",
      modulo: "Calculadora inteligente de festa",
      objetivo_ia: "Apoiar decisão de planejamento, economia, consumo e próximas ações.",
      regra_importante: "A IA interpreta dados já calculados; ela não é o motor matemático da calculadora.",
    },
    evento: {
      id_calculo: request.id_calculo,
      id_evento: request.id_evento,
      nome_evento: request.nome_evento,
      tipo_evento: request.tipo_evento,
      perfil_festa: request.perfil_festa,
      perfil_festa_tipo: request.perfil_festa_tipo,
      duracao_horas: request.duracao_horas,
      margem: request.margem,
    },
    convidados: {
      adultos: request.adultos,
      criancas: request.criancas,
      bebes: request.bebes,
      total_informado: request.total_informado,
      total_equivalente: request.total_equivalente,
      total_equivalente_arredondado: request.total_equivalente_arredondado,
    },
    financeiro: {
      orcamento_disponivel: request.orcamento_disponivel,
      custo_total_estimado: request.custo_total_estimado,
      diferenca_orcamento: request.orcamento_disponivel === null || request.orcamento_disponivel === undefined
        ? 0
        : (request.custo_total_estimado ?? 0) - request.orcamento_disponivel,
    },
    itens_calculados: itensOrdenados.map((item) => ({
      id_item_resultado: item.id_item_resultado,
      nome: item.nome,
      categoria: item.categoria,
      tipo_item: item.tipo_item,
      publico_alvo: item.publico_alvo,
      unidade: item.unidade,
      quantidade: item.quantidade,
      quantidade_por_convidado_equivalente: item.quantidade_por_convidado_equivalente,
      valor_unitario_medio: item.valor_unitario_medio,
      custo_estimado: item.custo_estimado,
      regra_aplicada: item.regra_aplicada,
    })),
    sugestoes_base_do_sistema: sugestoesBase.slice(0, 12).map((sugestao) => ({
      id: sugestao.id,
      titulo: sugestao.titulo,
      descricao: sugestao.descricao,
      tema: sugestao.tema,
      categoria: sugestao.categoria,
      prioridade: sugestao.prioridade,
      gatilhos: sugestao.gatilhos,
      tags: sugestao.tags,
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
