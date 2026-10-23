import { calcularResumo } from "./resumoFinanceiro";

export type Necessidade = {
  id: string;
  descricao: string;
  quantidade_necessaria?: number;
  quantidade_contratada?: number;
  preco_unitario?: number | null;
  custo_estimado_total?: number | null;
  coberta_por_buffet?: boolean;
  eliminada?: boolean;
};

export type PrevisaoGerente = {
  contratado: number;
  pagoLiquido: number;
  saldoContratado: number;
  faltaContratar: number;
  despesasAdicionais: number;
  custoFinalPrevisto: number;
  folgaAntesReserva: number | null;
  completo: boolean;
  cabeNoLimite: boolean | null;
  alertas: string[];
};

/**
 * Previsão do gerente: contratos + necessidades restantes + despesas fora.
 * Pagamentos não entram de novo na previsão.
 */
export function calcularPrevisaoGerente(entrada: {
  limite?: number | null;
  reserva?: number;
  compromissos: Record<string, unknown>[];
  necessidades?: Necessidade[];
}): PrevisaoGerente {
  const resumo = calcularResumo(entrada.compromissos);
  const contratado = resumo.contratado;
  const pagoLiquido = resumo.pagoLiquido;
  const saldoContratado = contratado - pagoLiquido;
  let faltaContratar = 0;
  let despesasAdicionais = 0;
  let completo = resumo.completo;
  const alertas: string[] = [];

  for (const c of entrada.compromissos) {
    if (c.cancelado === true) continue;
    if (c.contratado !== true) {
      const desp = numero(c.despesas);
      if (desp > 0) despesasAdicionais += desp;
    }
  }

  for (const n of entrada.necessidades ?? []) {
    if (n.eliminada || n.coberta_por_buffet) continue;
    if (typeof n.quantidade_necessaria === "number") {
      const necessidade = n.quantidade_necessaria;
      const contratada = Math.max(0, Number(n.quantidade_contratada ?? 0));
      const restante = Math.max(0, necessidade - contratada);
      if (restante <= 0) continue;
      const preco = n.preco_unitario;
      if (typeof preco !== "number" || !Number.isFinite(preco) || preco <= 0) {
        completo = false;
        alertas.push("preco_ausente");
        continue;
      }
      faltaContratar += restante * preco;
      continue;
    }
    const est = n.custo_estimado_total;
    if (typeof est !== "number" || !Number.isFinite(est) || est < 0) {
      completo = false;
      alertas.push("preco_ausente");
      continue;
    }
    faltaContratar += est;
  }

  const previsto = contratado + faltaContratar + despesasAdicionais;
  const limite =
    typeof entrada.limite === "number" && Number.isFinite(entrada.limite) && entrada.limite >= 0
      ? entrada.limite
      : null;
  let folgaAntesReserva: number | null = null;
  let cabeNoLimite: boolean | null = null;
  if (limite != null && completo) {
    folgaAntesReserva = limite - previsto;
    cabeNoLimite = previsto <= limite;
    if (!cabeNoLimite) alertas.push("excesso_previsto");
  } else if (limite != null && !completo) {
    cabeNoLimite = null;
    alertas.push("consulta_incompleta");
  }

  return {
    contratado,
    pagoLiquido,
    saldoContratado,
    faltaContratar,
    despesasAdicionais,
    custoFinalPrevisto: previsto,
    folgaAntesReserva,
    completo,
    cabeNoLimite,
    alertas,
  };
}

function numero(v: unknown): number {
  return typeof v === "number" && Number.isFinite(v) && v >= 0 ? v : 0;
}
