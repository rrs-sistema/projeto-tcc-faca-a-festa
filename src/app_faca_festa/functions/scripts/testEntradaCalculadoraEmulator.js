const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw Error('Somente emuladores locais.');
const admin = require('firebase-admin');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');
const { prepararEntradaAssistente, aplicarEntradaAssistente } = require('../lib/services/calculadora/entradaAssistenteService');
const projectId = process.env.CALCULADORA_QA_TEST_PROJECT ?? 'demo-calculadora-entrada';
if (!projectId.startsWith('demo-')) throw Error('Somente projeto demo.');
admin.initializeApp({ projectId });
const db = admin.firestore();
let checks = 0;
const rule = { id: 'menu_almoco_arroz', categoria: 'comida', nome: 'Arroz', tipo: 'comida', publico: 'todos', unidade: 'quilo',
  consumo: .1, preco: 0, selecionado: true, premissas: { id_evento: 'festa', id_cardapio: 'almoco', id_item_cardapio: 'arroz', estado: 'cru', papel_na_refeicao: 'acompanhamento' } };
const a = (id, tipo, extra = {}) => ({ id, tipo, evidencia: 'Trecho sintético de teste', id_cardapio: null, id_item: null, id_orcamento: null,
  nome: null, unidade: null, estado: null, quantidade: null, valor: null, adultos: null, criancas: null, bebes: null, receita: null, ...extra });
const item = { id_cardapio: 'almoco', id_item: 'arroz', unidade: 'kg', estado: 'cru' };
const actions = () => [a('c', 'compra_adicionar', { ...item, quantidade: 5 }), a('p', 'preco', { ...item, valor: 6 }), a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 200 })];
async function seed() {
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  await db.doc('usuarios/owner').set({ tipo: 'O', ativo: true });
  await db.doc('usuarios/other').set({ tipo: 'O', ativo: true });
  await db.doc('evento/festa').set({ id_usuario: 'owner', custo_estimado: 1500 });
  await db.doc('cardapios/almoco').set({ id_evento: 'festa', titulo: 'Almoço', ativo: true });
  await db.doc('cardapios/almoco/itens/arroz').set({ nome: 'Arroz', unidade: 'kg', publico_alvo: 'todos', quantidade_final: 10,
    confirmado: true, disponibilidade: { nome: 'Arroz', unidade: 'kg', estado: 'cru', publico: 'todos', comprado: 2, estoque: 0 } });
  await db.doc('orcamento/buffet').set({ id_evento: 'festa', nome: 'Buffet', custo_estimado: 1000, orcamento_fechado: true, status: 'fechado' });
  await db.doc('orcamento/buffet/orcamento_gasto/inicial').set({ custo: 1000, pago: 100 });
}
function preparar(acoes = actions(), opts = {}) {
  return prepararEntradaAssistente(db, opts.uid ?? 'owner', {
    evento: 'festa', texto: opts.texto ?? 'nota e comprovante de teste', documento: opts.documento ?? true,
    regras: [rule], ...(opts.anexo ? { anexo: opts.anexo } : {}),
  }, async () => ({ resumo: 'Proposta sintética', perguntas: [], documento: opts.identidade === false ? {} : { tipo: opts.tipo ?? 'nota_compra', numero: 'nf-123', emissor: 'Empresa teste' }, acoes }));
}
function aplicar(p, selecionadas, extra = {}) {
  return aplicarEntradaAssistente(db, 'owner', { evento: 'festa', id: p.id, assinatura: p.assinatura,
    selecionadas: selecionadas ?? p.acoes.map(a => a.id), conferiu_duplicidade: true, ...extra });
}
async function rejeita(call, code = 'failed-precondition') { await assert.rejects(call, e => e.code === code || e.code?.endsWith(code)); checks++; }
async function main() {
  const env = await initializeTestEnvironment({ projectId, firestore: { rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8') } });
  try {
    await seed();
    await rejeita(() => preparar([], { uid: 'other' }), 'permission-denied');
    await rejeita(() => prepararEntradaAssistente(db, undefined, {}, async () => ({})), 'unauthenticated');
    const p = await preparar();
    assert.equal(p.acoes.length, 3); checks++;
    assert.ok(p.acoes[0].descricao.includes('total comprado: 7')); checks++;
    const owner = env.authenticatedContext('owner').firestore(), other = env.authenticatedContext('other').firestore();
    await rejeita(() => setDoc(doc(other, 'evento/festa'), { id_usuario: 'other' }, { merge: true }), 'permission-denied');
    await rejeita(() => setDoc(doc(owner, 'evento/festa'), { id_usuario: 'other' }, { merge: true }), 'permission-denied');
    await setDoc(doc(owner, 'evento/festa'), { custo_estimado: 1500 }, { merge: true }); checks++;
    await getDoc(doc(owner, `calculadora_operacao/festa/entradas/${p.id}`)); checks++;
    await rejeita(() => getDoc(doc(other, `calculadora_operacao/festa/entradas/${p.id}`)), 'permission-denied');
    await rejeita(() => setDoc(doc(owner, `calculadora_operacao/festa/entradas/${p.id}`), { acoes: [] }), 'permission-denied');
    const results = await Promise.all([aplicar(p), aplicar(p)]);
    assert.deepEqual(results.map(r => r.aplicado).sort(), [false, true]); checks++;
    const arroz = (await db.doc('cardapios/almoco/itens/arroz').get()).data();
    assert.equal(arroz.disponibilidade.comprado, 7); assert.equal(arroz.quantidade_final, 10); assert.equal(arroz.confirmado, true); checks += 3;
    const op = (await db.doc('calculadora_operacao/festa').get()).data();
    assert.equal(op.execucao.regras[0].preco, 6); checks++;
    const pagos = await db.collection('orcamento/buffet/orcamento_gasto').get();
    assert.equal(pagos.docs.reduce((s, d) => s + d.data().pago, 0), 300); checks++;
    assert.equal(pagos.size, 1); checks++;
    assert.ok(pagos.docs.every(d => d.data().pago <= d.data().custo)); checks++;
    const repeat = await preparar(); assert.equal(repeat.acoes.length, 0); assert.equal(repeat.ja_registradas, 3); checks += 2;
    await rejeita(() => aplicarEntradaAssistente(db, 'other', { evento: 'festa', id: p.id, assinatura: p.assinatura, selecionadas: ['c'] }), 'permission-denied');
    await rejeita(() => aplicar(p, ['c']));
    // Partial application can import the remaining actions of the same document.
    await seed(); const parcial = await preparar(); await aplicar(parcial, ['c']);
    const restante = await preparar(); assert.deepEqual(restante.acoes.map(a => a.id), ['p', 'pg']); checks++;
    await aplicar(restante);
    assert.equal((await db.doc('cardapios/almoco/itens/arroz').get()).data().disponibilidade.comprado, 7); checks++;
    // A different scan/text with the same invoice identity is still deduplicated.
    assert.equal((await preparar(actions(), { texto: 'outra digitalização do mesmo documento' })).acoes.length, 0); checks++;
    // A failed payment rolls back all other selected actions.
    await seed(); const invalido = await preparar([...actions().slice(0, 2), a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 9999 })]);
    await rejeita(() => aplicar(invalido));
    assert.equal((await db.doc('cardapios/almoco/itens/arroz').get()).data().disponibilidade.comprado, 2); checks++;
    assert.equal((await db.doc('calculadora_operacao/festa').get()).exists, false); checks++;
    // Insertion into captured queries invalidates the pending proposal.
    const antigo = await preparar(); await db.doc('convidado/novo').set({ id_evento: 'festa' });
    await rejeita(() => aplicar(antigo));
    await seed();
    const novo = await preparar([a('d', 'despesa', { nome: 'Compra de arroz', valor: 60 }), a('pg', 'pagamento', { id_orcamento: 'nova:d', valor: 20 }), a('o', 'cotacao', { nome: 'Decoração', valor: 500 })]);
    await aplicar(novo, ['d', 'o']);
    const after = await preparar([a('d', 'despesa', { nome: 'Compra de arroz', valor: 60 }), a('pg', 'pagamento', { id_orcamento: 'nova:d', valor: 20 }), a('o', 'cotacao', { nome: 'Decoração', valor: 500 })]);
    assert.deepEqual(after.acoes.map(a => a.id), ['pg']); checks++;
    await aplicar(after);
    const budgets = (await db.collection('orcamento').get()).docs.map(d => ({ id: d.id, ...d.data() }));
    assert.equal(budgets.length, 3); checks++;
    const cotacao = budgets.find(b => b.nome === 'Decoração');
    assert.equal(cotacao.orcamento_fechado, false); assert.equal(cotacao.status, 'em_negociacao'); checks += 2;
    const compra = budgets.find(b => b.nome === 'Compra de arroz');
    const pagamentos = await db.collection(`orcamento/${compra.id}/orcamento_gasto`).get();
    assert.equal(pagamentos.docs.reduce((s, d) => s + d.data().pago, 0), 20); checks++;
    assert.equal(pagamentos.size, 1); checks++;
    assert.equal(pagamentos.docs[0].data().custo, 60); checks++;
    assert.equal(pagamentos.docs[0].data().nome, 'Compra de arroz'); checks++;
    assert.equal(pagamentos.docs[0].data().id_gasto, pagamentos.docs[0].id); checks++;
    // Split payments update the original expense rows without duplicating cost.
    await seed();
    await db.doc('orcamento/buffet/orcamento_gasto/inicial').update({ custo: 400, pago: 100 });
    await db.doc('orcamento/buffet/orcamento_gasto/segundo').set({ custo: 600, pago: 0 });
    await aplicar(await preparar([a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 700 })]));
    const distribuidos = (await db.collection('orcamento/buffet/orcamento_gasto').get()).docs.map(d => d.data());
    assert.equal(distribuidos.length, 2); checks++;
    assert.equal(distribuidos.reduce((s, g) => s + g.custo, 0), 1000); checks++;
    assert.equal(distribuidos.reduce((s, g) => s + g.pago, 0), 800); checks++;
    assert.ok(distribuidos.every(g => g.pago <= g.custo)); checks++;
    // A legacy budget without child rows acquires a compatible expense detail.
    await seed(); await db.doc('orcamento/buffet/orcamento_gasto/inicial').delete();
    await aplicar(await preparar([a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 200 })]));
    const detalhe = (await db.collection('orcamento/buffet/orcamento_gasto').get()).docs;
    assert.equal(detalhe.length, 1); checks++;
    assert.equal(detalhe[0].data().custo, 1000); checks++;
    assert.equal(detalhe[0].data().pago, 200); checks++;
    assert.equal(detalhe[0].data().id_gasto, detalhe[0].id); checks++;
    assert.equal(detalhe[0].data().nome, 'Buffet'); checks++;
    await seed();
    await db.doc('orcamento/buffet/orcamento_gasto/inicial').update({ custo: 50, pago: 100 });
    await rejeita(() => preparar([a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 10 })]).then(p => aplicar(p)));
    // Unknown identifiers and incompatible units become questions, not actions.
    const ambiguo = await preparar([a('x', 'compra_adicionar', { ...item, id_item: 'outro', quantidade: 3 }), a('y', 'compra_adicionar', { ...item, unidade: 'pacote', quantidade: 3 })]);
    assert.equal(ambiguo.acoes.length, 0); assert.equal(ambiguo.perguntas.length, 2); checks += 2;
    await seed(); const semId = await preparar([a('c', 'compra_adicionar', { ...item, quantidade: 1 })], { identidade: false });
    await rejeita(() => aplicar(semId, ['c'], { conferiu_duplicidade: false }));
    await aplicar(semId);
    await rejeita(() => preparar([], { anexo: { mime: 'application/pdf', base64: Buffer.from('arquivo falso').toString('base64') } }));
    await seed();
    const globais = await preparar([a('p', 'publico', { adultos: 29, criancas: 8, bebes: 0 }), a('h', 'duracao', { quantidade: 6 }), a('l', 'limite', { valor: 8500 })]);
    await aplicar(globais);
    assert.equal((await db.doc('evento/festa').get()).data().custo_estimado, 8500); checks++;
    assert.equal((await db.doc('calculadora_operacao/festa').get()).data().configuracao_planejamento.publico.adultos, 29); checks++;
    // Stock remains central and unreserved; planned quantity is distinct from purchased.
    await seed();
    await aplicar(await preparar([a('s', 'estoque', { ...item, quantidade: 3 }), a('q', 'quantidade', { ...item, quantidade: 8 })]));
    const stock = (await db.doc('calculadora_operacao/festa').get()).data();
    assert.equal(Object.values(stock.lotes)[0].total, 3); checks++;
    assert.deepEqual(Object.values(stock.lotes)[0].reservas, {}); checks++;
    assert.equal((await db.doc('cardapios/almoco/itens/arroz').get()).data().quantidade_final, 8); checks++;
    assert.equal((await db.doc('cardapios/almoco/itens/arroz').get()).data().disponibilidade.comprado, 2); checks++;
    await seed();
    await db.doc('orcamento/buffet').update({ pago: true });
    await rejeita(() => preparar([a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 10 })]).then(p => aplicar(p)));
    await seed();
    await db.doc('orcamento/buffet/orcamento_gasto/inicial').update({ pago: -20 });
    await rejeita(() => preparar([a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 10 })]).then(p => aplicar(p)));
    await seed();
    await db.doc('calculadora_operacao/festa').set({ revisao: 1, execucao: { regras: [{ ...rule, premissas: { ...rule.premissas, participacao: .8 } }] } });
    const receita = { rendimento: 2, unidade: 'kg', estado: 'cru', ingredientes: [{ nome: 'Arroz', quantidade: 2, unidade: 'kg', estado: 'cru' }] };
    await aplicar(await preparar([a('r', 'receita', { ...item, receita })]));
    const salva = (await db.doc('calculadora_operacao/festa').get()).data().execucao.regras[0];
    assert.equal(salva.premissas.participacao, .8); checks++;
    assert.equal(salva.premissas.ficha_tecnica.ingredientes[0].quantidade, 2); checks++;
    const injection = await preparar([a('pg', 'pagamento', { id_orcamento: 'buffet', valor: 999 })], { tipo: 'cotacao' });
    assert.equal(injection.acoes.length, 0); checks++;
    assert.match(injection.perguntas[0], /Cotação não comprova/); checks++;
    await seed();
    await aplicar(await preparar([a('d', 'despesa', { nome: 'Compra teste', valor: 60 })]));
    const alterada = await preparar([a('d', 'despesa', { nome: 'Compra teste', valor: 70 })]);
    assert.equal(alterada.acoes.length, 0); checks++;
    assert.match(alterada.perguntas[0], /extração financeira mudou/); checks++;
    // An acknowledged retry checks the receipt before recapturing a growing event.
    await seed();
    const recibo = await preparar([a('c', 'compra_adicionar', { ...item, quantidade: 1 })]);
    await aplicar(recibo);
    const batch = db.batch();
    for (let i = 0; i < 121; i++) batch.set(db.doc(`convidado/extra_${i}`), { id_evento: 'festa' });
    await batch.commit();
    assert.equal((await aplicar(recibo)).aplicado, false); checks++;
    console.log(`Entrada inteligente: ${checks} verificações de transação, autorização e duplicidade OK.`);
  } finally { await env.cleanup(); await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
