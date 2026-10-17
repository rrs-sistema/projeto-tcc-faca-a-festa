const fs = require('fs');
const path = require('path');
const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, query, collection, where, orderBy, updateDoc, writeBatch } = require('firebase/firestore');

async function run() {
  const env = await initializeTestEnvironment({
    projectId: 'faca-festa-calculadora-rules',
    firestore: { rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8') },
  });
  try {
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'usuarios/owner'), { tipo: 'O', ativo: true });
      await setDoc(doc(db, 'usuarios/other'), { tipo: 'O', ativo: true });
      await setDoc(doc(db, 'usuarios/provider'), { tipo: 'F', ativo: true });
      await setDoc(doc(db, 'orcamento/custo'), { id_evento: 'festa', id_fornecedor: 'provider', id_solicitante: 'owner', nome: 'Buffet', custo_estimado: 100 });
      await setDoc(doc(db, 'usuarios/admin'), { tipo: 'A', ativo: true });
      await setDoc(doc(db, 'evento/festa'), { id_usuario: 'owner' });
      await setDoc(doc(db, 'evento/outra'), { id_usuario: 'other' });
      await setDoc(doc(db, 'calculadora_festa/calc_festa_999'), { id_evento: 'outra', id_usuario: 'other' });
      await setDoc(doc(db, 'calculadora_festa/calc_festa_998/itens/orfao'), { quantidade: 1 });
      await setDoc(doc(db, 'calculadora_festa/original'), { id_evento: 'festa', id_usuario: 'owner' });
      await setDoc(doc(db, 'calculadora_festa/legado'), { id_evento: 'festa' });
      await setDoc(doc(db, 'calculadora_festa/original/itens/bolo'), { quantidade: 3 });
    });
    const owner = env.authenticatedContext('owner').firestore();
    const other = env.authenticatedContext('other').firestore();
    const admin = env.authenticatedContext('admin').firestore();
    const anonymous = env.unauthenticatedContext().firestore();
    const provider = env.authenticatedContext('provider').firestore();
    const operacao = { id_evento: 'festa', id_usuario: 'owner', versao: 1, revisao: 1,
      lotes: { arroz: { total: 10, reservas: {} } }, refeicoes: {} };
    await assertSucceeds(setDoc(doc(owner, 'calculadora_operacao/festa'), operacao));
    await assertSucceeds(getDoc(doc(owner, 'calculadora_operacao/festa')));
    for (const db of [other, provider, anonymous]) {
      await assertFails(getDoc(doc(db, 'calculadora_operacao/festa')));
      await assertFails(setDoc(doc(db, 'calculadora_operacao/festa'), operacao));
    }
    await assertFails(updateDoc(doc(owner, 'calculadora_operacao/festa'), { id_usuario: 'other' }));
    await assertFails(setDoc(doc(owner, 'calculadora_operacao/fora'), { ...operacao, id_evento: 'fora' }));
    const conferencia = { calculadora_conferencia_financeira: { modo: 'realizado', valor: 100 } };
    await assertSucceeds(updateDoc(doc(owner, 'orcamento/custo'), conferencia));
    await assertSucceeds(updateDoc(doc(provider, 'orcamento/custo'), { nome: 'Buffet atualizado' }));
    const cobertura = { calculadora_cobre_itens: ['v2:["festa","almoco","arroz","arroz|kg|todos"]'] };
    await assertSucceeds(updateDoc(doc(owner, 'orcamento/custo'), cobertura));
    await assertFails(updateDoc(doc(provider, 'orcamento/custo'), { calculadora_cobre_itens: [] }));
    await assertFails(setDoc(doc(owner, 'calculadora_ia_limites/owner'), { chamadas: 0 }));
    await assertFails(getDoc(doc(other, 'calculadora_ia_limites/owner')));
    await assertSucceeds(getDocs(query(collection(owner, 'calculadora_festa'), where('id_usuario', '==', 'owner'), orderBy('data_atualizacao', 'desc'))));
    await assertFails(updateDoc(doc(provider, 'orcamento/custo'), { id_solicitante: 'provider' }));
    await assertFails(updateDoc(doc(provider, 'orcamento/custo'), { id_evento: 'outra' }));
    for (const db of [provider, other, anonymous]) {
      await assertFails(updateDoc(doc(db, 'orcamento/custo'), { calculadora_conferencia_financeira: { modo: 'sem_itens', valor: 100 } }));
    }
    await assertSucceeds(updateDoc(doc(admin, 'orcamento/custo'), { calculadora_conferencia_financeira: { modo: 'revisar' } }));
    await assertSucceeds(getDocs(query(collection(owner, 'calculadora_festa'), where('id_evento', '==', 'festa'))));
    await assertSucceeds(getDoc(doc(admin, 'calculadora_festa/original')));
    for (const db of [other, anonymous]) {
      await assertFails(getDoc(doc(db, 'calculadora_festa/original')));
      await assertFails(getDoc(doc(db, 'calculadora_festa/original/itens/bolo')));
      await assertFails(setDoc(doc(db, 'calculadora_festa/original/itens/forjado'), { quantidade: 999 }));
      await assertFails(setDoc(doc(db, 'calculadora_festa/forjado'), { id_evento: 'festa', id_usuario: 'other' }));
    }
    await assertFails(updateDoc(doc(owner, 'calculadora_festa/original'), { id_usuario: 'other' }));
    await assertFails(updateDoc(doc(owner, 'calculadora_festa/original'), { id_evento: 'outra' }));
    await assertSucceeds(updateDoc(doc(owner, 'calculadora_festa/original'), {
      consumo_observado: { arroz: { sobra_pronta: 1 } }, consumo_registrado_em: '2026-10-15T12:00:00Z'
    }));
    await assertSucceeds(getDocs(query(collection(owner, 'calculadora_festa'),
      where('id_usuario', '==', 'owner'), orderBy('consumo_registrado_em', 'desc'))));
    for (const db of [other, anonymous]) {
      await assertFails(updateDoc(doc(db, 'calculadora_festa/original'), { consumo_observado: {} }));
      await assertFails(getDocs(query(collection(db, 'calculadora_festa'),
        where('id_usuario', '==', 'owner'), orderBy('consumo_registrado_em', 'desc'))));
    }
    await assertFails(updateDoc(doc(other, 'calculadora_festa/legado'), { id_usuario: 'other' }));
    await assertSucceeds(updateDoc(doc(owner, 'calculadora_festa/legado'), { id_usuario: 'owner' }));
    // O app consulta itens antigos antes de gravar o primeiro documento pai.
    const novaDoEvento = 'calc_festa_1770000000000000';
    await assertSucceeds(getDocs(collection(owner, `calculadora_festa/${novaDoEvento}/itens`)));
    for (const db of [other, provider, anonymous]) {
      await assertFails(getDocs(collection(db, `calculadora_festa/${novaDoEvento}/itens`)));
    }
    await assertFails(getDocs(collection(owner, 'calculadora_festa/calc_inexistente_123/itens')));
    await assertFails(getDocs(collection(owner, 'calculadora_festa/sem_identidade/itens')));
    await assertFails(getDocs(collection(owner, `calculadora_festa/${novaDoEvento}/analises`)));
    await assertFails(getDocs(collection(owner, 'calculadora_festa/calc_festa_999/itens')));
    await assertSucceeds(getDocs(collection(other, 'calculadora_festa/calc_festa_999/itens')));
    await assertFails(getDocs(collection(other, 'calculadora_festa/calc_festa_998/itens')));
    await assertSucceeds(getDocs(collection(owner, 'calculadora_festa/calc_festa_998/itens')));
    const limparOrfao = writeBatch(owner);
    limparOrfao.set(doc(owner, 'calculadora_festa/calc_festa_998'), { id_evento: 'festa', id_usuario: 'owner' });
    limparOrfao.delete(doc(owner, 'calculadora_festa/calc_festa_998/itens/orfao'));
    await assertSucceeds(limparOrfao.commit());
    const primeiroSave = writeBatch(owner);
    primeiroSave.set(doc(owner, `calculadora_festa/${novaDoEvento}`), { id_evento: 'festa', id_usuario: 'owner' });
    primeiroSave.set(doc(owner, `calculadora_festa/${novaDoEvento}/itens/arroz`), { quantidade: 2 });
    await assertSucceeds(primeiroSave.commit());
    await assertSucceeds(getDocs(collection(owner, `calculadora_festa/${novaDoEvento}/itens`)));
    const create = writeBatch(owner);
    create.set(doc(owner, 'calculadora_festa/nova'), { id_evento: 'festa', id_usuario: 'owner' });
    create.set(doc(owner, 'calculadora_festa/nova/itens/bolo'), { quantidade: 3 });
    await assertSucceeds(create.commit());
    const remove = writeBatch(owner);
    remove.delete(doc(owner, 'calculadora_festa/nova/itens/bolo'));
    remove.delete(doc(owner, 'calculadora_festa/nova'));
    await assertSucceeds(remove.commit());
    console.log('Calculadora Firestore rules: OK');
  } finally { await env.cleanup(); }
}
run().catch((error) => { console.error(error); process.exit(1); });
