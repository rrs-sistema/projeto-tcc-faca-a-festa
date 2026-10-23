const {spawn}=require('node:child_process'),path=require('node:path');
const local=/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/;
for(const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST'])if(!local.test(process.env[k]||''))throw Error(`${k} deve apontar para localhost.`);
process.env.GCLOUD_PROJECT='demo-agenda-servicos';
const admin=require('firebase-admin');admin.initializeApp({projectId:'demo-agenda-servicos'});
async function main(){try{
 const evento=`agenda-${Date.now()}`,db=admin.firestore();
 for(const uid of ['agenda-owner','agenda-other']){await admin.auth().createUser({uid,email:`${uid}@example.test`,password:'TesteLocal123!'});await db.doc(`usuarios/${uid}`).set({tipo:'O',ativo:true});}
 await db.doc(`evento/${evento}`).set({id_evento:evento,id_usuario:'agenda-owner',id_tipo_evento:'retiro',nome_evento:'Retiro sintético',data:admin.firestore.Timestamp.fromDate(new Date('2026-10-20T12:00:00Z')),data_fim:admin.firestore.Timestamp.fromDate(new Date('2026-10-21T12:00:00Z')),total_convidados:40,total_adultos:40,total_criancas:0,total_bebes:0,ativo:true});
 for(const tipo of ['almoco','jantar']){const id=`${evento}_${tipo}`;await db.doc(`cardapios/${id}`).set({id_cardapio:id,id_evento:evento,titulo:tipo==='almoco'?'Almoço':'Jantar',escopo:'refeicao',publico_alvo:'todos',ativo:true});await db.doc(`cardapios/${id}/itens/arroz`).set({id_item:'arroz',id_evento:evento,id_cardapio:id,nome:'Arroz',tipo:'comida',publico_alvo:'todos',unidade:'kg',quantidade_final:0,quantidade_sugerida:0,confirmado:false});}
 await db.doc(`calculadora_operacao/${evento}`).set({id_evento:evento,id_usuario:'agenda-owner',versao:1,revisao:1,configuracao_planejamento:{base:'previstos',base_confirmada:true,duracao:8,perfil:'padrao',margem:0}});
 await new Promise((resolve,reject)=>{const child=spawn('cmd.exe',['/d','/s','/c',`flutter test integration_test/agenda_ocorrencias_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true --dart-define=AGENDA_QA_EVENTO=${evento}`],{cwd:path.resolve(__dirname,'../..'),stdio:'inherit'});child.on('error',reject);child.on('exit',c=>c===0?resolve():reject(Error(`SDK Windows: ${c}`)));});
 const op=(await db.doc(`calculadora_operacao/${evento}`).get()).data();if(op.agenda.length!==4)throw Error('Agenda incompleta');console.log('Agenda SDK/Callable reais: OK');
 }finally{await admin.app().delete();}}
main().catch(e=>{console.error(e);process.exitCode=1;});
