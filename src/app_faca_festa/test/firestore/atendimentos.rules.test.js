require("../../functions/scripts/exigirEmuladorDemo").exigirEmuladorDemo("demo-chat-privado");
const fs = require('fs');
const assert = require('node:assert/strict');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');

// Compat contexts expose the same SDK used by the existing rules suites.
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
(async () => {
 const env = await initializeTestEnvironment({projectId:'demo-chat-privado',firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync('firestore.rules','utf8')}});
 let checks=0;
 const ok=async p=>{await assertSucceeds(p);checks++};
 const no=async p=>{await assertFails(p);checks++};
 const db=id=>env.authenticatedContext(id).firestore();
 const path='cotacao/a/fornecedores/fa/mensagens';
 const msg=(id,extra={})=>({id_usuario:id,nome_usuario:id,mensagem:'Operação sintética',enviado_em:firebase.firestore.FieldValue.serverTimestamp(),lido:false,...extra});
 try {
 await env.clearFirestore();
 await env.withSecurityRulesDisabled(async c=>{
 const d=c.firestore();
 for(const id of ['ca','cb','fa','fb','outro','admin']) await d.doc('usuarios/'+id).set({tipo:id==='admin'?'A':id.startsWith('f')?'F':'O',ativo:true});
 for(const [cot,cliente,fornecedor] of [['a','ca','fa'],['b','cb','fb']]) {
 await d.doc('cotacao/'+cot).set({id_usuario_solicitante:cliente,id_evento:'evento-compartilhado',status:'concluida'});
 await d.doc(`cotacao/${cot}/fornecedores/${fornecedor}`).set({id_fornecedor:fornecedor,status:'ganhouCotacao'});
 }
 await d.doc(path+'/s').set({id_usuario:'sistema',nome_usuario:'Sistema',mensagem:'Contratação confirmada',enviado_em:new Date(2026,0,1),lido:false,sistema:true});
 });
 for(const id of ['ca','fa','cb','fb','outro','admin']) {
 const d=db(id), participante=['ca','fa'].includes(id);
 await (participante?ok:no)(d.doc(path+'/s').get());
 await (participante?ok:no)(d.collection(path).orderBy('enviado_em').get());
 await no(d.collectionGroup('mensagens').get());
 await no(d.collectionGroup('mensagens').where('id_usuario','==','ca').get());
 await no(d.doc(path+'/s').update({mensagem:'Adulterada'}));
 await no(d.doc(path+'/s').delete());
 await (participante?ok:no)(d.collection(path).add(msg(id)));
 await no(d.collection(path).add(msg('ca',{sistema:true})));
 await no(d.collection(path).add(msg(id==='ca'?'fa':'ca')));
 await no(d.doc('cotacao/a').update({status:'pendente'}));
 await no(d.doc('cotacao/a/fornecedores/fa').update({status:'aguardando'}));
 await no(d.doc('cotacao/a').delete());
 await no(d.doc('cotacao/a/fornecedores/fa').delete());
 }
 const a=db('ca'), f=db('fa');
 // Gravação real da função de sistema via Admin SDK, apenas no emulador.
 const admin = require('../../functions/node_modules/firebase-admin');
 const app = admin.initializeApp({projectId:'demo-chat-privado'}, 'chat-test');
 const {gravarMensagemSistema} = require('../../functions/lib/functions/cotacao/mensagensSistemaCotacao');
 await gravarMensagemSistema(app.firestore(), 'a', 'fa', 'Mensagem sintética do backend');
 await ok(a.collection(path).where('sistema','==',true).get());
 await no(db('cb').collection(path).where('sistema','==',true).get());
 await app.delete();
 await ok(db('cb').doc('cotacao/b/fornecedores/fb/mensagens/b').set(msg('cb')));
 await ok(db('fb').doc('cotacao/b/fornecedores/fb/mensagens/b').get());
 await no(a.doc('cotacao/b/fornecedores/fb/mensagens/b').get());
 await no(f.doc('cotacao/b/fornecedores/fb/mensagens/b').get());
 await ok(a.collection(path).add(msg('ca',{mensagem:'x'.repeat(2000),nome_usuario:'x'.repeat(200)})));
 await ok(a.doc(path+'/cliente').set(msg('ca')));
 const before=(await f.doc(path+'/cliente').get()).data();
 await no(a.doc(path+'/cliente').update({lido:true}));
 await no(f.doc(path+'/cliente').update({lido:true,mensagem:'Outra'}));
 await no(f.doc(path+'/cliente').update({id_usuario:'fa'}));
 await no(f.doc(path+'/cliente').update({enviado_em:new Date()}));
 await ok(f.doc(path+'/cliente').update({lido:true}));
 const after=(await a.doc(path+'/cliente').get()).data();
 assert.deepEqual(after,{...before,lido:true}); checks++;
 await no(f.doc(path+'/cliente').update({lido:false}));
 await ok(f.doc(path+'/fornecedor').set(msg('fa')));
 await ok(a.doc(path+'/fornecedor').update({lido:true}));
 await ok(a.doc(path+'/s').update({lido:true}));
 await no(a.collection(path).add(msg('ca',{mensagem:''})));
 await no(a.collection(path).add(msg('ca',{mensagem:'x'.repeat(2001)})));
 await no(a.collection(path).add(msg('ca',{nome_usuario:'x'.repeat(201)})));
 await no(a.collection(path).add(msg('ca',{enviado_em:new Date(2020,0,1)})));
 await no(a.collection(path).add(msg('ca',{lido:true})));
 await no(a.collection(path).add(msg('ca',{anexo:'arquivo'})));
 await no(env.unauthenticatedContext().firestore().doc(path+'/s').get());
 await ok(f.collectionGroup('fornecedores').where('id_fornecedor','==','fa').get());
 await no(db('fb').collectionGroup('fornecedores').where('id_fornecedor','==','fa').get());

 const caminhoAoVivo = path + '/ao-vivo';
 let pararEscuta, timeout;
 try {
   await new Promise((resolve, reject) => {
     timeout = setTimeout(() => reject(new Error('Escuta do chat não recebeu o envio e a leitura.')), 10000);
     let fase = 'aguardando';
     pararEscuta = f.collection(path).onSnapshot({includeMetadataChanges: true}, snapshot => {
       if (snapshot.metadata.fromCache || snapshot.metadata.hasPendingWrites) return;
       const mensagem = snapshot.docs.find(doc => doc.id === 'ao-vivo')?.data();
       if (fase === 'aguardando' && !mensagem) {
         fase = 'enviado';
         a.doc(caminhoAoVivo).set(msg('ca')).catch(reject);
       } else if (fase === 'enviado' && mensagem?.id_usuario === 'ca' && mensagem.lido === false) {
         fase = 'lido';
         f.doc(caminhoAoVivo).update({lido: true}).catch(reject);
       } else if (fase === 'lido' && mensagem?.lido === true) {
         resolve();
       }
     }, reject);
   });
   checks++;
 } finally {
   clearTimeout(timeout);
   pararEscuta?.();
 }

 for (const status of ['cancelada','recusado','perdeuCotacao']) {
 await env.withSecurityRulesDisabled(c=>c.firestore().doc('cotacao/a/fornecedores/fa').update({status}));
 await no(a.collection(path).add(msg('ca'))); await no(f.collection(path).add(msg('fa')));
 await ok(a.doc(path+'/s').get());
 }
 await env.withSecurityRulesDisabled(c=>c.firestore().doc('cotacao/a').update({status:'cancelada'}));
 await no(a.collection(path).add(msg('ca')));
 await no(f.collection(path).add(msg('fa')));
 console.log(`PASS: ${checks} verificações de regras, isolamento, integridade, sobreposição, collectionGroup e estados.`);
 } finally {await env.cleanup();}
})().catch(e=>{console.error(e);process.exitCode=1});
