const assert = require("assert");
const path = require("path");
const {
  calcularPrevisaoGerente,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/previsaoGerenteService.js",
));

(function casoAceite() {
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
  assert.strictEqual(r.contratado, 18000);
  assert.strictEqual(r.pagoLiquido, 7000);
  assert.strictEqual(r.saldoContratado, 11000);
  assert.strictEqual(r.faltaContratar, 8000);
  assert.strictEqual(r.custoFinalPrevisto, 26000);
  assert.strictEqual(r.folgaAntesReserva, 4000);
  assert.strictEqual(r.cabeNoLimite, true);
  console.log("✓ previsão gerente 30k/18k/7k/8k");
})();

(function parcialSemPreco() {
  const r = calcularPrevisaoGerente({
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
  assert.strictEqual(r.completo, false);
  assert.strictEqual(r.cabeNoLimite, null);
  assert.ok(r.alertas.includes("preco_ausente"));
  console.log("✓ preço ausente → projeção parcial");
})();

(function coberturaParcial() {
  const r = calcularPrevisaoGerente({
    limite: 10000,
    compromissos: [],
    necessidades: [
      {
        id: "b",
        descricao: "Bebida",
        quantidade_necessaria: 100,
        quantidade_contratada: 60,
        preco_unitario: 10,
      },
    ],
  });
  assert.strictEqual(r.faltaContratar, 400);
  console.log("✓ 100-60 = 40 restantes");
})();

(function buffetNaoDuplica() {
  const r = calcularPrevisaoGerente({
    limite: 10000,
    compromissos: [
      {
        id: "buffet",
        contratado: true,
        valor_contratado: 6500,
        pago: 0,
        financeiro_valido: true,
      },
    ],
    necessidades: [
      {
        id: "arroz",
        descricao: "Arroz",
        custo_estimado_total: 200,
        coberta_por_buffet: true,
      },
    ],
  });
  assert.strictEqual(r.custoFinalPrevisto, 6500);
  console.log("✓ buffet não duplica compra");
})();

console.log("Previsão gerente: ok");
