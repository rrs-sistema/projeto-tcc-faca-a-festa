const assert = require("assert");
const path = require("path");
const {
  cenarioAnaDebora,
  acessoCruzadoNegado,
  conciliarMovimentosSemDuplicar,
  transicionarExecucao,
  podeRegistrarAceiteOuContestacao,
  rotulosAcaoPermitidos,
  acaoExibidaEhSegura,
  CTAS_INTEGRACAO_AUSENTE,
  montarVisaoFornecedor,
  montarVisaoOrganizador,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/acompanhamentoPartesService.js",
));

(function anaDeclara4kAntesConferencia() {
  const c = cenarioAnaDebora({
    valorContratoCentavos: 1_000_000,
    declaradoCentavos: 400_000,
    confirmadoAlocadoCentavos: 0,
    percentualBps: 500,
    repasseConfirmadoCentavos: 0,
    politicaLiberacaoAtiva: false,
  });
  assert.strictEqual(c.antesConferencia.nivel, "declarado");
  assert.strictEqual(c.antesConferencia.adminVePendenciaConferencia, true);
  assert.strictEqual(c.antesConferencia.fornecedorCaixaProprioCentavos, 0);
  console.log("✓ Ana declara 4k: admin vê pendência; fornecedor sem entrada automática");
})();

(function aposConfirmacaoSaldo6k() {
  const c = cenarioAnaDebora({
    valorContratoCentavos: 1_000_000,
    declaradoCentavos: 400_000,
    confirmadoAlocadoCentavos: 400_000,
    percentualBps: 500,
    repasseConfirmadoCentavos: 0,
    politicaLiberacaoAtiva: false,
  });
  assert.strictEqual(c.aposConfirmacao.aPagarClienteCentavos, 600_000);
  assert.strictEqual(c.aposConfirmacao.fornecedorVeAlocadoComoCaixa, false);
  console.log("✓ após confirmação: cliente saldo 6k; fornecedor não trata como caixa");
})();

(function comissao5eRepasseParcial() {
  const c = cenarioAnaDebora({
    valorContratoCentavos: 1_000_000,
    declaradoCentavos: 400_000,
    confirmadoAlocadoCentavos: 400_000,
    percentualBps: 500,
    repasseConfirmadoCentavos: 300_000,
    politicaLiberacaoAtiva: true,
  });
  assert.strictEqual(c.aposConfirmacao.direitoLiquidoCentavos, 950_000);
  assert.strictEqual(c.aposConfirmacao.saldoPrevistoRepasseCentavos, 650_000);
  const forn = montarVisaoFornecedor({
    idContrato: "c",
    idOrcamento: "o",
    idEvento: "e",
    nomeEvento: "Festa",
    dataEvento: null,
    nomeContratante: "Ana",
    nomeServico: "Decor",
    escopo: null,
    valorContratadoCentavos: 1_000_000,
    percentualBps: 500,
    modoComissao: "descontada_fornecedor",
    alocadoPlataformaCentavos: 400_000,
    repasseAutorizadoCentavos: 0,
    repasseConfirmadoCentavos: 300_000,
    politicaLiberacaoAtiva: true,
    estadoExecucao: "nao_iniciado",
  });
  assert.strictEqual(forn.comissaoJaDescontadaDoRepasse, true);
  assert.ok(forn.parcelaNaoFinanciadaOuNaoElegivelCentavos > 0);
  console.log("✓ 5% desconto → 9.500; repasse 3k → saldo previsto 6.500");
})();

(function acessoCruzado() {
  const a = acessoCruzadoNegado({
    idFornecedorContrato: "debora",
    idFornecedorConsulta: "outro-buffet",
    idContratanteContrato: "ana",
    idClienteConsulta: "outra-cliente",
  });
  assert.strictEqual(a.fornecedorEstranho, true);
  assert.strictEqual(a.clienteEstranho, true);
  console.log("✓ outro fornecedor/cliente não acessa o contrato");
})();

(function idempotenciaEContestacao() {
  const t1 = transicionarExecucao({
    atual: "em_execucao",
    acao: "informar_entrega",
  });
  assert.strictEqual(t1.novo, "entrega_informada");
  const dup = podeRegistrarAceiteOuContestacao("nao_iniciado", "aceitar");
  assert.strictEqual(dup.ok, false);
  const cont = transicionarExecucao({
    atual: "entrega_informada",
    acao: "contestar",
  });
  assert.strictEqual(cont.novo, "contestado");
  assert.strictEqual(cont.preservaHistorico, true);
  // Contestação não gera efeito financeiro no domínio.
  console.log("✓ entrega/aceite distintos; contestação preserva histórico sem reembolso");
})();

(function movimentosSemDuplicarECtas() {
  const m = conciliarMovimentosSemDuplicar([
    { id: "r1", origem: "pagamento_cliente_plataforma", valorCentavos: 400_000, idContrato: "c" },
    { id: "r1", origem: "pagamento_cliente_plataforma", valorCentavos: 400_000, idContrato: "c" },
    { id: "p1", origem: "repasse_plataforma", valorCentavos: 300_000, idContrato: "c" },
    { id: "x1", origem: "recebimento_proprio_fornecedor", valorCentavos: 50_000, idContrato: null },
  ]);
  assert.strictEqual(m.totalPagamentoClientePlataformaCentavos, 400_000);
  assert.strictEqual(m.totalRepassePlataformaCentavos, 300_000);
  assert.strictEqual(m.totalRecebimentoProprioCentavos, 50_000);
  assert.strictEqual(m.ids.length, 3);

  const acoes = rotulosAcaoPermitidos({
    temGatewayPagamento: false,
    temSaque: false,
    temGarantia: false,
  });
  for (const proibido of CTAS_INTEGRACAO_AUSENTE) {
    assert.strictEqual(acaoExibidaEhSegura(proibido, acoes), false);
  }
  console.log("✓ IDs únicos conciliam; CTAs Pagar agora/Sacar bloqueados sem integração");
})();

(function organizadorNiveis() {
  const v = montarVisaoOrganizador({
    idContrato: "c",
    idOrcamento: "o",
    idEvento: "e",
    nomeEvento: "Festa Ana",
    nomeFornecedor: "Débora Festas",
    nomeServico: "Decoração",
    escopo: "salão",
    valorContratadoCentavos: 1_000_000,
    declaradoCentavos: 400_000,
    confirmadoAlocadoCentavos: 0,
    estadoRepasse: "sem_repasse",
    estadoExecucao: "nao_iniciado",
    parcelasConhecidas: true,
    politicaLiberacaoAtiva: false,
  });
  assert.strictEqual(v.nivelPagamentoPlataforma, "declarado");
  assert.strictEqual(v.aPagarPlataformaCentavos, 1_000_000);
  assert.strictEqual(v.nomeFornecedor, "Débora Festas");
  assert.ok(v.proximoPasso.rotulo.length > 0);
  console.log("✓ organizador: declaração ≠ confirmação; próximo passo útil");
})();

console.log("✓ acompanhamentoPartes: todos os aceites (cenário Ana/Débora)");
