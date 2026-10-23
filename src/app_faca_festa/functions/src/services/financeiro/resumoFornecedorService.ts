export type VendaFato = {
  id: string;
  id_evento: string;
  valor_contratado: number;
  recebido_confirmado?: number;
  adiantamento_caixa?: number;
  receita_realizada?: number;
  execucao_confirmada?: boolean;
  vencimento?: string | null;
};

export type CustoFato = {
  id: string;
  id_evento: string;
  incorrido: number;
  restante_previsto?: number;
  desembolso_caixa?: number;
  origem?: string;
  direto?: boolean;
};

export type ResumoFornecedor = {
  contratado: number;
  recebido: number;
  aReceber: number;
  custoRealizado: number;
  custoRestantePrevisto: number;
  custoDiretoPrevisto: number;
  outrasDespesasAusentes: boolean;
  receitaRealizada: number;
  adiantamentosCaixa: number;
  resultadoDiretoPrevisto: number;
  resultadoDiretoRealizado: number;
  margemContribuicao: number | null;
  entradasCaixa: number;
  saidasCaixa: number;
  movimentoLiquido: number;
  saldoFinal: number | null;
  completo: boolean;
  formula: string;
};

export function calcularResumoFornecedor(entrada: {
  vendas: VendaFato[];
  custos: CustoFato[];
  saldoInicial?: number | null;
  comissao?: number | null;
  taxas?: number | null;
  tributos?: number | null;
  idEvento?: string | null;
}): ResumoFornecedor {
  const filtro = entrada.idEvento ?? null;
  let contratado = 0;
  let recebido = 0;
  let aReceber = 0;
  let receitaRealizada = 0;
  let adiantamentos = 0;
  let custoRealizado = 0;
  let custoRestante = 0;
  let outras = 0;
  let temOutras = false;
  let completo = true;
  let saidasCusto = 0;

  for (const v of entrada.vendas) {
    if (filtro && v.id_evento !== filtro) continue;
    if (!fin(v.valor_contratado) || !fin(v.recebido_confirmado ?? 0)) {
      completo = false;
      continue;
    }
    const rec = v.recebido_confirmado ?? 0;
    contratado += v.valor_contratado;
    recebido += rec;
    aReceber += v.valor_contratado - rec;
    adiantamentos += v.adiantamento_caixa ?? 0;
    if (v.execucao_confirmada) {
      receitaRealizada +=
        (v.receita_realizada ?? 0) > 0 ? (v.receita_realizada as number) : v.valor_contratado;
    } else if ((v.receita_realizada ?? 0) > 0) {
      receitaRealizada += v.receita_realizada as number;
    }
  }

  for (const c of entrada.custos) {
    if (filtro && c.id_evento !== filtro) continue;
    if (!fin(c.incorrido) || !fin(c.restante_previsto ?? 0)) {
      completo = false;
      continue;
    }
    if (c.direto === false) {
      temOutras = true;
      outras += c.incorrido + (c.restante_previsto ?? 0);
    } else {
      custoRealizado += c.incorrido;
      custoRestante += c.restante_previsto ?? 0;
    }
    if (c.origem !== "estoque_consumo") {
      saidasCusto += c.desembolso_caixa ?? 0;
    }
  }

  const custoDiretoPrevisto = custoRealizado + custoRestante;
  const deducoes =
    (fin(entrada.comissao) ? (entrada.comissao as number) : 0) +
    (fin(entrada.taxas) ? (entrada.taxas as number) : 0) +
    (fin(entrada.tributos) ? (entrada.tributos as number) : 0);
  if (entrada.comissao == null && entrada.taxas == null && entrada.tributos == null) {
    completo = false;
  }
  if (!temOutras) completo = false;

  const resultadoPrevisto = contratado - custoDiretoPrevisto - deducoes - outras;
  const resultadoRealizado = receitaRealizada - custoRealizado - deducoes;
  const margem =
    receitaRealizada > 0 ? receitaRealizada - custoRealizado : null;

  const entradas = recebido;
  const saidas = saidasCusto;
  const movimento = entradas - saidas;
  const saldoFinal =
    entrada.saldoInicial != null && fin(entrada.saldoInicial)
      ? (entrada.saldoInicial as number) + movimento
      : null;

  return {
    contratado,
    recebido,
    aReceber,
    custoRealizado,
    custoRestantePrevisto: custoRestante,
    custoDiretoPrevisto,
    outrasDespesasAusentes: !temOutras,
    receitaRealizada,
    adiantamentosCaixa: adiantamentos,
    resultadoDiretoPrevisto: resultadoPrevisto,
    resultadoDiretoRealizado: resultadoRealizado,
    margemContribuicao: margem,
    entradasCaixa: entradas,
    saidasCaixa: saidas,
    movimentoLiquido: movimento,
    saldoFinal,
    completo,
    formula:
      "resultado_direto = receita_aplicavel - custo_direto (- comissao/taxas/tributos informados)",
  };
}

function fin(v: unknown): v is number {
  return typeof v === "number" && Number.isFinite(v) && v >= 0;
}
