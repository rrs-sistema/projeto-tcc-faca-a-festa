const assert = require("assert");
const path = require("path");
const {
  calcularResumoFornecedor,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/resumoFornecedorService.js",
));

(function aReceberIndependente() {
  const r = calcularResumoFornecedor({
    vendas: [
      {
        id: "v1",
        id_evento: "e1",
        valor_contratado: 10000,
        recebido_confirmado: 4000,
      },
    ],
    custos: [{ id: "c1", id_evento: "e1", incorrido: 9999 }],
  });
  assert.strictEqual(r.aReceber, 6000);
  console.log("✓ a receber 6k independente dos custos");
})();

(function custoDireto() {
  const r = calcularResumoFornecedor({
    vendas: [
      { id: "v1", id_evento: "e1", valor_contratado: 10000, recebido_confirmado: 0 },
    ],
    custos: [
      {
        id: "c1",
        id_evento: "e1",
        incorrido: 3000,
        restante_previsto: 2000,
      },
    ],
    comissao: 0,
    taxas: 0,
    tributos: 0,
  });
  assert.strictEqual(r.custoDiretoPrevisto, 5000);
  assert.strictEqual(r.outrasDespesasAusentes, true);
  console.log("✓ custo direto previsto 5k");
})();

(function estoqueSemCaixa() {
  const r = calcularResumoFornecedor({
    vendas: [],
    custos: [
      {
        id: "c1",
        id_evento: "e1",
        incorrido: 1500,
        desembolso_caixa: 0,
        origem: "estoque_consumo",
      },
    ],
  });
  assert.strictEqual(r.custoRealizado, 1500);
  assert.strictEqual(r.saidasCaixa, 0);
  console.log("✓ estoque: custo sem saída de caixa");
})();

(function adiantamento() {
  const r = calcularResumoFornecedor({
    vendas: [
      {
        id: "v1",
        id_evento: "e2",
        valor_contratado: 10000,
        recebido_confirmado: 2000,
        adiantamento_caixa: 2000,
        receita_realizada: 0,
        execucao_confirmada: false,
      },
    ],
    custos: [],
  });
  assert.strictEqual(r.receitaRealizada, 0);
  assert.strictEqual(r.adiantamentosCaixa, 2000);
  assert.strictEqual(r.entradasCaixa, 2000);
  console.log("✓ adiantamento só caixa");
})();

(function authEspelho() {
  function exigir({ uid, idFornecedor }) {
    if (uid !== idFornecedor) {
      const e = new Error("permission-denied");
      e.code = "permission-denied";
      throw e;
    }
  }
  assert.throws(
    () => exigir({ uid: "organizador", idFornecedor: "forn-1" }),
    (e) => e.code === "permission-denied",
  );
  assert.throws(
    () => exigir({ uid: "outro-forn", idFornecedor: "forn-1" }),
    (e) => e.code === "permission-denied",
  );
  assert.throws(
    () => exigir({ uid: "admin-uid", idFornecedor: "forn-1" }),
    (e) => e.code === "permission-denied",
  );
  assert.doesNotThrow(() =>
    exigir({ uid: "forn-1", idFornecedor: "forn-1" }),
  );
  console.log("✓ organizador/outro/admin sem uid dono: negado");
})();

console.log("Financeiro fornecedor: ok");
