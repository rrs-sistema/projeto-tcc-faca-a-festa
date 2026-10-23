const assert = require("assert");
const path = require("path");
const {
  orcamentoLivreAntesDespesas,
  simularOrcamento,
  tetoCompartilhadoParaFornecedor,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/simulacaoOrcamentoService.js",
));
const {
  precoPorMargemSobreVenda,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/precificacaoFornecedorService.js",
));

(function livres5k() {
  assert.strictEqual(orcamentoLivreAntesDespesas(2_000_000, 1_500_000), 500_000);
  const r = simularOrcamento({
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
  assert.strictEqual(r.orcamentoLivreAntesDespesasCentavos, 500_000);
  assert.strictEqual(r.alteraFinanceiro, false);
  console.log("✓ 20k−15k = 5k livres; simulação sem efeito financeiro");
})();

(function alternativasNaoSomadas() {
  const r = simularOrcamento({
    limiteCentavos: 5_000_000,
    compromissos: [],
    necessidades: [{ id: "som", descricao: "Som" }],
    alternativasPorNecessidade: {
      som: [
        {
          id: "a1",
          idNecessidade: "som",
          rotulo: "Barato",
          precoCentavos: 100_000,
        },
        {
          id: "a2",
          idNecessidade: "som",
          rotulo: "Caro",
          precoCentavos: 300_000,
        },
      ],
    },
  });
  const eco = r.cenarios.find((c) => c.tipo === "economico");
  assert.strictEqual(eco.previsaoCentavos, 100_000);
  assert.notStrictEqual(eco.previsaoCentavos, 400_000);
  console.log("✓ alternativas não somadas");
})();

(function preco1000() {
  const p = precoPorMargemSobreVenda(70_000, 0.2, 0.1);
  assert.strictEqual(p.precoCentavos, 100_000);
  assert.throws(
    () => precoPorMargemSobreVenda(70_000, 0.8, 0.3),
    (e) => e.code === "failed-precondition",
  );
  console.log("✓ 700 / (1−0,2−0,1) = 1000");
})();

(function parcial() {
  const r = simularOrcamento({
    limiteCentavos: 1_000_000,
    compromissos: [],
    necessidades: [{ id: "luz", descricao: "Luz" }],
    alternativasPorNecessidade: {
      luz: [
        {
          id: "x",
          idNecessidade: "luz",
          rotulo: "Inválida",
          precoCentavos: 50_000,
          historicoValido: false,
        },
      ],
    },
  });
  assert.strictEqual(r.completo, false);
  console.log("✓ histórico incompatível → parcial");
})();

(function tetoAuth() {
  assert.strictEqual(
    tetoCompartilhadoParaFornecedor({
      idFornecedor: "f1",
      idNecessidade: "n",
      tetoCentavos: null,
      compartilhadoExplicitamente: false,
      solicitanteUid: "f1",
      idFornecedorSolicitante: "f1",
    }),
    null,
  );
  assert.throws(
    () =>
      tetoCompartilhadoParaFornecedor({
        idFornecedor: "f2",
        idNecessidade: "n",
        tetoCentavos: 100,
        compartilhadoExplicitamente: true,
        solicitanteUid: "f1",
        idFornecedorSolicitante: "f1",
      }),
    (e) => e.code === "permission-denied",
  );
  console.log("✓ teto: sem compartilhamento / sem acesso cruzado");
})();

console.log("Simulação orçamento: ok");
