/**
 * Comissão da plataforma sobre serviços contratados via plataforma.
 * Volume contratado ≠ receita até geração da obrigação.
 * Novas políticas: inativas por padrão. Simulação não persiste.
 */

export type PagadorComissao =
  | "fornecedor"
  | "organizador"
  | "plataforma_absorve";
export type BaseElegivel =
  | "servicos_contratados_plataforma"
  | "limite_global_cliente";
export type GatilhoGeracao =
  | "contratacao_confirmada"
  | "evento_realizado"
  | "manual";
export type Reversao = "proporcional" | "nenhuma" | "manual";
export type StatusObrigacao =
  | "previsao"
  | "gerada"
  | "a_vencer"
  | "vencida"
  | "recebida"
  | "estornada";

export interface PoliticaComissao {
  id: string;
  versao: number;
  /** Basis points 0–10000. Ausente ≠ zero. */
  percentualBps: number | null;
  baseElegivel: BaseElegivel;
  pagador: PagadorComissao;
  gatilho: GatilhoGeracao;
  reversao: Reversao;
  ativa: boolean;
  completa: boolean;
  diasVencimentoAposGeracao: number;
}

export interface ObrigacaoComissao {
  id: string;
  idEvento: string;
  idContrato: string;
  baseElegivelCentavos: number;
  valorOriginalCentavos: number;
  valorAjustesCentavos: number;
  valorLiquidadoCentavos: number;
  status: StatusObrigacao;
  politicaAplicada: Record<string, unknown>;
  idPagador?: string | null;
  idFornecedor?: string | null;
}

export function validarPercentualBps(bps: number | null | undefined): asserts bps is number {
  if (bps === null || bps === undefined) {
    throw Object.assign(new Error("Percentual ausente (diferente de zero válido)."), {
      code: "invalid-argument",
    });
  }
  if (!Number.isInteger(bps) || bps < 0 || bps > 10000) {
    throw Object.assign(new Error("Percentual deve estar entre 0% e 100%."), {
      code: "invalid-argument",
    });
  }
}

export function baseLiquidaElegivel(
  baseBrutaCentavos: number,
  descontosCentavos = 0,
  exclusoesCentavos = 0,
): number {
  if (baseBrutaCentavos < 0 || descontosCentavos < 0 || exclusoesCentavos < 0) {
    throw new Error("Valores da base não podem ser negativos.");
  }
  const liquida = baseBrutaCentavos - descontosCentavos - exclusoesCentavos;
  if (liquida < 0) {
    throw new Error("Descontos/exclusões excedem a base bruta.");
  }
  return liquida;
}

/** Arredondamento explícito ao centavo. */
export function calcularComissaoCentavos(
  baseLiquidaCentavos: number,
  percentualBps: number,
): number {
  validarPercentualBps(percentualBps);
  return Math.round((baseLiquidaCentavos * percentualBps) / 10000);
}

export function politicaPodeGerarDivida(politica: PoliticaComissao | null): boolean {
  if (!politica) return false;
  if (!politica.ativa) return false;
  if (!politica.completa) return false;
  if (politica.percentualBps === null || politica.percentualBps === undefined) {
    return false;
  }
  return true;
}

export function snapshotPolitica(p: PoliticaComissao): Record<string, unknown> {
  return {
    id_politica: p.id,
    versao: p.versao,
    percentual_bps: p.percentualBps,
    base_elegivel: p.baseElegivel,
    pagador: p.pagador,
    gatilho_geracao: p.gatilho,
    reversao: p.reversao,
    dias_vencimento_apos_geracao: p.diasVencimentoAposGeracao,
  };
}

export function simular(params: {
  politica: PoliticaComissao | null;
  baseBrutaCentavos: number;
  descontosCentavos?: number;
  exclusoesCentavos?: number;
}): {
  valorCentavos: number;
  baseLiquidaCentavos: number;
  percentualBps: number;
  podeGerar: boolean;
  motivoBloqueio?: string;
} {
  const { politica, baseBrutaCentavos } = params;
  const descontos = params.descontosCentavos ?? 0;
  const exclusoes = params.exclusoesCentavos ?? 0;
  if (!politica) {
    return {
      valorCentavos: 0,
      baseLiquidaCentavos: 0,
      percentualBps: 0,
      podeGerar: false,
      motivoBloqueio: "Política ausente — não gera dívida.",
    };
  }
  if (!politica.ativa) {
    return {
      valorCentavos: 0,
      baseLiquidaCentavos: 0,
      percentualBps: politica.percentualBps ?? 0,
      podeGerar: false,
      motivoBloqueio: "Política inativa — não gera dívida.",
    };
  }
  if (!politica.completa || politica.percentualBps === null) {
    return {
      valorCentavos: 0,
      baseLiquidaCentavos: 0,
      percentualBps: politica.percentualBps ?? 0,
      podeGerar: false,
      motivoBloqueio: "Política incompleta — não gera dívida.",
    };
  }
  if (politica.baseElegivel === "limite_global_cliente") {
    return {
      valorCentavos: 0,
      baseLiquidaCentavos: 0,
      percentualBps: politica.percentualBps,
      podeGerar: false,
      motivoBloqueio:
        "Base limite global do cliente exige autorização comercial explícita.",
    };
  }
  const liquida = baseLiquidaElegivel(baseBrutaCentavos, descontos, exclusoes);
  const valor = calcularComissaoCentavos(liquida, politica.percentualBps);
  return {
    valorCentavos: valor,
    baseLiquidaCentavos: liquida,
    percentualBps: politica.percentualBps,
    podeGerar: true,
  };
}

export function gerarObrigacao(params: {
  politica: PoliticaComissao;
  idObrigacao: string;
  idEvento: string;
  idContrato: string;
  baseBrutaCentavos: number;
  descontosCentavos?: number;
  exclusoesCentavos?: number;
  idPagador?: string;
  idFornecedor?: string;
  jaExistente?: ObrigacaoComissao | null;
}): ObrigacaoComissao {
  if (params.jaExistente) return params.jaExistente;
  if (!politicaPodeGerarDivida(params.politica)) {
    throw Object.assign(
      new Error("Política ausente/inativa/incompleta não gera dívida."),
      { code: "failed-precondition" },
    );
  }
  const s = simular({
    politica: params.politica,
    baseBrutaCentavos: params.baseBrutaCentavos,
    descontosCentavos: params.descontosCentavos,
    exclusoesCentavos: params.exclusoesCentavos,
  });
  if (!s.podeGerar) {
    throw Object.assign(new Error(s.motivoBloqueio || "Não gera obrigação."), {
      code: "failed-precondition",
    });
  }
  return {
    id: params.idObrigacao,
    idEvento: params.idEvento,
    idContrato: params.idContrato,
    baseElegivelCentavos: s.baseLiquidaCentavos,
    valorOriginalCentavos: s.valorCentavos,
    valorAjustesCentavos: 0,
    valorLiquidadoCentavos: 0,
    status: "gerada",
    politicaAplicada: snapshotPolitica(params.politica),
    idPagador: params.idPagador ?? null,
    idFornecedor: params.idFornecedor ?? null,
  };
}

export function saldoCentavos(o: ObrigacaoComissao): number {
  return o.valorOriginalCentavos + o.valorAjustesCentavos - o.valorLiquidadoCentavos;
}

export function liquidarManual(
  obrigacao: ObrigacaoComissao,
  valorCentavos: number,
): ObrigacaoComissao {
  if (!Number.isInteger(valorCentavos) || valorCentavos <= 0) {
    throw Object.assign(new Error("Informe valor de liquidação positivo."), {
      code: "invalid-argument",
    });
  }
  if (obrigacao.status === "estornada") {
    throw Object.assign(new Error("Obrigação estornada não aceita liquidação."), {
      code: "failed-precondition",
    });
  }
  const liquidado = obrigacao.valorLiquidadoCentavos + valorCentavos;
  const saldo =
    obrigacao.valorOriginalCentavos +
    obrigacao.valorAjustesCentavos -
    liquidado;
  return {
    ...obrigacao,
    valorLiquidadoCentavos: liquidado,
    status: saldo <= 0 ? "recebida" : "a_vencer",
  };
}

export function ajustePorReducaoElegivel(
  percentualBpsAplicado: number,
  reducaoBaseCentavos: number,
  reversao: Reversao,
): { ajusteCentavos: number; tipo: string; creditoReembolsoExplicito: boolean } {
  if (reducaoBaseCentavos <= 0) {
    throw new Error("Informe a redução elegível.");
  }
  if (reversao === "nenhuma") {
    return { ajusteCentavos: 0, tipo: "sem_reversao", creditoReembolsoExplicito: false };
  }
  if (reversao === "manual") {
    return {
      ajusteCentavos: 0,
      tipo: "reversao_manual_pendente",
      creditoReembolsoExplicito: false,
    };
  }
  const credito = calcularComissaoCentavos(reducaoBaseCentavos, percentualBpsAplicado);
  return {
    ajusteCentavos: -credito,
    tipo: "reversao_proporcional",
    creditoReembolsoExplicito: credito > 0,
  };
}

export function aplicarAjuste(
  obrigacao: ObrigacaoComissao,
  ajusteCentavos: number,
): ObrigacaoComissao {
  return {
    ...obrigacao,
    valorAjustesCentavos: obrigacao.valorAjustesCentavos + ajusteCentavos,
  };
}
