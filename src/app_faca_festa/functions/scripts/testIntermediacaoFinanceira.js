const assert = require("assert");
const path = require("path");
const {
  calcularDireitosContrato,
  validarAlocacoesRecebimento,
  tentarAlocarConcurrente,
  avaliarElegibilidadeRepasse,
  transicionarRepasse,
  conciliarCaixaPedido,
  registrarChargebackAposRepasse,
  montarPosicaoContrato,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/intermediacaoFinanceiraService.js",
));

(function contrato10kComissao5Descontada() {
  const d = calcularDireitosContrato({
    valorContratadoCentavos: 1_000_000,
    percentualBps: 500,
    modoComissao: "descontada_fornecedor",
  });
  assert.strictEqual(d.direitoFornecedorPrevistoCentavos, 950_000);
  assert.strictEqual(d.comissaoPrevistaCentavos, 50_000);
  assert.strictEqual(d.precoClienteCentavos, 1_000_000);
  console.log("✓ 10k / 5% descontada → 9.500 fornecedor, sem cobrança duplicada");
})();

(function recebimentoParcialSemPolitica() {
  const pos = montarPosicaoContrato({
    idContrato: "c1",
    valorContratadoCentavos: 1_000_000,
    percentualBps: 500,
    modoComissao: "descontada_fornecedor",
    alocadoCentavos: 400_000,
    repassadoConfirmadoCentavos: 0,
    autorizadoOuProcessandoCentavos: 0,
    recebimentosPedidoCentavos: 400_000,
    alocadoPedidoCentavos: 400_000,
    politica: null,
  });
  assert.strictEqual(pos.aReceberClienteCentavos, 600_000);
  assert.strictEqual(pos.repassadoConfirmadoCentavos, 0);
  assert.strictEqual(pos.elegivelRepasseCentavos, 0);
  assert.strictEqual(pos.politicaLiberacaoAtiva, false);
  console.log("✓ parcial 4k sem política: cliente 6k; fornecedor não recebeu; sem liberação auto");
})();

(function politicaSinteticaTeto3k() {
  const eleg = avaliarElegibilidadeRepasse({
    direitoFornecedorPrevistoCentavos: 950_000,
    alocadoAoContratoCentavos: 400_000,
    jaRepassadoCentavos: 0,
    jaAutorizadoOuProcessandoCentavos: 0,
    politica: {
      id: "p",
      versao: 1,
      ativa: true,
      permiteRepasseParcial: true,
      tetoParcialCentavos: 300_000,
    },
  });
  assert.strictEqual(eleg.elegivelCentavos, 300_000);
  const conf = transicionarRepasse({
    estadoAtual: "autorizado",
    acao: "confirmar_manual",
  });
  assert.strictEqual(conf.estado, "confirmado");
  assert.strictEqual(conf.confirmacaoManual, true);
  const caixa = conciliarCaixaPedido({
    recebimentosConfirmadosCentavos: 400_000,
    alocadoTotalCentavos: 400_000,
    repassadoConfirmadoCentavos: 300_000,
    remuneracaoAppSeparadaCentavos: 50_000,
  });
  assert.strictEqual(caixa.residualAposRepasseCentavos, 100_000);
  assert.strictEqual(caixa.ok, true);
  console.log("✓ teto 3k confirmado; residual 1k com destinação, não receita auto");
})();

(function alocacaoNaoExcede() {
  const r = {
    id: "r1",
    idEvento: "e",
    idPagador: null,
    valorCentavos: 600_000,
    nivelConfirmacao: "conferencia",
    alocadoCentavos: 0,
    referencia: null,
    origem: "manual",
    origemLegadoPago: false,
  };
  const bad = validarAlocacoesRecebimento({
    recebimento: r,
    alocacoesNovas: [
      { idContrato: "A", valorCentavos: 400_000 },
      { idContrato: "B", valorCentavos: 300_000 },
    ],
  });
  assert.strictEqual(bad.ok, false);
  const conc = tentarAlocarConcurrente({
    disponivelCentavos: 600_000,
    pedidoACentavos: 400_000,
    pedidoBCentavos: 300_000,
  });
  assert.strictEqual(conc.aceitoA, true);
  assert.strictEqual(conc.aceitoB, false);
  console.log("✓ 6k não aloca 4k+3k; concorrência preserva limite");
})();

(function autorizarNaoEConfirmadoEFalha() {
  const auth = transicionarRepasse({
    estadoAtual: "previsto",
    acao: "autorizar",
  });
  assert.strictEqual(auth.estado, "autorizado");
  assert.notStrictEqual(auth.estado, "confirmado");
  const falha = transicionarRepasse({
    estadoAtual: "em_processamento",
    acao: "falhar",
  });
  assert.strictEqual(falha.estado, "falhou");
  let bloqueou = false;
  try {
    transicionarRepasse({ estadoAtual: "confirmado", acao: "cancelar" });
  } catch (_) {
    bloqueou = true;
  }
  assert.ok(bloqueou);
  const cb = registrarChargebackAposRepasse({
    valorChargebackCentavos: 200_000,
    repassadoConfirmadoCentavos: 300_000,
  });
  assert.strictEqual(cb.repasseHistoricoPreservadoCentavos, 300_000);
  assert.strictEqual(cb.recuperacaoPendenteCentavos, 200_000);
  console.log("✓ autorizar ≠ confirmado; falha/chargeback não apagam histórico");
})();

console.log("✓ intermediacaoFinanceira: todos os aceites");
