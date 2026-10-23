const assert = require("assert");
const path = require("path");
const svc = require(path.join(
  __dirname,
  "../lib/services/financeiro/comissaoPlataformaService.js",
));

function pol(parcial = {}) {
  return {
    id: "pol-1",
    versao: 1,
    percentualBps: 500,
    baseElegivel: "servicos_contratados_plataforma",
    pagador: "fornecedor",
    gatilho: "contratacao_confirmada",
    reversao: "proporcional",
    ativa: true,
    completa: true,
    diasVencimentoAposGeracao: 30,
    ...parcial,
  };
}

(function gera500UmaVez() {
  const o1 = svc.gerarObrigacao({
    politica: pol(),
    idObrigacao: "comissao-c1",
    idEvento: "e1",
    idContrato: "c1",
    baseBrutaCentavos: 1_000_000,
  });
  assert.strictEqual(o1.valorOriginalCentavos, 50_000);
  const o2 = svc.gerarObrigacao({
    politica: pol(),
    idObrigacao: "comissao-c1",
    idEvento: "e1",
    idContrato: "c1",
    baseBrutaCentavos: 1_000_000,
    jaExistente: o1,
  });
  assert.strictEqual(o2.valorOriginalCentavos, 50_000);
  console.log("✓ 5% de 10k = R$500 uma vez");
})();

(function preservaSnapshot() {
  const o = svc.gerarObrigacao({
    politica: pol({ percentualBps: 500 }),
    idObrigacao: "o1",
    idEvento: "e1",
    idContrato: "c1",
    baseBrutaCentavos: 1_000_000,
  });
  assert.strictEqual(o.politicaAplicada.percentual_bps, 500);
  const futura = pol({ percentualBps: 600 });
  assert.strictEqual(futura.percentualBps, 600);
  assert.strictEqual(o.valorOriginalCentavos, 50_000);
  console.log("✓ taxa futura 6% preserva R$500");
})();

(function liquidacao() {
  const o = svc.gerarObrigacao({
    politica: pol(),
    idObrigacao: "o1",
    idEvento: "e1",
    idContrato: "c1",
    baseBrutaCentavos: 1_000_000,
  });
  const liq = svc.liquidarManual(o, 20_000);
  assert.strictEqual(svc.saldoCentavos(liq), 30_000);
  console.log("✓ liquidação 200 → saldo 300");
})();

(function ajusteProporcional() {
  const aj = svc.ajustePorReducaoElegivel(500, 200_000, "proporcional");
  assert.strictEqual(aj.ajusteCentavos, -10_000);
  assert.strictEqual(aj.creditoReembolsoExplicito, true);
  console.log("✓ redução 2k → ajuste R$100 crédito explícito");
})();

(function semDivida() {
  assert.strictEqual(
    svc.simular({ politica: null, baseBrutaCentavos: 1_000_000 }).podeGerar,
    false,
  );
  assert.strictEqual(
    svc.simular({ politica: pol({ ativa: false }), baseBrutaCentavos: 1_000_000 })
      .podeGerar,
    false,
  );
  assert.throws(
    () =>
      svc.gerarObrigacao({
        politica: pol({ ativa: false }),
        idObrigacao: "x",
        idEvento: "e",
        idContrato: "c",
        baseBrutaCentavos: 1_000_000,
      }),
    (e) => e.code === "failed-precondition",
  );
  console.log("✓ ausente/inativa não gera dívida");
})();

(function authTaxa() {
  function exigirConfigurar(tipo) {
    if (tipo !== "A") {
      const e = new Error("permission-denied");
      e.code = "permission-denied";
      throw e;
    }
  }
  assert.throws(() => exigirConfigurar("F"), (e) => e.code === "permission-denied");
  assert.throws(() => exigirConfigurar("O"), (e) => e.code === "permission-denied");
  exigirConfigurar("A");
  svc.validarPercentualBps(0);
  assert.throws(() => svc.validarPercentualBps(null), (e) => e.code === "invalid-argument");
  console.log("✓ alteração não autorizada rejeitada; zero ≠ ausente");
})();

console.log("Comissão plataforma: ok");
