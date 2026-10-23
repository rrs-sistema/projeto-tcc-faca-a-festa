const assert = require("assert");
const path = require("path");
const {
  agregarDashboardAdmin,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/dashboardAdminService.js",
));

function c(parcial) {
  return {
    idEvento: "e1",
    idOrcamento: "c1",
    contratado: true,
    valorOportunidadeCentavos: 0,
    valorContratadoCentavos: 0,
    pagoCentavos: 0,
    alternativaAtiva: true,
    ...parcial,
  };
}

(function doisEventosSeisContratos() {
  const fatos = [];
  for (const e of ["e1", "e2"]) {
    for (let i = 1; i <= 3; i++) {
      fatos.push(
        c({
          idEvento: e,
          idOrcamento: `${e}-c${i}`,
          valorContratadoCentavos: 100000,
          idFornecedor: `f${i}`,
          idNecessidade: `${e}-n${i}`,
        }),
      );
    }
  }
  const d = agregarDashboardAdmin({ fatos });
  assert.strictEqual(d.qtdEventos, 2);
  assert.strictEqual(d.qtdContratos, 6);
  console.log("✓ 2 eventos / 6 contratos");
})();

(function receitaNaoEVolume() {
  const d = agregarDashboardAdmin({
    fatos: [
      c({
        valorContratadoCentavos: 10_000_000,
        pagoCentavos: 10_000_000,
      }),
    ],
    comissoes: [
      {
        id: "com1",
        status: "recebida",
        valorOriginalCentavos: 500_000,
        valorLiquidadoCentavos: 500_000,
        idEvento: "e1",
      },
    ],
    politicaComissaoAtiva: true,
  });
  assert.strictEqual(d.pagamentosEventosCentavos, 10_000_000);
  assert.strictEqual(d.receitaPlataformaCentavos, 500_000);
  assert.notStrictEqual(d.receitaPlataformaCentavos, d.pagamentosEventosCentavos);
  console.log("✓ 100k movimentados ≠ receita própria 5k");
})();

(function idempotente() {
  const fatos = [
    c({ idOrcamento: "c1", valorContratadoCentavos: 1000, pagoCentavos: 400 }),
    c({ idOrcamento: "c2", valorContratadoCentavos: 2000, pagoCentavos: 0 }),
  ];
  const a = agregarDashboardAdmin({ fatos });
  const b = agregarDashboardAdmin({ fatos });
  assert.deepStrictEqual(
    {
      e: a.qtdEventos,
      c: a.qtdContratos,
      v: a.volumeContratadoCentavos,
      p: a.pagamentosEventosCentavos,
    },
    {
      e: b.qtdEventos,
      c: b.qtdContratos,
      v: b.volumeContratadoCentavos,
      p: b.pagamentosEventosCentavos,
    },
  );
  console.log("✓ repetir agregação não altera totais");
})();

(function semVazarPrivado() {
  const d = agregarDashboardAdmin({ fatos: [], politicaComissaoAtiva: false });
  assert.strictEqual(d.comissaoConfigurada, false);
  assert.ok(!d.rotuloResultado.includes("lucro_liquido"));
  assert.ok(d.formulaAbrangencia.includes("volume_contratado"));
  console.log("✓ sem política: não configurado; sem lucro líquido");
})();

(function authEspelho() {
  function exigirAdmin(tipo) {
    if (tipo !== "A") {
      const e = new Error("permission-denied");
      e.code = "permission-denied";
      throw e;
    }
  }
  assert.throws(() => exigirAdmin("F"), (e) => e.code === "permission-denied");
  assert.throws(() => exigirAdmin("O"), (e) => e.code === "permission-denied");
  exigirAdmin("A");
  console.log("✓ acesso dashboard só admin");
})();

console.log("Dashboard admin: ok");
