/* Real Firebase client authentication/rules + Admin SDK transactional executor.
 * This script refuses to run outside local emulators and a demo project. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Use apenas emuladores locais de Auth e Firestore.');
}
const projectId = 'demo-calculadora-execucao';
const admin = require('firebase-admin');
admin.initializeApp({ projectId });
const db = admin.firestore();
const { executarPlano, normalizarFonte } = require('../lib/services/calculadora/executarPlanoService');
const { salvarRevisaoPosEvento } = require('../lib/services/calculadora/revisaoPosEventoService');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, createUserWithEmailAndPassword, getIdToken } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, doc, getDoc, setDoc, getDocs, collection, query, where } = require('firebase/firestore');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fixture = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../.dart_tool/calculadora-plano-fixture.json'), 'utf8'));
const clone = v => JSON.parse(JSON.stringify(v));
let checks = 0;
async function rejects(action, code) {
  await assert.rejects(action, e => e.code === code || e.code?.endsWith(code)); checks++;
}
async function seed(payload = fixture) {
  const all = await db.listCollections();
  for (const c of all) await db.recursiveDelete(c);
  for (const [key, value] of Object.entries(payload.plano.fontes)) {
    if (value != null) await db.doc(key).set(value);
  }
  await db.doc('usuarios/owner').set({ tipo: 'O', ativo: true });
  await db.doc('usuarios/other').set({ tipo: 'O', ativo: true });
}
async function client(uid) {
  const app = initializeApp({ projectId, apiKey: 'demo-key', appId: `demo-${uid}` }, uid);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, { disableWarnings: true });
  const user = await createUserWithEmailAndPassword(auth, `${uid}@example.test`, 'testPassword123!');
  // Seeded fixture uses stable organizer IDs; map the authenticated UID instead.
  const firestore = getFirestore(app), [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  connectFirestoreEmulator(firestore, host, Number(port));
  const token = await getIdToken(user.user);
  const verified = await admin.auth().verifyIdToken(token);
  return { app, firestore, uid: verified.uid, token };
}
async function main() {
  const env = await initializeTestEnvironment({ projectId, firestore: {
    rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
  } });
  const owner = await client('organizador'), other = await client('outro');
  // Authenticated UIDs are actual emulator-generated users.
  fixture.plano.fontes['evento/evento'].id_usuario = owner.uid;
  try {
    await seed();
    await db.doc(`usuarios/${owner.uid}`).set({ tipo: 'O', ativo: true });
    await db.doc(`usuarios/${other.uid}`).set({ tipo: 'O', ativo: true });
    const menus = await getDocs(query(collection(owner.firestore, 'cardapios'), where('id_evento', '==', 'evento')));
    assert.equal(menus.size, 2); checks++;
    await setDoc(doc(owner.firestore, `calculadora_preferencias/${owner.uid}`), { versao: 1, receitas: [] });
    await getDoc(doc(owner.firestore, `calculadora_preferencias/${owner.uid}`)); checks++;
    await rejects(() => getDoc(doc(other.firestore, `calculadora_preferencias/${owner.uid}`)), 'permission-denied');
    await rejects(() => executarPlano(db, undefined, fixture), 'unauthenticated');
    await rejects(() => executarPlano(db, other.uid, fixture), 'permission-denied');
    // Real authenticated callable protocol; repeat returns the original receipt.
    async function chamar(payload, usuario = owner) {
      const response = await fetch(`http://127.0.0.1:5001/${projectId}/southamerica-east1/aplicarPlanoCalculadora`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${usuario.token}` }, body: JSON.stringify({ data: payload }) });
      const body = await response.json();
      if (body.error) { const e = new Error(body.error.message); e.code = body.error.status.toLowerCase().replaceAll('_', '-'); throw e; }
      return body.result;
    }
    const primeira = await chamar(fixture), repetida = await chamar(fixture);
    assert.equal(primeira.aplicado, true); checks++;
    assert.equal(repetida.aplicado, false); checks++;
    assert.deepEqual(primeira.recibo, repetida.recibo); checks++;
    await rejects(() => chamar(fixture, other), 'permission-denied');
    await rejects(() => setDoc(doc(owner.firestore, 'calculadora_operacao/evento/aplicacoes/forjado'), { versao: 1, id_evento: 'evento', id_usuario: owner.uid }), 'permission-denied');
    await seed();
    assert.equal(await executarPlano(db, owner.uid, fixture), true); checks++;
    assert.equal(await executarPlano(db, owner.uid, fixture), false); checks++;
    assert.equal((await db.doc('cardapios/almoco/itens/arroz').get()).data().quantidade_final, 7); checks++;
    const tasks = await db.collection('tarefa').get();
    assert.ok(tasks.size > 0); checks++;
    assert.ok(tasks.docs.every(d => d.data().id_responsavel === owner.uid)); checks++;
    // Natural-language configuration survives the grouped executor and cannot be changed by it.
    const configured = clone(fixture);
    const config = { base: 'manual', publico: { adultos: 29, criancas: 8, bebes: 0 }, duracao: 6, revisao: 1 };
    configured.plano.fontes['calculadora_operacao/evento'] = { versao: 1, revisao: 0, lotes: {}, configuracao_planejamento: config };
    configured.plano.operacao.configuracao_planejamento = config;
    await seed(configured);
    const tamperedConfig = clone(configured); tamperedConfig.plano.operacao.configuracao_planejamento.duracao = 24;
    await rejects(() => executarPlano(db, owner.uid, tamperedConfig), 'failed-precondition');
    assert.equal(await executarPlano(db, owner.uid, configured), true); checks++;
    assert.deepEqual((await db.doc('calculadora_operacao/evento').get()).data().configuracao_planejamento, config); checks++;
    // A manual edit not used by this plan remains available when reopening.
    const saved = clone(fixture);
    const extra = { ...clone(fixture.plano.regras[0]), id: 'manual_preservada', preco: 35.5, selecionado: false };
    saved.plano.fontes['calculadora_operacao/evento'] = { versao: 1, revisao: 0, execucao: { regras: [extra] } };
    saved.plano.operacao.execucao = { regras: [extra] };
    await seed(saved);
    assert.equal(await executarPlano(db, owner.uid, saved), true); checks++;
    assert.deepEqual((await db.doc('calculadora_operacao/evento').get()).data().execucao.regras.find(r => r.id === extra.id), extra); checks++;
    await seed();
    const concurrent = await Promise.all([executarPlano(db, owner.uid, fixture), executarPlano(db, owner.uid, fixture)]);
    assert.deepEqual(concurrent.sort(), [false, true]); checks++;
    assert.equal((await db.collection('tarefa').get()).size, tasks.size); checks++;
    await rejects(() => getDoc(doc(other.firestore, 'calculadora_operacao/evento')), 'permission-denied');
    const changed = clone(fixture); changed.plano.publico.adultos++;
    await rejects(() => executarPlano(db, owner.uid, changed), 'failed-precondition');
    // New rows in every captured query, including originally empty ones.
    for (const [key, value] of [
      ['convidado/novo', { id_evento: 'evento' }],
      ['cardapios/novo', { id_evento: 'evento', ativo: true }],
      ['cardapios/almoco/itens/novo', { nome: 'novo' }],
      ['orcamento/novo', { id_evento: 'evento' }],
      ['tarefa/nova', { id_evento: 'evento' }],
    ]) {
      await seed(); await db.doc(key).set(value);
      await rejects(() => executarPlano(db, owner.uid, fixture), 'failed-precondition');
      assert.equal((await db.doc('calculadora_operacao/evento').get()).exists, false); checks++;
    }
    // Newly inserted child expense after capture.
    await seed();
    const budget = { id_evento: 'evento', custo_estimado: 20 };
    await db.doc('orcamento/base').set(budget);
    const withBudget = clone(fixture); withBudget.plano.fontes['orcamento/base'] = budget;
    await db.doc('orcamento/base/orcamento_gasto/novo').set({ valor: 10 });
    await rejects(() => executarPlano(db, owner.uid, withBudget), 'failed-precondition');
    // Deletion / update / foreign path / invalid quantity never partially commit.
    for (const mutate of [
      async () => db.doc('cardapios/almoco/itens/arroz').delete(),
      async () => db.doc('evento/evento').update({ total_adultos: 99 }),
    ]) {
      await seed(); await mutate();
      await rejects(() => executarPlano(db, owner.uid, fixture), 'failed-precondition');
    }
    await seed();
    const foreign = clone(fixture); foreign.plano.alteracoes['evento/outra'] = { id_usuario: owner.uid };
    await rejects(() => executarPlano(db, owner.uid, foreign), 'failed-precondition');
    const negative = clone(fixture); negative.plano.alteracoes['cardapios/almoco/itens/arroz'].quantidade_sugerida = -1;
    await rejects(() => executarPlano(db, owner.uid, negative), 'failed-precondition');
    const duplicada = clone(fixture);
    const tarefa = Object.keys(duplicada.plano.alteracoes).find(p => p.startsWith('tarefa/'));
    duplicada.plano.alteracoes[`${tarefa}-duplicada`] = duplicada.plano.alteracoes[tarefa];
    delete duplicada.plano.alteracoes[tarefa];
    await rejects(() => executarPlano(db, owner.uid, duplicada), 'failed-precondition');
    for (const name of ['estoque', 'ingredientes']) {
      const payload = JSON.parse(fs.readFileSync(path.resolve(__dirname, `../../.dart_tool/calculadora-${name}-fixture.json`), 'utf8'));
      payload.plano.fontes['evento/evento'].id_usuario = owner.uid;
      await seed(payload);
      assert.equal(await executarPlano(db, owner.uid, payload), true); checks++;
      const operation = (await db.doc('calculadora_operacao/evento').get()).data();
      assert.deepEqual(operation.execucao.compras, payload.plano.compras); checks++;
      if (name === 'estoque') {
        const lot = operation.lotes.arroz;
        assert.equal(Object.values(lot.reservas).reduce((sum, r) => sum + r.quantidade, 0), 10); checks++;
        await seed(payload);
        const outroPedido = clone(payload); outroPedido.pedido = 'outro-acesso';
        const disputa = await Promise.allSettled([executarPlano(db, owner.uid, payload), executarPlano(db, owner.uid, outroPedido)]);
        assert.equal(disputa.filter(r => r.status === 'fulfilled').length, 1); checks++;
        assert.equal(disputa.filter(r => r.status === 'rejected' && r.reason.code === 'failed-precondition').length, 1); checks++;
        assert.equal((await db.collection('calculadora_operacao/evento/aplicacoes').get()).size, 1); checks++;
        for (const adulterar of [
          p => { const rs = p.plano.operacao.lotes.arroz.reservas; const k = Object.keys(rs)[0]; rs.alias = rs[k]; delete rs[k]; },
          p => { const rs = p.plano.operacao.lotes.arroz.reservas; rs[Object.keys(rs)[0]].refeicao = 'fora-do-evento'; },
          p => { const rs = p.plano.operacao.lotes.arroz.reservas; rs[Object.keys(rs)[0]].ingrediente = 'inventado'; },
        ]) {
          await seed(payload); const invalid = clone(payload); adulterar(invalid);
          await rejects(() => executarPlano(db, owner.uid, invalid), 'failed-precondition');
          assert.equal((await db.collection('tarefa').get()).size, 0); checks++;
          assert.equal((await db.collection('calculadora_operacao/evento/aplicacoes').get()).size, 0); checks++;
        }
        for (const iniciada of [false, true]) {
          const protegido = clone(payload), reservas = protegido.plano.operacao.lotes.arroz.reservas;
          const chave = Object.keys(reservas)[0], r = { ...reservas[chave], quantidade: 1, origem: iniciada ? 'execucao_v1' : 'manual' };
          protegido.plano.fontes['calculadora_operacao/evento'].lotes.arroz.reservas = { [chave]: r };
          if (iniciada) protegido.plano.fontes['tarefa/preparo-protegido'] = { id_evento: 'evento', calculadora_origem: 'execucao_v1', calculadora_chave: JSON.stringify(['preparo', r.refeicao, r.item]), status: 'em_andamento', titulo: 'Preparar', descricao: 'Preparo iniciado' };
          await seed(protegido);
          await rejects(() => executarPlano(db, owner.uid, protegido), 'failed-precondition');
          assert.deepEqual((await db.doc('calculadora_operacao/evento').get()).data().lotes.arroz.reservas, { [chave]: r }); checks++;
        }
      }
    }
    await seed();
    // Existing timestamps compare in the same representation as the Dart client.
    const dated = clone(fixture), stamp = admin.firestore.Timestamp.fromMillis(1700000000123);
    dated.plano.fontes['evento/evento'].atualizado = normalizarFonte(stamp);
    await db.doc('evento/evento').update({ atualizado: stamp });
    assert.equal(await executarPlano(db, owner.uid, dated), true); checks++;
    // Expected strings are independent of the normalizer: Admin toDate rounds
    // submilliseconds, which previously made an unchanged mobile snapshot stale.
    for (const [seconds, nanos, iso] of [
      [1700000000, 0, '2023-11-14T22:13:20.000Z'],
      [1700000000, 123456000, '2023-11-14T22:13:20.123456Z'],
      [1700000000, 123789000, '2023-11-14T22:13:20.123789Z'],
      [1700000000, 999999999, '2023-11-14T22:13:20.999999Z'],
      [-1, 999999000, '1969-12-31T23:59:59.999999Z'],
    ]) {
      assert.deepEqual(normalizarFonte(new admin.firestore.Timestamp(seconds, nanos)), { __timestamp: iso }); checks++;
    }
    for (const [nanos, iso] of [[123789000, '2023-11-14T22:13:20.123789Z'], [999999000, '2023-11-14T22:13:20.999999Z']]) {
      await seed();
      const micro = clone(fixture);
      micro.plano.fontes['evento/evento'].atualizado = { __timestamp: iso };
      await db.doc('evento/evento').update({ atualizado: new admin.firestore.Timestamp(1700000000, nanos) });
      assert.equal(await executarPlano(db, owner.uid, micro), true); checks++;
      await seed();
      await db.doc('evento/evento').update({ atualizado: new admin.firestore.Timestamp(1700000000 + Math.floor((nanos + 1000) / 1000000000), (nanos + 1000) % 1000000000) });
      await rejects(() => executarPlano(db, owner.uid, micro), 'failed-precondition');
    }
    // Qualitative closure is persisted and cannot certify quantities or payments.
    await seed();
    const future = admin.firestore.Timestamp.fromMillis(Date.now() + 86400000);
    await db.doc('evento/evento').update({ data: future });
    const review = { evento: 'evento', acao: { id_cardapio: 'almoco', revisao: 0, concluir: true, itens: { arroz: 'sobrou' } } };
    await rejects(() => salvarRevisaoPosEvento(db, owner.uid, review), 'failed-precondition');
    await db.doc('evento/evento').update({ data: admin.firestore.Timestamp.fromMillis(Date.now() - 86400000) });
    await rejects(() => salvarRevisaoPosEvento(db, other.uid, review), 'permission-denied');
    const result = await salvarRevisaoPosEvento(db, owner.uid, review);
    assert.equal(result.revisao_pos_evento.almoco.status, 'concluida'); checks++;
    assert.equal(result.revisao_pos_evento.almoco.natureza, 'qualitativa'); checks++;
    assert.equal((await db.doc('evento/evento').get()).data().status, undefined); checks++;
    await rejects(() => salvarRevisaoPosEvento(db, owner.uid, review), 'failed-precondition');
    const updated = { ...review, acao: { ...review.acao, revisao: 1, itens: {} } };
    await rejects(() => salvarRevisaoPosEvento(db, owner.uid, updated), 'failed-precondition');
    console.log(`Execução e revisão autenticadas: ${checks} verificações OK.`);
  } finally {
    await deleteApp(owner.app); await deleteApp(other.app); await env.cleanup();
    await admin.app().delete();
  }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
