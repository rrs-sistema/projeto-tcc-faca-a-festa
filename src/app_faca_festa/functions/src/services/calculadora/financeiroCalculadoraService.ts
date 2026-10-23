import { CalculadoraIARequest } from "../../types/calculadoraIA.types";

/** Números da calculadora são autoritativos; a IA apenas explica o cenário. */
export function financeiroCalculadora(payload: CalculadoraIARequest) {
  const contexto = (payload.planejamento && typeof payload.planejamento === "object")
    ? payload.planejamento as Record<string, unknown> : {};
  const custo = numero(contexto.custo_projetado ?? payload.custo_total_estimado ?? payload.custoTotalEstimado);
  const resumo = contexto.compras_restantes && typeof contexto.compras_restantes === "object"
    ? contexto.compras_restantes as Record<string, unknown> : null;
  const novoContrato = resumo?.versao_financeiro === 2;
  const contratoInvalido = novoContrato && [resumo!.orcado, resumo!.compras_restantes_conhecidas,
    resumo!.quantidades_pendentes, resumo!.precos_pendentes,
    resumo!.compras_sem_registro_financeiro].some(valor =>
    typeof valor !== "number" || !Number.isFinite(valor) || valor < 0);
  const incompleto = contexto.estimativa_incompleta === true || contexto.orcamento_carregado === false ||
    contratoInvalido ||
    (resumo !== null && (resumo.completo !== true || resumo.consulta_completa !== true ||
      resumo.sobreposicao_orcamento === true || numero(resumo.quantidades_pendentes) > 0 ||
      numero(resumo.precos_pendentes) > 0 || numero(resumo.compras_sem_registro_financeiro) > 0));
  const custoConciliado = novoContrato
    ? numero(resumo!.orcado) + numero(resumo!.compras_restantes_conhecidas) : custo;
  const limite = payload.orcamento_disponivel ?? payload.orcamentoDisponivel;
  const orcamento = !incompleto && typeof limite === "number" && Number.isFinite(limite) && limite >= 0
    ? limite : null;
  return {
    custo: custoConciliado,
    incompleto,
    orcamento,
    diferenca: orcamento === null ? 0 : custoConciliado - orcamento,
  };
}

function numero(valor: unknown): number {
  return typeof valor === "number" && Number.isFinite(valor) ? Math.max(0, valor) : 0;
}
