const assert = require("assert");
const {
  cpfValido,
  valorCobradoCentavos,
  valorContratadoDoOrcamento,
  vencimentoPix,
  referenciaExterna,
  lerReferenciaExterna,
  referenciaDesteProduto,
  mapearStatusAsaas,
  centavosDeValorAsaas,
  cobrancaConfere,
  reaisDeCentavos,
  confirmadoLimitado,
  entradaSugerida,
  LIMITE_PAGAMENTOS_CONTRATO,
} = require("../lib/services/financeiro/asaasPixRegras");

assert.strictEqual(cpfValido("529.982.247-25"), "52998224725");
assert.strictEqual(cpfValido("11111111111"), null);
assert.strictEqual(cpfValido("123"), null);

assert.deepStrictEqual(valorCobradoCentavos(null, 315000), { ok: true, centavos: 315000 });
assert.deepStrictEqual(valorCobradoCentavos(63000, 315000), { ok: true, centavos: 63000 });
assert.strictEqual(valorCobradoCentavos(315001, 315000).ok, false);
assert.strictEqual(valorCobradoCentavos(null, 0).ok, false);
assert.strictEqual(valorCobradoCentavos(10.5, 100).ok, false);

assert.strictEqual(valorContratadoDoOrcamento({ valor_contratado_centavos: 315000 }), 315000);
assert.strictEqual(valorContratadoDoOrcamento({ valor_contratado: 3150 }), 315000);
assert.strictEqual(valorContratadoDoOrcamento({ valor: 10.5 }), 1050);

const prazo = vencimentoPix(new Date("2026-11-19T15:00:00.000Z"));
assert.strictEqual(prazo.dueDate, "2026-11-19");
const noite = vencimentoPix(new Date("2026-11-19T22:30:00.000Z"));
assert.strictEqual(noite.dueDate, "2026-11-20");

const ref = referenciaExterna("orc1", "cob1");
assert.strictEqual(ref, "FESTA|orc1|cob1");
assert.deepStrictEqual(lerReferenciaExterna(ref), { idOrcamento: "orc1", cobrancaId: "cob1" });
assert.strictEqual(lerReferenciaExterna("CARDAPIO|x|y|z"), null);
assert.strictEqual(referenciaDesteProduto("FESTA|a|b"), true);
assert.strictEqual(referenciaDesteProduto("CARDAPIO|a|b|c"), false);

assert.strictEqual(mapearStatusAsaas("RECEIVED"), "APPROVED");
assert.strictEqual(mapearStatusAsaas("CONFIRMED"), "APPROVED");
assert.strictEqual(mapearStatusAsaas("PENDING"), "PENDING");
assert.strictEqual(mapearStatusAsaas("OVERDUE"), "PENDING");
assert.strictEqual(mapearStatusAsaas("REFUNDED"), "REFUNDED");

assert.strictEqual(centavosDeValorAsaas(3150), 315000);
assert.strictEqual(centavosDeValorAsaas("630.00"), 63000);
assert.strictEqual(reaisDeCentavos(315000), 3150);

assert.deepStrictEqual(cobrancaConfere({
  valorEsperadoCentavos: 315000,
  valorPago: 3150,
  referenciaEsperada: ref,
  referenciaRecebida: ref,
  pagamentoIdEsperado: "pay_1",
  pagamentoIdRecebido: "pay_1",
}), { ok: true });
assert.strictEqual(cobrancaConfere({
  valorEsperadoCentavos: 315000,
  valorPago: 3149.99,
  referenciaEsperada: ref,
  referenciaRecebida: ref,
  pagamentoIdEsperado: "",
  pagamentoIdRecebido: "pay_2",
}).ok, false);
assert.strictEqual(cobrancaConfere({
  valorEsperadoCentavos: 315000,
  valorPago: 3150,
  referenciaEsperada: ref,
  referenciaRecebida: "FESTA|outro|cob1",
  pagamentoIdEsperado: "",
  pagamentoIdRecebido: "pay_2",
}).ok, false);

assert.strictEqual(confirmadoLimitado(315000, 598500), 315000);
assert.strictEqual(confirmadoLimitado(315000, 100000), 100000);
assert.strictEqual(confirmadoLimitado(0, 100), 0);
assert.strictEqual(LIMITE_PAGAMENTOS_CONTRATO, 2);
assert.deepStrictEqual(entradaSugerida("20% de entrada", 315000), {
  percentual: 20,
  centavos: 63000,
});
assert.strictEqual(entradaSugerida("à vista", 315000), null);
assert.strictEqual(entradaSugerida("100% na contratação", 315000), null);
assert.strictEqual(entradaSugerida("0% de entrada", 315000), null);

console.log("✓ regras do Pix Asaas");
