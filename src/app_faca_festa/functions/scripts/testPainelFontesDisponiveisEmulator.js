require('./exigirEmuladorDemo').exigirEmuladorDemo('demo-painel-fontes');
const fs=require('node:fs'),assert=require('node:assert/strict');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('../../node_modules/@firebase/rules-unit-testing');
(async()=>{
 const env=await initializeTestEnvironment({projectId:'demo-painel-fontes',firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync('firestore.rules','utf8')}});
 try {
 await env.withSecurityRulesDisabled(async c=>{
  const d=c.firestore();for(const[u,tipo]of[['f','F'],['g','F'],['c','O'],['x','O'],['a','A']])await d.doc('usuarios/'+u).set({tipo,ativo:true});
  for(const uid of ['f','g']){
   await d.doc('fornecedor/'+uid).set({media_avaliacoes:4.4,total_avaliacoes:45});
   await d.doc('cotacao/q'+uid).set({id_usuario_solicitante:uid==='f'?'c':'x',id_evento:'e'+uid,status:'pendente',data_envio:new Date('2026-10-25T12:00:00Z')});
   await d.doc('cotacao/q'+uid+'/fornecedores/'+uid).set({id_fornecedor:uid,status:'aguardando'});
   await d.doc('cotacao/q'+uid+'/fornecedores/'+uid+'/mensagens/m').set({id_usuario:uid==='f'?'c':'x',mensagem:'Sintética',lido:false});
   await d.doc('orcamento/o'+uid).set({id_fornecedor:uid,id_solicitante:uid==='f'?'c':'x',id_evento:'e'+uid,status:'fechado'});
   await d.doc('fornecedor_servico/s'+uid).set({id_fornecedor:uid,ativo:true});
   await d.doc('fornecedor/'+uid+'/estoque_itens/i').set({nome:'Material privado',quantidade_total:2});
  }
 });
 let n=0;
 for(const uid of ['f','g']){
  const d=env.authenticatedContext(uid).firestore();
  const ps=await assertSucceeds(d.collectionGroup('fornecedores').where('id_fornecedor','==',uid).get());n++;
  assert.equal(ps.size,1);for(const p of ps.docs){await assertSucceeds(p.ref.parent.parent.get());await assertSucceeds(p.ref.collection('mensagens').get());await assertSucceeds(p.ref.collection('propostas').get());n+=3;}
  assert.equal((await assertSucceeds(d.collection('orcamento').where('id_fornecedor','==',uid).get())).size,1);n++;
  assert.equal((await assertSucceeds(d.collection('fornecedor_servico').where('id_fornecedor','==',uid).get())).size,1);n++;
  await assertSucceeds(d.doc('fornecedor/'+uid).get());n++;
  assert.equal((await assertSucceeds(d.collection('fornecedor/'+uid+'/estoque_itens').get())).size,1);n++;
 }
 for(const uid of ['g','x','a']){
  const d=env.authenticatedContext(uid).firestore();
  await assertFails(d.collectionGroup('fornecedores').where('id_fornecedor','==','f').get());n++;
  await assertFails(d.collection('cotacao/qf/fornecedores/f/mensagens').get());n++;
  await assertFails(d.collection('fornecedor/f/estoque_itens').get());n++;
 }
 console.log('PASS '+n+' verificações reais das consultas independentes, sem leitura global de mensagens nem acesso privado de terceiros.');
 }finally{await env.cleanup();}
})().catch(e=>{console.error(e);process.exitCode=1;});
