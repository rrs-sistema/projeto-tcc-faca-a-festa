const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { exigirEmuladorDemo } = require("./exigirEmuladorDemo");

exigirEmuladorDemo("demo-abrangencia");

const { admin } = require("../lib/shared/firebaseAdmin");
const {
  consultarAbrangenciaFornecedor,
  consultarTabelasAbrangenciaAdmin,
  publicarTabelaAbrangenciaAdmin,
} = require("../lib/functions/fornecedores/abrangencia");

const db = admin.firestore();
const adminUid = "administrador";
const fornecedorUid = "fornecedor";
const dia = new Intl.DateTimeFormat("sv-SE", {
  timeZone: "America/Sao_Paulo", year: "numeric", month: "2-digit", day: "2-digit",
});

async function testar() {
  const hoje = dia.format(new Date());
  const futuro = dia.format(new Date(Date.now() + 2 * 86400000));
  const chamar = (funcao, uid, data = {}) => funcao.run({
    data, auth: uid ? { uid } : undefined,
  });
  const publicar = (uid, data) => chamar(publicarTabelaAbrangenciaAdmin, uid, data);
  const cobertura = () => chamar(consultarAbrangenciaFornecedor, fornecedorUid);
  const consultarAdmin = () => chamar(consultarTabelasAbrangenciaAdmin, adminUid);

  await Promise.all([
    db.doc(`usuarios/${adminUid}`).set({ tipo: "A", ativo: true, nome: "  Ana Administradora  " }),
    db.doc(`usuarios/${fornecedorUid}`).set({ tipo: "F", ativo: true }),
    db.doc("territorio/ativo").set({
      id_fornecedor: fornecedorUid, ativo: true, raio_km: 34, tipo_cobertura: "raio",
    }),
    db.doc("territorio/inativo").set({
      id_fornecedor: fornecedorUid, ativo: false, raio_km: 100,
    }),
    db.doc("territorio/outro").set({ id_fornecedor: "outro", ativo: true, raio_km: 60 }),
  ]);

  assert.deepEqual(await cobertura(), {
    raioGratuitoKm: 20, incrementoKm: 5, tabela: null,
    territorios: [{ raioKm: 34, tipo: "raio", descricao: null }],
  });
  await assert.rejects(
    () => chamar(consultarAbrangenciaFornecedor, undefined), { code: "unauthenticated" },
  );
  await assert.rejects(
    () => chamar(consultarTabelasAbrangenciaAdmin, fornecedorUid), { code: "permission-denied" },
  );

  const primeiraTabela = { vigencia: hoje, valoresCentavos: [1000, 1200, 1500], pedidoId: randomUUID() };
  await assert.rejects(() => publicar(fornecedorUid, primeiraTabela), { code: "permission-denied" });
  for (const alteracao of [
    { valoresCentavos: [] },
    { valoresCentavos: [0] },
    { valoresCentavos: [10.5] },
    { valoresCentavos: [Number.MAX_SAFE_INTEGER, 1] },
    { vigencia: "2090-02-30" },
    { vigencia: "2000-01-01" },
  ]) {
    await assert.rejects(() => publicar(adminUid, { ...primeiraTabela, ...alteracao }), {
      code: "invalid-argument",
    });
  }
  const primeira = await publicar(adminUid, primeiraTabela);
  assert.deepEqual((await cobertura()).tabela.faixas, [
    { ateKm: 25, adicionalCentavos: 1000, mensalidadeCentavos: 1000 },
    { ateKm: 30, adicionalCentavos: 1200, mensalidadeCentavos: 2200 },
    { ateKm: 35, adicionalCentavos: 1500, mensalidadeCentavos: 3700 },
  ]);

  const agendada = await publicar(adminUid, {
    vigencia: futuro, valoresCentavos: [900], pedidoId: randomUUID(),
  });
  const segunda = await publicar(adminUid, {
    vigencia: hoje, valoresCentavos: [1100], pedidoId: randomUUID(),
  });
  assert.equal((await cobertura()).tabela.id, segunda.id);

  const primeiroPedidoRepetido = await publicar(adminUid, primeiraTabela);
  assert.equal(primeiroPedidoRepetido.id, primeira.id);
  await assert.rejects(() => publicar(adminUid, {
    ...primeiraTabela, valoresCentavos: [99],
  }), { code: "already-exists" });

  const resultadoAdmin = await consultarAdmin();
  assert.equal(resultadoAdmin.vigente.id, segunda.id);
  assert.deepEqual(resultadoAdmin.historico.map(tabela => tabela.id), [
    agendada.id, segunda.id, primeira.id,
  ]);
  assert.equal(resultadoAdmin.historico[0].autorId, adminUid);
  assert.equal(resultadoAdmin.vigente.autorNome, "Ana Administradora");
  assert(resultadoAdmin.historico.every(tabela => tabela.autorNome === "Ana Administradora"));
  await db.doc(`usuarios/${adminUid}`).update({ nome: "" });
  assert.equal((await consultarAdmin()).historico[0].autorNome, null);
  await db.doc(`usuarios/${adminUid}`).update({ nome: "Ana Administradora" });
  await db.doc(`abrangencia_tabelas/${primeira.id}`).update({ autorId: "usuario-excluido" });
  const autorExcluido = (await consultarAdmin()).historico.find(tabela => tabela.id === primeira.id);
  assert.equal(autorExcluido.autorNome, null);
  assert.equal(Object.hasOwn((await cobertura()).tabela, "autorId"), false);
  assert.equal(Object.hasOwn((await cobertura()).tabela, "autorNome"), false);
  console.log("PASS abrangência: permissões, faixas acumuladas, vigência, histórico e repetição de publicação.");
}

testar().catch(erro => {
  console.error(erro);
  process.exitCode = 1;
}).finally(() => db.terminate());
