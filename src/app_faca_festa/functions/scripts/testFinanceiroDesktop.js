const {spawn}=require('node:child_process'),path=require('node:path');
for(const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST'])if(!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k]||''))throw Error('Use apenas emuladores locais.');
process.env.GCLOUD_PROJECT='demo-financeiro08';
const admin=require('firebase-admin');admin.initializeApp({projectId:'demo-financeiro08'});
async function main(){try{
 const evento=`financeiro-${Date.now()}`,db=admin.firestore();
 for(const uid of ['financeiro-owner','financeiro-other']){await admin.auth().createUser({uid,email:`${uid}@example.test`,password:'TesteLocal123!'});await db.doc(`usuarios/${uid}`).set({tipo:'O',ativo:true});}
 await db.doc(`evento/${evento}`).set({id_evento:evento,id_usuario:'financeiro-owner',nome_evento:'Fixture financeira',id_tipo_evento:'evento_corporativo',local_evento:'Local sintético',data:admin.firestore.Timestamp.now(),custo_estimado:8500,total_convidados:20,total_adultos:20,total_criancas:0,total_bebes:0,ativo:true});
 await db.doc(`orcamento/${evento}-buffet`).set({id_orcamento:`${evento}-buffet`,id_evento:evento,id_solicitante:'financeiro-owner',nome:'Buffet sintético',custo_estimado:6500,status:'fechado',orcamento_fechado:true,data_cadastro:admin.firestore.Timestamp.now()});
 await db.doc(`orcamento/${evento}-buffet/orcamento_gasto/parcial`).set({id_gasto:'parcial',id_orcamento:`${evento}-buffet`,nome:'Despesa sintética',custo:6500,pago:500,data_cadastro:admin.firestore.Timestamp.now()});
 await db.doc(`calculadora_operacao/${evento}`).set({id_evento:evento,id_usuario:'financeiro-owner',versao:1,revisao:1,configuracao_planejamento:{base:'previstos',base_confirmada:true,verba_alimentacao:200}});
 await new Promise((resolve,reject)=>{const c=spawn('cmd.exe',['/d','/s','/c',`flutter test integration_test/financeiro_capacidade_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true --dart-define=FINANCEIRO_QA_EVENTO=${evento}`],{cwd:path.resolve(__dirname,'../..'),stdio:'inherit'});c.on('error',reject);c.on('exit',n=>n===0?resolve():reject(Error(`Windows SDK: ${n}`)));});
 console.log('Financeiro, verba e capacidade: SDK Auth/Firestore reais OK');
 }finally{await admin.app().delete();}}
main().catch(e=>{console.error(e);process.exitCode=1;});
