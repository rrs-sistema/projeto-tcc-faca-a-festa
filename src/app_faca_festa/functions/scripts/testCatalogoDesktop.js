const {spawn}=require('node:child_process'),path=require('node:path');
for(const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST'])if(!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k]||''))throw Error(`${k} exige localhost.`);
process.env.GCLOUD_PROJECT='demo-catalogo-contextual';
const admin=require('firebase-admin');admin.initializeApp({projectId:'demo-catalogo-contextual'});
async function main(){try{
 const evento=`catalogo-${Date.now()}`,db=admin.firestore();
 for(const [uid,tipo] of [['catalogo-admin','A'],['catalogo-owner','O']]){await admin.auth().createUser({uid,email:`${uid}@example.test`,password:'TesteLocal123!'});await db.doc(`usuarios/${uid}`).set({tipo,ativo:true});}
 await db.doc(`evento/${evento}`).set({id_evento:evento,id_usuario:'catalogo-owner',nome_evento:'Corporativo sintético',id_tipo_evento:'evento_corporativo',total_convidados:40,total_adultos:40,total_criancas:0,total_bebes:0,ativo:true});
 const menu=`${evento}_menu`;
 await db.doc(`cardapios/${menu}`).set({id_cardapio:menu,id_evento:evento,titulo:'Serviço sintético',ativo:true,escopo:'refeicao',publico_alvo:'todos'});
 await db.doc(`cardapios/${menu}/itens/item`).set({id_item:'item',id_evento:evento,id_cardapio:menu,nome:'Alimento sintético',tipo:'comida',publico_alvo:'todos',unidade:'kg',quantidade_final:0,quantidade_sugerida:0,confirmado:false});
 await db.doc(`calculadora_operacao/${evento}`).set({id_evento:evento,id_usuario:'catalogo-owner',versao:1,revisao:1,configuracao_planejamento:{base:'previstos',base_confirmada:true}});
 await new Promise((resolve,reject)=>{const c=spawn('cmd.exe',['/d','/s','/c',`flutter test integration_test/catalogo_contextual_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true --dart-define=CATALOGO_QA_EVENTO=${evento}`],{cwd:path.resolve(__dirname,'../..'),stdio:'inherit'});c.on('error',reject);c.on('exit',n=>n===0?resolve():reject(Error(`SDK Windows: ${n}`)));});
 console.log('Catálogo SDK/Callable reais: OK');
 }finally{await admin.app().delete();}}
main().catch(e=>{console.error(e);process.exitCode=1;});
