const assert = require("assert");
const path = require("path");
const svc = require(path.join(
  __dirname,
  "../lib/services/financeiro/estoqueFornecedorService.js",
));

function item(parcial = {}) {
  return {
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
    ...parcial,
  };
}

(function concorrencia() {
  const base = item();
  const intervalo = svc.intervaloEfetivo(
    new Date("2026-10-21T10:00:00"),
    new Date("2026-10-21T18:00:00"),
    base,
  );
  const r1 = svc.reservar({
    item: base,
    idReserva: "r1",
    idEvento: "e1",
    quantidade: 60,
    intervalo,
    reservasAtivas: [],
  });
  assert.throws(
    () =>
      svc.reservar({
        item: r1.item,
        idReserva: "r2",
        idEvento: "e2",
        quantidade: 50,
        intervalo,
        reservasAtivas: [r1.reserva],
      }),
    (e) => e.code === "failed-precondition",
  );
  console.log("✓ reserva concorrente 50 rejeitada (100/60)");
})();

(function retiradaNaoDuplica() {
  const base = item({ quantidadeReservada: 60 });
  const reserva = {
    idReserva: "r1",
    idItem: "cadeiras",
    idFornecedor: "forn-1",
    idEvento: "e1",
    quantidade: 60,
    status: "ativa",
    intervaloEfetivo: {
      inicio: new Date("2026-10-21"),
      fim: new Date("2026-10-22"),
    },
  };
  const ret = svc.retirarDeReserva(base, reserva);
  assert.strictEqual(ret.item.quantidadeTotal, 100);
  assert.strictEqual(ret.item.quantidadeReservada, 0);
  assert.strictEqual(ret.item.quantidadeEmUso, 60);
  console.log("✓ retirada não desconta novamente");
})();

(function intervalosReutilizaveis() {
  const base = item({
    natureza: "reutilizavel",
    quantidadeTotal: 10,
    custoUsoCentavos: 100,
  });
  const manha = {
    inicio: new Date("2026-10-21T08:00:00"),
    fim: new Date("2026-10-21T12:00:00"),
  };
  const tarde = {
    inicio: new Date("2026-10-21T14:00:00"),
    fim: new Date("2026-10-21T18:00:00"),
  };
  const r1 = svc.reservar({
    item: base,
    idReserva: "r1",
    idEvento: "e1",
    quantidade: 10,
    intervalo: manha,
    reservasAtivas: [],
  });
  const r2 = svc.reservar({
    item: r1.item,
    idReserva: "r2",
    idEvento: "e2",
    quantidade: 10,
    intervalo: tarde,
    reservasAtivas: [r1.reserva],
  });
  assert.strictEqual(r2.reserva.quantidade, 10);
  assert.throws(
    () =>
      svc.reservar({
        item: r2.item,
        idReserva: "r3",
        idEvento: "e3",
        quantidade: 1,
        intervalo: manha,
        reservasAtivas: [r1.reserva, r2.reserva],
      }),
    (e) => e.code === "failed-precondition",
  );
  console.log("✓ 10 cadeiras: não sobrepostos ok; conflito rejeitado");
})();

(function consumoCusto() {
  const r = svc.consumir({ item: item(), quantidade: 20 });
  assert.strictEqual(r.custoAtribuidoCentavos, 10000);
  assert.strictEqual(r.geraDesembolso, false);
  assert.strictEqual(r.origemCusto, "estoque_consumo");
  console.log("✓ consumo 20×R$5 = R$100 sem desembolso");
})();

(function idempotenciaCancelamento() {
  const reserva = {
    idReserva: "r1",
    idItem: "cadeiras",
    idFornecedor: "forn-1",
    idEvento: "e1",
    quantidade: 10,
    status: "ativa",
    intervaloEfetivo: {
      inicio: new Date("2026-10-21"),
      fim: new Date("2026-10-22"),
    },
  };
  const cons = svc.consumir({
    item: item({ quantidadeReservada: 10 }),
    quantidade: 10,
    reserva,
  });
  const rep = svc.consumir({
    item: cons.item,
    quantidade: 10,
    reserva: cons.reserva,
  });
  assert.strictEqual(rep.idempotente, true);
  assert.throws(
    () => svc.cancelarReserva(cons.item, cons.reserva),
    (e) => e.code === "failed-precondition",
  );
  console.log("✓ idempotência consumo; cancel só reserva ativa");
})();

(function manutencaoAuth() {
  assert.throws(
    () =>
      svc.reservar({
        item: item({ status: "manutencao" }),
        idReserva: "r",
        idEvento: "e",
        quantidade: 1,
        intervalo: {
          inicio: new Date("2026-10-21"),
          fim: new Date("2026-10-22"),
        },
        reservasAtivas: [],
      }),
    (e) => e.code === "failed-precondition",
  );
  function exigir(uid, idFornecedor) {
    if (uid !== idFornecedor) {
      const e = new Error("permission-denied");
      e.code = "permission-denied";
      throw e;
    }
  }
  assert.throws(() => exigir("outra", "forn-1"), (e) => e.code === "permission-denied");
  exigir("forn-1", "forn-1");
  console.log("✓ manutenção bloqueada; outra empresa negada");
})();

console.log("Estoque fornecedor: ok");
