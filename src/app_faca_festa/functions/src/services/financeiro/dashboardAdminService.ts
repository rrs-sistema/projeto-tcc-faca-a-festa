/**
 * Dashboard financeiro/comercial admin.
 * Volume contratado ≠ receita da plataforma.
 * Alternativas da mesma necessidade não somam previsão.
 * Idempotente: mesmos fatos → mesmos totais.
 * Nunca inclui custos/margens privados de fornecedor.
 */

export type FatoComercial = {
  idEvento: string;
  idOrcamento: string;
  idNecessidade?: string | null;
  idFornecedor?: string | null;
  idServico?: string | null;
  contratado: boolean;
  valorOportunidadeCentavos: number;
  valorContratadoCentavos: number;
  pagoCentavos: number;
  alternativaAtiva?: boolean;
  dataEvento?: string | null;
  dataContratacao?: string | null;
  statusEvento?: string | null;
  consultaPagamentoCompleta?: boolean;
};

export type FatoComissao = {
  id: string;
  status: string;
  valorOriginalCentavos: number;
  valorAjustesCentavos?: number;
  valorLiquidadoCentavos?: number;
  vencimento?: string | null;
  idEvento?: string | null;
};

export type DashboardAdmin = {
  qtdEventos: number;
  qtdContratos: number;
  qtdOportunidades: number;
  qtdEventosExecucao: number;
  qtdEventosRealizados: number;
  qtdServicosDistintos: number;
  qtdFornecedoresDistintos: number;
  valorOportunidadesCentavos: number;
  volumeContratadoCentavos: number;
  pagamentosEventosCentavos: number;
  receitaPlataformaCentavos: number;
  comissaoConfigurada: boolean;
  comissaoPrevistasCentavos: number;
  comissaoGeradasCentavos: number;
  comissaoAReceberCentavos: number;
  comissaoVencidasCentavos: number;
  comissaoRecebidasCentavos: number;
  comissaoAjustadasCentavos: number;
  completo: boolean;
  eixoTemporal: string;
  rotuloResultado: string;
  formulaAbrangencia: string;
  despesasPlataformaCentavos: number | null;
  resultadoGerencialCentavos: number | null;
  linhasEvento: Array<Record<string, unknown>>;
};

type Acc = {
  dataEvento: string | null;
  status: string | null;
  contratos: Set<string>;
  servicos: Set<string>;
  previsaoPorNec: Map<string, number>;
  contratado: number;
  pago: number;
  pagamentoIncompleto: boolean;
};

export function agregarDashboardAdmin(params: {
  fatos: FatoComercial[];
  comissoes?: FatoComissao[];
  politicaComissaoAtiva?: boolean;
  despesasPlataformaCentavos?: number | null;
  eixoTemporal?: string;
  agora?: Date;
}): DashboardAdmin {
  const fatos = params.fatos;
  const comissoes = params.comissoes ?? [];
  const politicaAtiva = params.politicaComissaoAtiva === true;
  const now = params.agora ?? new Date();
  const eixo = params.eixoTemporal ?? "data_evento";

  const eventos = new Set<string>();
  const contratos = new Set<string>();
  const oportunidades = new Set<string>();
  const servicos = new Set<string>();
  const fornecedores = new Set<string>();
  const eventosExecucao = new Set<string>();
  const eventosRealizados = new Set<string>();
  const oppPorNec = new Map<string, number>();
  const porEvento = new Map<string, Acc>();

  let volumeContratado = 0;
  let pagamentos = 0;
  let completo = true;

  for (const f of fatos) {
    if (!f.idEvento || !f.idOrcamento) {
      completo = false;
      continue;
    }
    eventos.add(f.idEvento);
    if (f.idFornecedor) fornecedores.add(f.idFornecedor);
    const svc = f.idServico || f.idNecessidade || f.idOrcamento;
    if (svc) servicos.add(svc);

    const st = (f.statusEvento || "").toLowerCase();
    if (st.includes("execuc") || st.includes("andamento")) {
      eventosExecucao.add(f.idEvento);
    }
    if (st.includes("realiz") || st.includes("encerr") || st.includes("conclu")) {
      eventosRealizados.add(f.idEvento);
    }
    if (f.consultaPagamentoCompleta === false) completo = false;

    let acc = porEvento.get(f.idEvento);
    if (!acc) {
      acc = {
        dataEvento: f.dataEvento ?? null,
        status: f.statusEvento ?? null,
        contratos: new Set(),
        servicos: new Set(),
        previsaoPorNec: new Map(),
        contratado: 0,
        pago: 0,
        pagamentoIncompleto: false,
      };
      porEvento.set(f.idEvento, acc);
    }
    if (f.dataEvento) acc.dataEvento = acc.dataEvento || f.dataEvento;
    if (f.statusEvento) acc.status = acc.status || f.statusEvento;
    acc.servicos.add(svc);

    if (f.contratado) {
      contratos.add(f.idOrcamento);
      volumeContratado += f.valorContratadoCentavos;
      pagamentos += f.pagoCentavos;
      acc.contratos.add(f.idOrcamento);
      acc.contratado += f.valorContratadoCentavos;
      acc.pago += f.pagoCentavos;
      if (f.consultaPagamentoCompleta === false) acc.pagamentoIncompleto = true;
    } else {
      oportunidades.add(f.idOrcamento);
      const nec = f.idNecessidade || f.idOrcamento;
      if (f.alternativaAtiva !== false) {
        const atual = oppPorNec.get(nec) ?? 0;
        if (f.valorOportunidadeCentavos > atual) {
          oppPorNec.set(nec, f.valorOportunidadeCentavos);
        }
        const prev = acc.previsaoPorNec.get(nec) ?? 0;
        if (f.valorOportunidadeCentavos > prev) {
          acc.previsaoPorNec.set(nec, f.valorOportunidadeCentavos);
        }
      }
    }
  }

  let valorOportunidades = 0;
  for (const v of oppPorNec.values()) valorOportunidades += v;

  const comissaoPorEvento = new Map<string, number>();
  let previstas = 0;
  let geradas = 0;
  let aReceber = 0;
  let vencidas = 0;
  let recebidas = 0;
  let ajustadas = 0;

  if (politicaAtiva || comissoes.length > 0) {
    for (const c of comissoes) {
      const st = (c.status || "").toLowerCase();
      if (st === "previsao") previstas += c.valorOriginalCentavos;
      else geradas += c.valorOriginalCentavos;
      const ajustes = c.valorAjustesCentavos ?? 0;
      if (ajustes !== 0) ajustadas += Math.abs(ajustes);
      const liq = c.valorLiquidadoCentavos ?? 0;
      recebidas += liq;
      const saldo = c.valorOriginalCentavos + ajustes - liq;
      if (saldo > 0 && st !== "estornada" && st !== "recebida") {
        aReceber += saldo;
        const venc = c.vencimento ? new Date(c.vencimento) : null;
        if (st === "vencida" || (venc && venc < now)) vencidas += saldo;
      }
      if (c.idEvento) {
        comissaoPorEvento.set(
          c.idEvento,
          (comissaoPorEvento.get(c.idEvento) ?? 0) + c.valorOriginalCentavos,
        );
      }
    }
  }

  const receitaPlataforma = recebidas;
  const despesas = params.despesasPlataformaCentavos ?? null;
  let resultado: number | null = null;
  let rotulo = "receitas_e_movimentos";
  if (despesas !== null && despesas !== undefined) {
    resultado = receitaPlataforma - despesas;
    rotulo = "resultado_gerencial_parcial";
  }

  const linhas = [...porEvento.entries()].map(([idEvento, a]) => {
    let previsao = 0;
    for (const v of a.previsaoPorNec.values()) previsao += v;
    return {
      id_evento: idEvento,
      data_evento: a.dataEvento,
      status: a.status,
      qtd_servicos: a.servicos.size,
      qtd_contratos: a.contratos.size,
      contratado_centavos: a.contratado,
      pago_centavos: a.pago,
      saldo_centavos: a.contratado - a.pago,
      previsao_disponivel_centavos: previsao,
      comissao_centavos: comissaoPorEvento.get(idEvento) ?? 0,
      pagamento_incompleto: a.pagamentoIncompleto,
    };
  });

  return {
    qtdEventos: eventos.size,
    qtdContratos: contratos.size,
    qtdOportunidades: oportunidades.size,
    qtdEventosExecucao: eventosExecucao.size,
    qtdEventosRealizados: eventosRealizados.size,
    qtdServicosDistintos: servicos.size,
    qtdFornecedoresDistintos: fornecedores.size,
    valorOportunidadesCentavos: valorOportunidades,
    volumeContratadoCentavos: volumeContratado,
    pagamentosEventosCentavos: pagamentos,
    receitaPlataformaCentavos: receitaPlataforma,
    comissaoConfigurada: politicaAtiva || comissoes.length > 0,
    comissaoPrevistasCentavos: previstas,
    comissaoGeradasCentavos: geradas,
    comissaoAReceberCentavos: aReceber,
    comissaoVencidasCentavos: vencidas,
    comissaoRecebidasCentavos: recebidas,
    comissaoAjustadasCentavos: ajustadas,
    completo,
    eixoTemporal: eixo,
    rotuloResultado: rotulo,
    formulaAbrangencia:
      "receita_plataforma = comissoes_recebidas; volume_contratado ≠ receita",
    despesasPlataformaCentavos: despesas,
    resultadoGerencialCentavos: resultado,
    linhasEvento: linhas,
  };
}

/** Centavos a partir de campos novos ou legado double (sem migração silenciosa ambígua). */
export function centavosDeOrcamento(data: Record<string, unknown>): {
  contratado: number;
  oportunidade: number;
  pago: number;
  pagoCompleto: boolean;
} {
  const contratadoMap = data.valor_contratado_centavos;
  let contratado = 0;
  if (typeof contratadoMap === "number" && Number.isInteger(contratadoMap)) {
    contratado = contratadoMap;
  } else if (data.contrato_financeiro && typeof data.contrato_financeiro === "object") {
    const v = (data.contrato_financeiro as { valor?: { centavos?: number } }).valor
      ?.centavos;
    if (typeof v === "number") contratado = v;
  } else if (typeof data.valor_contratado === "number") {
    contratado = Math.round(data.valor_contratado * 100);
  } else if (typeof data.custo_estimado === "number") {
    contratado = Math.round(data.custo_estimado * 100);
  }

  let oportunidade = 0;
  if (typeof data.custo_estimado === "number") {
    oportunidade = Math.round(data.custo_estimado * 100);
  }

  let pago = 0;
  let pagoCompleto = true;
  if (typeof data.pago_liquido_centavos === "number") {
    pago = data.pago_liquido_centavos;
  } else if (typeof data.pago === "number") {
    pago = Math.round(data.pago * 100);
  } else {
    pagoCompleto = false;
  }

  return { contratado, oportunidade, pago, pagoCompleto };
}
