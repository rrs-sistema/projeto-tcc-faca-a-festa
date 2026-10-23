/**
 * Simula a regra de concorrência/idempotência sem tocar produção.
 * Duas liquidações sequenciais no mesmo saldo: a segunda que excede é rejeitada
 * salvo crédito/adiantamento. Repetição com a mesma chave não duplica.
 */
const assert = require("assert");

function aplicar({ saldo, pago, valor, tipo, chave, visto }) {
  if (visto.has(chave)) {
    return { idempotente: true, pago, saldo, rejeitado: false };
  }
  const efeito =
    tipo === "reembolso" || tipo === "estorno"
      ? -valor
      : tipo === "retencao"
        ? 0
        : valor;
  const pagoNovo = pago + efeito;
  const saldoApos = saldo - pagoNovo;
  const permite = tipo === "credito" || tipo === "adiantamento";
  if (efeito > 0 && saldoApos < 0 && !permite) {
    return { idempotente: false, pago, saldo: saldo - pago, rejeitado: true };
  }
  visto.add(chave);
  return {
    idempotente: false,
    pago: Math.max(0, pagoNovo),
    saldo: saldo - Math.max(0, pagoNovo),
    rejeitado: false,
  };
}

const visto = new Set();
const contrato = 10000;
let pago = 0;

const a = aplicar({
  saldo: contrato,
  pago,
  valor: 7000,
  tipo: "pagamento",
  chave: "k1",
  visto,
});
assert.strictEqual(a.rejeitado, false);
pago = a.pago;

const repetido = aplicar({
  saldo: contrato,
  pago,
  valor: 7000,
  tipo: "pagamento",
  chave: "k1",
  visto,
});
assert.strictEqual(repetido.idempotente, true);
assert.strictEqual(repetido.pago, 7000);

const concorrente = aplicar({
  saldo: contrato,
  pago,
  valor: 4000,
  tipo: "pagamento",
  chave: "k2",
  visto,
});
assert.strictEqual(concorrente.rejeitado, true);

const credito = aplicar({
  saldo: contrato,
  pago,
  valor: 4000,
  tipo: "credito",
  chave: "k3",
  visto,
});
assert.strictEqual(credito.rejeitado, false);

console.log("✓ repetição idempotente e concorrência sem excesso sem crédito");
