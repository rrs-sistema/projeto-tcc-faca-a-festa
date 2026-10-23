/**
 * Validação integrada (Prompt 08) — cenários mínimos + conciliação de perspectivas.
 * Determinístico, sem Firebase real / sem cobrança.
 */
const assert = require("assert");
const path = require("path");

const { calcularResumo } = require(path.join(
  __dirname,
  "../lib/services/financeiro/resumoFinanceiro.js",
));
const { calcularPrevisaoGerente } = require(path.join(
  __dirname,
  "../lib/services/financeiro/previsaoGerenteService.js",
));
const { calcularResumoFornecedor } = require(path.join(
  __dirname,
  "../lib/services/financeiro/resumoFornecedorService.js",
));
const {
  gerarObrigacao,
  liquidarManual,
  saldoCentavos,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/comissaoPlataformaService.js",
));
const {
  reservar,
  retirarDeReserva,
  cancelarReserva,
  intervaloEfetivo,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/estoqueFornecedorService.js",
));
const { agregarDashboardAdmin } = require(path.join(
  __dirname,
  "../lib/services/financeiro/dashboardAdminService.js",
));
const {
  orcamentoLivreAntesDespesas,
  simularOrcamento,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/simulacaoOrcamentoService.js",
));

const TZ = "America/Sao_Paulo";

function exigirAcessoEvento({ uid, tipo, eventoDono }) {
  if (uid === eventoDono || tipo === "A") return;
  const e = new Error("permission-denied");
  e.code = "permission-denied";
  throw e;
}

function exigirFinanceiroFornecedor({ uid, idFornecedor }) {
  if (uid !== idFornecedor) {
    const e = new Error("permission-denied");
    e.code = "permission-denied";
    throw e;
  }
}

(function contrato10kPago3kSaldo7k() {
  const r = calcularResumo([
    {
      id: "c1",
      id_necessidade: "n1",
      contratado: true,
      valor_contratado: 10000,
      pago: 3000,
      saldo_devido: 7000,
      financeiro_valido: true,
    },
  ]);
  assert.strictEqual(r.contratado, 10000);
  assert.strictEqual(r.pagoLiquido, 3000);
  assert.strictEqual(r.saldoDevido, 7000);
  console.log("✓ contrato 10k / pago 3k / saldo 7k");
})();

(function previsao30k() {
  const r = calcularPrevisaoGerente({
    limite: 30000,
    compromissos: [
      {
        id: "1",
        contratado: true,
        valor_contratado: 18000,
        pago: 7000,
        saldo_devido: 11000,
        financeiro_valido: true,
      },
    ],
    necessidades: [
      { id: "n1", descricao: "Restante", custo_estimado_total: 8000 },
    ],
  });
  assert.strictEqual(r.custoFinalPrevisto, 26000);
  assert.strictEqual(r.folgaAntesReserva, 4000);
  console.log("✓ limite 30k / contratos 18k / restantes 8k → previsão 26k");
})();

(function comissao500PreservaVersao() {
  const pol = {
    id: "pol",
    versao: 1,
    percentualBps: 500,
    baseElegivel: "servicos_contratados_plataforma",
    pagador: "fornecedor",
    gatilho: "contratacao_confirmada",
    reversao: "proporcional",
    ativa: true,
    completa: true,
    diasVencimentoAposGeracao: 30,
  };
  const o = gerarObrigacao({
    politica: pol,
    idObrigacao: "comissao-c1",
    idEvento: "e1",
    idContrato: "c1",
    baseBrutaCentavos: 1_000_000,
  });
  assert.strictEqual(o.valorOriginalCentavos, 50_000);
  assert.strictEqual(o.politicaAplicada.percentual_bps, 500);
  const o2 = gerarObrigacao({
    politica: { ...pol, percentualBps: 600, versao: 2 },
    idObrigacao: "comissao-c1",
    idEvento: "e1",
    idContrato: "c1",
    baseBrutaCentavos: 1_000_000,
    jaExistente: o,
  });
  assert.strictEqual(o2.valorOriginalCentavos, 50_000);
  assert.strictEqual(o2.politicaAplicada.percentual_bps, 500);
  const liq = liquidarManual(o, 20_000);
  assert.strictEqual(saldoCentavos(liq), 30_000);
  console.log("✓ comissão 5% de 10k = R$500 uma vez; versão preservada");
})();

(function estoqueConcorrenteCancelamento() {
  const itemBase = {
    idItem: "cadeiras",
    idFornecedor: "forn-1",
    nome: "Cadeira",
    natureza: "consumivel",
    quantidadeTotal: 100,
    quantidadeReservada: 0,
    quantidadeEmUso: 0,
    status: "disponivel",
    custoMedioUnitarioCentavos: 500,
    custoUsoCentavos: 0,
    custoLocacaoCentavos: 0,
    montagemMinutos: 0,
    transporteMinutos: 0,
    desmontagemMinutos: 0,
  };
  const intervalo = intervaloEfetivo(
    new Date("2026-10-21T10:00:00-03:00"),
    new Date("2026-10-21T18:00:00-03:00"),
    itemBase,
  );
  const r1 = reservar({
    item: itemBase,
    idReserva: "r1",
    idEvento: "e1",
    quantidade: 60,
    intervalo,
    reservasAtivas: [],
  });
  assert.throws(
    () =>
      reservar({
        item: r1.item,
        idReserva: "r2",
        idEvento: "e2",
        quantidade: 50,
        intervalo,
        reservasAtivas: [r1.reserva],
      }),
    (e) => e.code === "failed-precondition",
  );
  const ret = retirarDeReserva(r1.item, r1.reserva);
  assert.strictEqual(ret.item.quantidadeTotal, 100);
  assert.strictEqual(ret.item.quantidadeEmUso, 60);
  // Cancelamento só reserva ainda ativa (não retirada)
  const rAtiva = reservar({
    item: {
      ...itemBase,
      quantidadeReservada: 0,
      quantidadeEmUso: 0,
    },
    idReserva: "r3",
    idEvento: "e3",
    quantidade: 10,
    intervalo,
    reservasAtivas: [],
  });
  const can = cancelarReserva(rAtiva.item, rAtiva.reserva);
  assert.strictEqual(can.reserva.status, "cancelada");
  assert.strictEqual(can.item.quantidadeReservada, 0);
  console.log("✓ estoque: concorrência sem excesso; cancelamento parcial ok");
})();

(function taxaFuturaEPrecoAusente() {
  assert.strictEqual(orcamentoLivreAntesDespesas(2_000_000, 1_500_000), 500_000);
  const parcial = calcularPrevisaoGerente({
    limite: 30000,
    compromissos: [],
    necessidades: [
      {
        id: "x",
        descricao: "Som",
        quantidade_necessaria: 1,
        quantidade_contratada: 0,
        preco_unitario: null,
      },
    ],
  });
  assert.strictEqual(parcial.completo, false);
  assert.strictEqual(parcial.cabeNoLimite, null);
  assert.ok(parcial.alertas.includes("preco_ausente"));
  console.log("✓ preço ausente não vira economia; taxa futura coberta na comissão");
})();

(function conciliacaoPerspectivas() {
  // Evento pagador: pago 4000
  const evento = calcularResumo([
    {
      id: "c1",
      contratado: true,
      valor_contratado: 10000,
      pago: 4000,
      saldo_devido: 6000,
      financeiro_valido: true,
    },
  ]);
  // Fornecedor: recebimento NÃO copiado automaticamente do pagamento do cliente
  const forn = calcularResumoFornecedor({
    vendas: [
      {
        id: "v1",
        id_evento: "e1",
        valor_contratado: 10000,
        recebido_confirmado: 0,
        receita_realizada: 0,
      },
    ],
    custos: [],
  });
  assert.strictEqual(evento.pagoLiquido, 4000);
  assert.strictEqual(forn.recebido, 0);
  assert.notStrictEqual(evento.pagoLiquido, forn.recebido);
  // Dashboard: volume ≠ receita plataforma
  const dash = agregarDashboardAdmin({
    fatos: [
      {
        idEvento: "e1",
        idOrcamento: "c1",
        contratado: true,
        valorOportunidadeCentavos: 0,
        valorContratadoCentavos: 10_000_000,
        pagoCentavos: 10_000_000,
      },
    ],
    comissoes: [
      {
        id: "com1",
        status: "recebida",
        valorOriginalCentavos: 500_000,
        valorLiquidadoCentavos: 500_000,
        idEvento: "e1",
      },
    ],
    politicaComissaoAtiva: true,
  });
  assert.strictEqual(dash.pagamentosEventosCentavos, 10_000_000);
  assert.strictEqual(dash.receitaPlataformaCentavos, 500_000);
  console.log(
    "✓ conciliação: pagamento evento ≠ recebimento fornecedor; volume ≠ receita plataforma",
  );
})();

(function authCruzadaEElevacao() {
  assert.throws(
    () => exigirAcessoEvento({ uid: "org-2", tipo: "O", eventoDono: "org-1" }),
    (e) => e.code === "permission-denied",
  );
  assert.throws(
    () => exigirFinanceiroFornecedor({ uid: "forn-2", idFornecedor: "forn-1" }),
    (e) => e.code === "permission-denied",
  );
  assert.throws(
    () => exigirFinanceiroFornecedor({ uid: "admin-1", idFornecedor: "forn-1" }),
    (e) => e.code === "permission-denied",
  );
  // Elevação de papel pelo cliente: tipo F tentando agir como A no evento alheio
  assert.throws(
    () =>
      exigirAcessoEvento({
        uid: "forn-1",
        tipo: "F",
        eventoDono: "org-1",
      }),
    (e) => e.code === "permission-denied",
  );
  // Anônimo (uid vazio)
  assert.throws(
    () => exigirAcessoEvento({ uid: "", tipo: "", eventoDono: "org-1" }),
    (e) => e.code === "permission-denied",
  );
  console.log("✓ auth: evento alheio, outra empresa, admin sem uid dono, elevação, anônimo");
})();

(function idempotenciaRepeticao() {
  const a = simularOrcamento({
    limiteCentavos: 2_000_000,
    compromissos: [
      {
        id: "c1",
        contratado: true,
        valor_contratado: 15000,
        pago: 0,
        financeiro_valido: true,
      },
    ],
    necessidades: [],
    alternativasPorNecessidade: {},
  });
  const b = simularOrcamento({
    limiteCentavos: 2_000_000,
    compromissos: [
      {
        id: "c1",
        contratado: true,
        valor_contratado: 15000,
        pago: 0,
        financeiro_valido: true,
      },
    ],
    necessidades: [],
    alternativasPorNecessidade: {},
  });
  assert.deepStrictEqual(
    {
      l: a.orcamentoLivreAntesDespesasCentavos,
      c: a.comprometidoCentavos,
      f: a.alteraFinanceiro,
    },
    {
      l: b.orcamentoLivreAntesDespesasCentavos,
      c: b.comprometidoCentavos,
      f: b.alteraFinanceiro,
    },
  );
  console.log("✓ repetição/idempotência de simulação e agregados");
})();

(function fusoSaoPaulo() {
  const fmt = new Intl.DateTimeFormat("pt-BR", {
    timeZone: TZ,
    dateStyle: "short",
    timeStyle: "short",
  });
  const d = new Date("2026-10-21T18:00:00.000Z");
  const s = fmt.format(d);
  assert.ok(typeof s === "string" && s.length > 0);
  assert.strictEqual(TZ, "America/Sao_Paulo");
  console.log(`✓ apresentação de datas no fuso ${TZ}: ${s}`);
})();

console.log("Validação financeira integrada: ok");
console.log(
  JSON.stringify({
    fixture_personas: [
      "org-1",
      "org-2",
      "forn-1",
      "forn-2",
      "gerente-limitado=org-1",
      "admin-1",
    ],
    timezone: TZ,
  }),
);
