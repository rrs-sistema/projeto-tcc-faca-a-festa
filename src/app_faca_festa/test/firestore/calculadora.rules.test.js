const fs = require('fs');
const path = require('path');
const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, query, collection, where, orderBy, updateDoc, writeBatch, runTransaction } = require('firebase/firestore');

async function run() {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || '')) {
    throw new Error('Teste exige FIRESTORE_EMULATOR_HOST local; conexão fora do emulador recusada.');
  }
  const env = await initializeTestEnvironment({
    projectId: 'demo-faca-festa-contexto',
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
      await setDoc(doc(db, 'usuarios/admin-inativo11'), { tipo: 'A', ativo: false });
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
    // Migração e governança não podem ser forjadas pelo cliente, nem admin.
    const novo = env.authenticatedContext('novo11').firestore();
    const inativo = env.authenticatedContext('admin-inativo11').firestore();
    await assertFails(updateDoc(doc(inativo,'usuarios/admin-inativo11'),{ativo:true}));
    await assertFails(setDoc(doc(novo,'usuarios/novo11'),{tipo:'A',ativo:true}));
    await assertFails(updateDoc(doc(owner,'usuarios/owner'),{migracao_planejamento:true}));
    await assertFails(setDoc(doc(admin,'planejamento_compatibilidade/festa'),{schema:1,selecao_ativa:true}));
    await assertFails(setDoc(doc(owner,'planejamento_compatibilidade/outra'),{schema:1}));
    await assertFails(setDoc(doc(admin,'calculadora_itens_base/governanca-forjada'),{governanca_contextual:{estado:'publicada'}}));
    await env.withSecurityRulesDisabled(async context => {
      await setDoc(doc(context.firestore(),'planejamento_compatibilidade/festa'),{schema:1,id_usuario:'owner'});
      await setDoc(doc(context.firestore(),'planejamento_compatibilidade/festa/inspecoes/hash'),{fontes:{privado:true}});
      await setDoc(doc(context.firestore(),'evento/futuro11'),{id_usuario:'owner'});
      await setDoc(doc(context.firestore(),'calculadora_operacao/futuro11'),{id_evento:'futuro11',id_usuario:'owner',versao:2,revisao:1});
    });
    await assertSucceeds(getDoc(doc(owner,'planejamento_compatibilidade/festa')));
    await assertFails(getDoc(doc(other,'planejamento_compatibilidade/festa')));
    await assertFails(getDoc(doc(owner,'planejamento_compatibilidade/festa/inspecoes/hash')));
    await assertSucceeds(getDoc(doc(admin,'planejamento_compatibilidade/festa/inspecoes/hash')));
    await assertFails(setDoc(doc(owner,'calculadora_operacao/futuro11'),{id_evento:'futuro11',id_usuario:'owner',versao:1,revisao:2}));
    // Publicação contextual é exclusiva da callable; nem admin forja versões.
    await assertFails(setDoc(doc(owner,'calculadora_itens_base/editorial'),{referencia_contextual:{versao:1}}));
    await assertFails(setDoc(doc(admin,'calculadora_itens_base/editorial'),{referencia_contextual:{versao:1}}));
    await env.withSecurityRulesDisabled(async context => {
      await setDoc(doc(context.firestore(),'calculadora_itens_base/editorial'),{id:'editorial',nome:'Sintético',ativo:true,referencia_contextual:{id:'editorial',versao:1}});
      await setDoc(doc(context.firestore(),'calculadora_itens_base/editorial/versoes_contextuais/1'),{id:'editorial',versao:1});
    });
    await assertSucceeds(getDoc(doc(owner,'calculadora_itens_base/editorial/versoes_contextuais/1')));
    await assertFails(getDoc(doc(anonymous,'calculadora_itens_base/editorial/versoes_contextuais/1')));
    await assertFails(updateDoc(doc(admin,'calculadora_itens_base/editorial'),{referencia_contextual:{id:'editorial',versao:2}}));
    await assertFails(updateDoc(doc(admin,'calculadora_itens_base/editorial/versoes_contextuais/1'),{versao:2}));
    await assertSucceeds(updateDoc(doc(admin,'calculadora_itens_base/editorial'),{ativo:false}));
    const despesa=doc(owner,'orcamento/custo/orcamento_gasto/parcial');
    await assertSucceeds(setDoc(despesa,{id_orcamento:'custo',custo:6500,pago:500}));
    await assertSucceeds(updateDoc(despesa,{pago:750}));
    for(const patch of [{pago:6501},{pago:-1},{pago:'500'},{id_orcamento:'outra'}])await assertFails(updateDoc(despesa,patch));
    await assertFails(updateDoc(doc(other,'orcamento/custo/orcamento_gasto/parcial'),{pago:800}));
    const vinculo = doc(owner, 'calculadora_festa/calc_festa_12345');
    await assertSucceeds(getDoc(vinculo));
    await assertFails(getDoc(doc(other, 'calculadora_festa/calc_festa_54321')));
    await assertFails(getDoc(doc(anonymous, 'calculadora_festa/calc_festa_54321')));
    const criarVinculo = () => runTransaction(owner, async (tx) => {
      const atual = await tx.get(vinculo);
      if (atual.exists()) return;
      tx.set(vinculo, {id_evento: 'festa', id_usuario: 'owner',
        contexto_planejamento: {id_rascunho_origem: 'rascunho-local'}, total_adultos: 10});
      tx.set(doc(owner, 'calculadora_festa/calc_festa_12345/itens/arroz'), {quantidade: 3});
    });
    await assertSucceeds(criarVinculo());
    await assertSucceeds(updateDoc(vinculo, {total_adultos: 20}));
    await assertSucceeds(criarVinculo());
    if ((await getDoc(vinculo)).data().total_adultos !== 20) throw new Error('Repetição sobrescreveu histórico');
    const operacao = { id_evento: 'festa', id_usuario: 'owner', versao: 1, revisao: 1,
      lotes: { arroz: { total: 10, reservas: {} } }, refeicoes: {} };
    await assertSucceeds(setDoc(doc(owner, 'calculadora_operacao/festa'), operacao));
    await assertSucceeds(getDoc(doc(owner, 'calculadora_operacao/festa')));
    const privado = doc(owner, 'calculadora_operacao/festa');
    await assertFails(updateDoc(privado,{planejador:{menu:{objetivo:'forjado'}}}));
    await assertFails(setDoc(doc(owner,'calculadora_operacao/festa/planejador_confirmacoes/forjado'),{id_usuario:'owner'}));
    await env.withSecurityRulesDisabled(async context=>{
      await updateDoc(doc(context.firestore(),'calculadora_operacao/festa'),{planejador:{menu:{versao:1,objetivo:'manter_receitas'}}});
      await setDoc(doc(context.firestore(),'calculadora_operacao/festa/planejador_confirmacoes/real'),{id_usuario:'owner'});
    });
    await assertSucceeds(getDoc(doc(owner,'calculadora_operacao/festa/planejador_confirmacoes/real')));
    await assertFails(getDoc(doc(other,'calculadora_operacao/festa/planejador_confirmacoes/real')));
    await assertFails(updateDoc(privado,{planejador:{}}));
    await assertSucceeds(updateDoc(privado,{revisao:2}));
    await assertFails(updateDoc(privado, {agenda:[{id:'forjada'}]}));
    const agenda=[{id:'oc1',id_evento:'festa',id_modelo:'modelo',id_cardapio:'oc1',titulo:'Serviço',formato:'nao_definido'}];
    await env.withSecurityRulesDisabled(async context => {
      await updateDoc(doc(context.firestore(),'calculadora_operacao/festa'),{agenda});
      await setDoc(doc(context.firestore(),'calculadora_operacao/festa/agenda_confirmacoes/pedido'),{id_usuario:'owner'});
    });
    await assertSucceeds(updateDoc(privado,{revisao:2}));
    await assertFails(updateDoc(privado,{agenda:[]}));
    await assertFails(updateDoc(privado,{agenda:[{...agenda[0],titulo:'Alteração direta'}]}));
    for(const db of [other,provider,anonymous]) await assertFails(getDoc(doc(db,'calculadora_operacao/festa/agenda_confirmacoes/pedido')));
    await assertFails(setDoc(doc(owner,'calculadora_operacao/festa/agenda_confirmacoes/falso'),{id_usuario:'owner'}));
    await assertSucceeds(updateDoc(privado, {configuracao_planejamento:{duracao:6,perfil:'premium',margem:0.1,verba_alimentacao:1450,confirmacoes:{teste:'recibo'}}}));
    for (const cfg of [{duracao:0},{duracao:25},{duracao:1.5},{perfil:'luxo'},{margem:-0.1},{margem:0.31},{verba_alimentacao:-1},{verba_alimentacao:'1450'},{confirmacoes:[]}]) {
      await assertFails(updateDoc(privado,{configuracao_planejamento:cfg}));
    }
    await assertSucceeds(updateDoc(privado,{configuracao_planejamento:{margem:0,verba_alimentacao:0}}));
    await assertSucceeds(updateDoc(privado,{configuracao_planejamento:{margem:null,verba_alimentacao:null}}));
    await assertSucceeds(updateDoc(privado, {configuracao_planejamento: {base: 'previstos', base_confirmada: true, lista_completude: 'em_preenchimento'}}));
    for (const cfg of [
      {lista_completude: 'inferida_pela_quantidade'}, {base: 'inventada'},
      {base_confirmada: 'sim'}, {base_confirmada: true},
      {base: 'manual', base_confirmada: true},
      {publico: {adultos: -1, criancas: 0, bebes: 0}},
      {publico: {adultos: 1.5, criancas: 0, bebes: 0}},
    ]) await assertFails(updateDoc(privado, {configuracao_planejamento: cfg}));
    await assertSucceeds(updateDoc(privado, {configuracao_planejamento: {base:'manual', base_confirmada:true, lista_completude:'concluida', publico:{adultos:0,criancas:0,bebes:0}}}));
    if ((await getDoc(privado)).data().configuracao_planejamento.publico.adultos !== 0) throw Error('Zero manual perdido');

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
    // Leitura do destino estável ainda inexistente permite a transação inicial.
    const inicial = 'plano_inicial_festa';
    await assertSucceeds(getDoc(doc(owner, `calculadora_festa/${inicial}`)));
    await assertFails(getDoc(doc(anonymous, `calculadora_festa/${inicial}`)));
    const conjunto = writeBatch(owner);
    conjunto.set(doc(owner, `cardapios/${inicial}`), { id_evento: 'festa', origem_plano_inicial: 1 });
    conjunto.set(doc(owner, `cardapios/${inicial}/itens/arroz`), { quantidade_final: 0, confirmado: false });
    conjunto.set(doc(owner, `calculadora_festa/${inicial}`), { id_evento: 'festa', id_usuario: 'owner' });
    conjunto.set(doc(owner, `calculadora_festa/${inicial}/itens/arroz`), { quantidade: 2 });
    await assertSucceeds(conjunto.commit());
    await assertSucceeds(getDoc(doc(owner, `calculadora_festa/${inicial}`)));
    await assertFails(getDoc(doc(other, `calculadora_festa/${inicial}`)));
    const ataque = writeBatch(other);
    ataque.set(doc(other, 'cardapios/plano_inicial_ataque'), { id_evento: 'festa' });
    ataque.set(doc(other, 'cardapios/plano_inicial_ataque/itens/arroz'), { quantidade_final: 999 });
    ataque.set(doc(other, 'calculadora_festa/plano_inicial_ataque'), { id_evento: 'festa', id_usuario: 'other' });
    await assertFails(ataque.commit());
    await env.withSecurityRulesDisabled(async (ctx) => {
      if ((await getDoc(doc(ctx.firestore(), 'cardapios/plano_inicial_ataque'))).exists()) throw Error('Gravação parcial indevida');
    });
    const apagarMenu = writeBatch(owner);
    apagarMenu.delete(doc(owner, `cardapios/${inicial}/itens/arroz`));
    apagarMenu.delete(doc(owner, `cardapios/${inicial}`));
    await assertSucceeds(apagarMenu.commit());
    const executar = writeBatch(owner);
    const tarefaExec = 'calc_exec_festa_revisao';
    await assertSucceeds(getDoc(doc(owner, `tarefa/${tarefaExec}`)));
    await assertFails(getDoc(doc(anonymous, `tarefa/${tarefaExec}`)));
    executar.update(doc(owner, 'calculadora_operacao/festa'), { revisao: 2, execucao: { versao: 1, pedido: 'pedido', publico: { adultos: 37 } } });
    executar.set(doc(owner, 'calculadora_operacao/festa/aplicacoes/pedido'), { versao: 1, id_evento: 'festa', id_usuario: 'owner', assinatura: 'revisao' });
    executar.set(doc(owner, `tarefa/${tarefaExec}`), { id_evento: 'festa', titulo: 'Comprar arroz', status: 'a_fazer', id_responsavel: 'owner' });
    await assertFails(executar.commit());
    await env.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), 'calculadora_operacao/festa/aplicacoes/pedido'), { versao: 2, id_evento: 'festa', id_usuario: 'owner', assinatura: 'revisao' });
      await setDoc(doc(ctx.firestore(), `tarefa/${tarefaExec}`), { id_evento: 'festa', titulo: 'Comprar arroz', status: 'a_fazer', id_responsavel: 'owner' });
    });
    await assertSucceeds(getDoc(doc(owner, 'calculadora_operacao/festa/aplicacoes/pedido')));
    await assertSucceeds(updateDoc(doc(owner, 'calculadora_operacao/festa'), { execucao: { regras: [], contexto_desatualizado: true } }));
    await assertFails(updateDoc(doc(owner, 'calculadora_operacao/festa'), { execucao: { pedido: 'forjado' } }));
    for (const db of [other, provider, anonymous]) {
      await assertFails(getDoc(doc(db, `tarefa/${tarefaExec}`)));
      await assertFails(getDoc(doc(db, 'calculadora_operacao/festa/aplicacoes/pedido')));
      const negado = writeBatch(db);
      negado.set(doc(db, 'calculadora_operacao/festa/aplicacoes/forjado'), { versao: 1, id_evento: 'festa', id_usuario: 'other' });
      negado.set(doc(db, 'tarefa/calc_exec_festa_forjada'), { id_evento: 'festa', titulo: 'Invadida', status: 'a_fazer', id_responsavel: null });
      await assertFails(negado.commit());
    }
    await assertFails(updateDoc(doc(owner, 'calculadora_operacao/festa/aplicacoes/pedido'), { assinatura: 'substituida' }));
    console.log('Calculadora Firestore rules: OK');
  } finally { await env.cleanup(); }
}
run().catch((error) => { console.error(error); process.exit(1); });
