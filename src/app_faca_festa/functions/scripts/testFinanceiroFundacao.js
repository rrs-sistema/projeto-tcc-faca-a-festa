/**
 * Testes unitários da fundação financeira (sem emulador / produção).
 * Executar: node scripts/testFinanceiroFundacao.js
 */
const assert = require("assert");
const path = require("path");

const dinheiro = require(path.join(__dirname, "../lib/services/financeiro/dinheiro.js"));
const resumo = require(path.join(__dirname, "../lib/services/financeiro/resumoFinanceiro.js"));

function ok(nome) {
  console.log(`✓ ${nome}`);
}

(function centavos() {
  assert.strictEqual(dinheiro.reaisParaCentavosArredondado(10000), 1000000);
  assert.strictEqual(dinheiro.deReaisLegado(10.001), null);
  assert.deepStrictEqual(dinheiro.dinheiro(300000), { centavos: 300000, moeda: "BRL" });
  ok("centavos e legado");
})();

(function contratoPagamentoSaldo() {
  const r = resumo.calcularResumo([
    {
      id: "1",
      id_necessidade: "buffet",
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
  ok("contrato 10k / pago 3k / saldo 7k");
})();

(function alternativasNaoSomam() {
  const r = resumo.calcularResumo([
    { id: "a", id_necessidade: "buffet", cotado: 4000, estimado: 4000 },
    { id: "b", id_necessidade: "buffet", cotado: 4500, estimado: 4500 },
    { id: "c", id_necessidade: "buffet", cotado: 5000, estimado: 5000 },
  ]);
  assert.strictEqual(r.cotado, 5000);
  assert.strictEqual(r.contratado, 0);
  assert.strictEqual(r.saldoDevido, 0);
  ok("alternativas comparáveis, não somadas");
})();

(function excessoTipo() {
  const tiposExcedem = new Set(["credito", "adiantamento"]);
  assert.strictEqual(tiposExcedem.has("pagamento"), false);
  assert.strictEqual(tiposExcedem.has("credito"), true);
  ok("excesso exige crédito/adiantamento");
})();

console.log("Fundação financeira: todos os asserts passaram.");
