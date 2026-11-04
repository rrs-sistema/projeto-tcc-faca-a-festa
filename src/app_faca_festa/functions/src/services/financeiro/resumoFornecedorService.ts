export type VendaFato = {
  id: string;
  id_evento: string;
  valor_contratado: number;
  recebido_confirmado?: number;
  liquido_previsto?: number;
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
  creditoExcedente:number;
  saldoContrato:number;
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
  receitaRealizadaLiquidaDeComissao?: boolean;
  comissao?: number | null;
  taxas?: number | null;
  tributos?: number | null;
  idEvento?: string | null;
}): ResumoFornecedor {
  const filtro = entrada.idEvento ?? null;
  let contratado = 0;
  let recebido = 0;
  let aReceber = 0, creditoExcedente=0, saldoContrato=0;
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
    const saldo=(Math.round((v.liquido_previsto ?? v.valor_contratado)*100)-Math.round(rec*100))/100;
    saldoContrato+=saldo;
    if(saldo<0) creditoExcedente-=saldo; else aReceber+=saldo;
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
  const resultadoRealizado = receitaRealizada - custoRealizado - deducoes + (entrada.receitaRealizadaLiquidaDeComissao ? (entrada.comissao || 0) : 0);
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
    aReceber, creditoExcedente, saldoContrato,
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

/** Uma entrada por fato. O espelho não é outra receita/entrada de caixa. */
export function projetarCaixaRecebimentos(
  fatos: Array<{id:string;data:Record<string, any>}>,
  movimentos: Array<{id:string;data:Record<string, any>}>,
  aliases: Map<string,string> | undefined = undefined, idEvento?: string | null,
) {
  const porContrato = new Map<string,number>();
  const recebimentos = new Map<string,{centavos:number;entrada:boolean;evento:string}>();
  const identidades=new Set<string>(), repassesLegados=new Set<string>();
  let repasseLegadoNaoConciliado=0, movimentoLegadoNaoConciliado=0;
  let entradas = 0, saidas = 0, naoAlocado = 0, adiantamentos = 0;
  const centavos = (v:unknown) => {
    if (typeof v !== 'number' || !Number.isSafeInteger(v) || v<0) throw new Error('Valor de caixa inválido ou indisponível.');
    return v;
  };
  for (const f of fatos) {
    const d = f.data;
    if (idEvento && d.id_evento !== idEvento) continue;
    const identidade=String(d.id_operacao || d.chave_idempotencia || f.id);
    if(['repasse','repasse_plataforma'].includes(d.tipo) || d.origem === 'repasse_plataforma') { repassesLegados.add(f.id);repassesLegados.add(identidade);repasseLegadoNaoConciliado+=centavos(d.valor?.centavos);continue; }
    if(identidades.has(identidade)) throw new Error('Recebimentos legados repetem a mesma identidade; confira os fatos.');
    identidades.add(identidade);
    const c = centavos(d.valor?.centavos), entrada = d.tipo !== 'estorno', sinal = entrada ? 1 : -1;
    recebimentos.set(f.id,{centavos:c,entrada,evento:d.id_evento});
    if (entrada) entradas += c; else saidas += c;
    let alocado = 0;
    const alocacoes = Array.isArray(d.alocacoes) ? d.alocacoes : (d.id_contrato || d.id_orcamento) ? [{id_contrato:d.id_contrato || d.id_orcamento,centavos:c}] : [];
    for (const a of alocacoes) {
      const valor = centavos(a.centavos);
      const id = aliases ? aliases.get(a.id_contrato) : a.id_contrato;
      if (!id) continue;
      porContrato.set(id,(porContrato.get(id) || 0)+sinal*valor);
      alocado += valor;
    }
    if (alocado>c) throw new Error('Alocações superiores ao fato de recebimento.');
    naoAlocado += sinal*(c-alocado);
    if (d.adiantamento || d.tipo === 'adiantamento') adiantamentos += sinal*c;
    if (!entrada && d.referencia_recebimento) {
      const original = fatos.find(f=>f.id===d.referencia_recebimento)?.data;
      if (original?.adiantamento || original?.tipo==='adiantamento') adiantamentos -= c;
    }
  }
  const vistos = new Set<string>();
  for (const m of movimentos) {
    const d = m.data;
    if (idEvento && d.id_evento !== idEvento) continue;
    const referencia = String(d.id_recebimento_origem || d.chave_idempotencia || m.id);
    if(repassesLegados.has(referencia) || d.origem === 'repasse_plataforma') continue;
    const idFato=fatos.find(f=>String(f.data.id_operacao || f.data.chave_idempotencia || f.id)===referencia)?.id;
    const fato = recebimentos.get(referencia) || (idFato ? recebimentos.get(idFato) : undefined);
    if (fato) {
      if (centavos(d.valor?.centavos)!==fato.centavos || (d.entrada===true)!==fato.entrada || d.id_evento!==fato.evento) throw new Error('Fato e espelho de caixa divergem; confira os documentos preservados.');
      continue;
    }
    if (d.id_recebimento_origem || d.schema === 2) throw new Error('Espelho sem recebimento de origem.');
    if(['recebimento','adiantamento','recebimento_proprio_declarado','estorno_recebimento'].includes(d.origem)) {movimentoLegadoNaoConciliado+=centavos(d.valor?.centavos);continue;}
    if (d.origem === 'repasse_plataforma') continue; // Origem canônica é plataforma_repasses.
    const chave = String(d.id_operacao || d.chave_idempotencia || m.id);
    if (vistos.has(chave)) throw new Error('Movimentos legados repetem a identidade de caixa.');
    vistos.add(chave);
    if (d.entrada === true) entradas += centavos(d.valor?.centavos); else saidas += centavos(d.valor?.centavos);
  }
  return {porContrato,entradasCentavos:entradas,saidasCentavos:saidas,
    proprioLiquidoCentavos:[...recebimentos.values()].reduce((s,f)=>s+(f.entrada?1:-1)*f.centavos,0),
    naoAlocadoCentavos:naoAlocado,adiantamentosCentavos:adiantamentos,repasseLegadoNaoConciliadoCentavos:repasseLegadoNaoConciliado,movimentoLegadoNaoConciliadoCentavos:movimentoLegadoNaoConciliado};
}
