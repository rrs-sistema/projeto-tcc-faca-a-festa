const assert = require('node:assert/strict');
const fs = require('node:fs'), path = require('node:path');
for (const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Teste exige emuladores locais.');
}
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== 'demo-migracao11') throw Error('Projeto inesperado.');
process.env.GCLOUD_PROJECT = 'demo-migracao11';
const admin = require('firebase-admin');
admin.initializeApp({projectId:process.env.GCLOUD_PROJECT});
const db = admin.firestore(), projeto = process.env.GCLOUD_PROJECT;
const host = '127.0.0.1:5001';
async function entrar(uid) {
  await admin.auth().createUser({uid,email:`${uid}@example.test`,password:'DemoSintetico123!'});
  const r = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`,{
    method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:`${uid}@example.test`,password:'DemoSintetico123!',returnSecureToken:true})});
  const dados = await r.json(); assert.ok(dados.idToken); return dados.idToken;
}
async function chamar(funcao,token,data,erro) {
  const r = await fetch(`http://${host}/${projeto}/southamerica-east1/${funcao}`,{
    method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({data})});
  const resposta = await r.json();
  if (erro) { assert.equal(resposta.error?.status,erro); return; }
  assert.equal(resposta.error,undefined,JSON.stringify(resposta.error));
  return resposta.result;
}
function referencia(versao = 1) {
  return {schema:1,motor_minimo:1,id:'demo_porcoes',versao,tipo:'porcao',nome:'Alimento sintético',aliases:['Alimento sintético'],
    alimento_receita:'Alimento sintético',servicos:['lanche'],formatos:['buffet'],periodos:['qualquer'],publicos:['todos'],obtencoes:['servir'],
    papel:'outro',unidade:'quilo',estado_consumo:'pronto',estado_compra:'pronto',contexto:'Contexto sintético',limitacoes:'Somente fixture',fonte:'codigo:fixture-demo',
    revisao_editorial:'Sem alegação de verificação externa',minimo:.1,maximo:.3,padrao:.2,aprovado_por:null,aprovado_em:null};
}
async function main() {
  try {
    const tokens = {};
    for (const [uid,tipo,autorizado] of [['admin11','A',true],['owner11','O',false],['other11','O',false],['admin-sem-papel11','A',false]]) {
      tokens[uid] = await entrar(uid);
      await db.doc(`usuarios/${uid}`).set({tipo,ativo:true,migracao_planejamento:autorizado});
    }
    const fontes = {
      'evento/legado11':{id_evento:'legado11',id_usuario:'owner11',total_convidados:40,data:admin.firestore.Timestamp.fromDate(new Date('2026-10-20T12:00:00Z'))},
      'cardapios/menu11':{id_cardapio:'menu11',id_evento:'legado11',titulo:'Fixture',ativo:true},
      'cardapios/menu11/itens/item11':{nome:'Receita privada sintética',quantidade_final:3,confirmado:true},
      'calculadora_operacao/legado11':{id_evento:'legado11',id_usuario:'owner11',versao:1,revisao:1,execucao:{regras:[{id:'legada',premissas:{}}]},lotes:{},refeicoes:{}},
      'calculadora_festa/hist11':{id_evento:'legado11',id_usuario:'owner11',status_simulacao:'aprovada',total_convidados:40,custo_total_estimado:120},
      'calculadora_festa/hist11/itens/item11':{quantidade:3,preco:40},
      'orcamento/financeiro11':{id_evento:'legado11',id_solicitante:'owner11',custo_estimado:500},
      'orcamento/financeiro11/orcamento_gasto/pago11':{custo:500,pago:250},
      'contratos/contrato11':{id_evento:'legado11',valor:500,status:'assinado'},
      'calculadora_preferencias/owner11':{versao:1,receitas:[{nome:'Receita privada sintética',rendimento:2}]},
    };
    for (const [p,d] of Object.entries(fontes)) await db.doc(p).set(d);
    const capturar = async () => Object.fromEntries(await Promise.all(Object.keys(fontes).map(async p => [p,(await db.doc(p).get()).data()])));
    const antes = await capturar();
    const migrar = (token,acao,assinatura,erro) => chamar('migrarPlanejamentoCalculadora',token,{projeto,evento:'legado11',acao,...assinatura ? {assinatura} : {}},erro);
    await migrar(tokens.owner11,'inspecionar',null,'PERMISSION_DENIED');
    await migrar(tokens.other11,'aplicar','qualquer','PERMISSION_DENIED');
    await migrar(tokens['admin-sem-papel11'],'inspecionar',null,'PERMISSION_DENIED');
    const a = await migrar(tokens.admin11,'inspecionar');
    assert.ok(a.hipoteses.includes('distribuicao_etaria_desconhecida'));
    assert.equal((await db.collection('planejamento_compatibilidade').get()).size,0);
    assert.deepEqual(await capturar(),antes);
    const aplicado = await migrar(tokens.admin11,'aplicar',a.assinatura);
    assert.equal(aplicado.alterado,true);
    const ref = db.doc('planejamento_compatibilidade/legado11'), primeiro = (await ref.get()).data();
    assert.equal((await migrar(tokens.admin11,'aplicar',a.assinatura)).alterado,false);
    assert.deepEqual((await ref.get()).data(),primeiro);
    assert.equal((await ref.collection('inspecoes').get()).size,1);
    assert.deepEqual(await capturar(),antes);
    assert.equal((await migrar(tokens.admin11,'reverter',a.assinatura)).alterado,true);
    const revertido = (await ref.get()).data();
    assert.equal(revertido.selecao_ativa,false);
    assert.equal((await migrar(tokens.admin11,'reverter',a.assinatura)).alterado,false);
    assert.deepEqual((await ref.get()).data(),revertido);
    assert.deepEqual(await capturar(),antes);
    await db.doc('evento/legado11').update({total_convidados:41});
    await migrar(tokens.admin11,'aplicar',a.assinatura,'ABORTED');
    await db.doc('evento/legado11').update({total_convidados:40});
    const r = referencia();
    const editar = (token,acao,ref = r,esperada = 0,pedido = acao) => chamar('editarCatalogoCalculadora',token,{referencia:ref,versao_esperada:esperada,pedido,acao});
    await chamar('editarCatalogoCalculadora',tokens.owner11,{referencia:r,versao_esperada:0,pedido:'negado',acao:'publicar'},'PERMISSION_DENIED');
    await chamar('editarCatalogoCalculadora',tokens.admin11,{referencia:r,versao_esperada:0,pedido:'sem-aprovacao',acao:'publicar'},'FAILED_PRECONDITION');
    await editar(tokens.admin11,'rascunho');
    assert.equal((await db.doc('calculadora_itens_base/demo_porcoes').get()).data().referencia_contextual,undefined);
    await editar(tokens.admin11,'aprovar');
    assert.equal((await db.doc('calculadora_itens_base/demo_porcoes').get()).data().governanca_contextual.estado,'aprovada');
    await editar(tokens.admin11,'publicar');
    const versao1 = (await db.doc('calculadora_itens_base/demo_porcoes/versoes_contextuais/1').get()).data();
    await editar(tokens.admin11,'publicar'); // resposta perdida/repetição
    const r2 = referencia(2);
    await editar(tokens.admin11,'aprovar',r2,1,'aprovar2');
    await editar(tokens.admin11,'publicar',r2,1,'publicar2');
    assert.equal((await db.doc('calculadora_itens_base/demo_porcoes/estados_contextuais/1').get()).data().estado,'substituida');
    const selecionar = data => chamar('editarCatalogoCalculadora',tokens.admin11,{id:r.id,versao_esperada:2,...data});
    await selecionar({acao:'selecionar',versao_alvo:1,pedido:'voltar1'});
    assert.equal((await db.doc('calculadora_itens_base/demo_porcoes').get()).data().referencia_contextual.versao,1);
    await selecionar({acao:'desativar',pedido:'off'});
    const desativado = (await db.doc('calculadora_itens_base/demo_porcoes').get()).data();
    await selecionar({acao:'desativar',pedido:'off'});
    assert.deepEqual((await db.doc('calculadora_itens_base/demo_porcoes').get()).data(),desativado);
    assert.equal(desativado.referencia_contextual,null);
    assert.deepEqual((await db.doc('calculadora_itens_base/demo_porcoes/versoes_contextuais/1').get()).data(),versao1);
    assert.deepEqual(await capturar(),antes);
    // Exercita o CLI real: relatório de inspeção primeiro, aplicação/repetição depois.
    const cli = require('./migrarPlanejamento');
    const dir = path.resolve(__dirname,'../../.dart_tool/p11-cli');fs.mkdirSync(dir,{recursive:true});
    const run = Date.now(), inspecao = path.join(dir,`inspecao-${run}.json`);
    await cli.executar({projeto,eventos:'legado11',relatorio:inspecao},tokens.admin11,host);
    await cli.executar({projeto,eventos:'legado11',acao:'aplicar',inspecao,relatorio:path.join(dir,`aplicacao-${run}.json`)},tokens.admin11,host);
    await db.doc('calculadora_operacao/legado11').update({versao:2});
    await migrar(tokens.admin11,'inspecionar',null,'FAILED_PRECONDITION');
    await migrar(tokens.admin11,'reverter',a.assinatura);
    assert.equal((await ref.get()).data().selecao_ativa,false);
    assert.equal((await db.doc('calculadora_operacao/legado11').get()).data().versao,2);
    await db.doc('calculadora_operacao/legado11').update({versao:1});
    assert.deepEqual(await capturar(),antes);
    await assert.rejects(() => cli.executar({projeto:'producao',eventos:'legado11'},tokens.admin11,host));
    await assert.rejects(() => cli.executar({projeto,eventos:'legado11'},tokens.admin11,'example.com:5001'));
    console.log('Migração/CLI: dry-run sem escrita, aplicação dupla, conflito, reversão dupla, isolamento e preservação integral OK.');
    console.log('Catálogo: aprovação, publicação, substituição, seleção anterior, desativação e repetição com Auth/Firestore/Functions reais OK.');
  } finally { await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
