const assert=require('node:assert/strict'),fs=require('node:fs'),ts=require('typescript');
if(!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST||''))throw Error('Use Firestore local.');
process.env.GCLOUD_PROJECT='demo-financeiro-entrada';
const admin=require('firebase-admin');admin.initializeApp({projectId:'demo-financeiro-entrada'});
require.extensions['.ts']=(m,p)=>m._compile(ts.transpileModule(fs.readFileSync(p,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,p);
const {prepararEntradaAssistente,aplicarEntradaAssistente}=require('../src/services/calculadora/entradaAssistenteService.ts');
async function main(){try{
 const db=admin.firestore(),evento=`financeiro-entrada-${Date.now()}`,uid='financeiro-fixture';
 await db.doc(`evento/${evento}`).set({id_usuario:uid,custo_estimado:2500});
 const proposta=await prepararEntradaAssistente(db,uid,{evento,texto:'Quero confirmar verba alimentar de 1200 reais.',regras:[]},async()=>({resumo:'Fixture sem IA externa',acoes:[{id:'verba',tipo:'verba',valor:1200,evidencia:'Verba explicitamente informada pelo organizador'}],perguntas:[],documento:{}}));
 const comando={evento,id:proposta.id,assinatura:proposta.assinatura,selecionadas:proposta.acoes.map(a=>a.id),conferiu_duplicidade:true};
 await aplicarEntradaAssistente(db,uid,comando);
 const op=(await db.doc(`calculadora_operacao/${evento}`).get()).data(),cfg=op.configuracao_planejamento;
 assert.equal(cfg.verba_alimentacao,1200);assert.equal(cfg.verba_confirmacao.valor,1200);assert.equal(cfg.verba_confirmacao.fonte,'organizador');assert.equal(cfg.verba_confirmacao.confirmado_por,uid);assert.ok(Number.isFinite(Date.parse(cfg.verba_confirmacao.confirmado_em)));
 assert.equal((await aplicarEntradaAssistente(db,uid,comando)).aplicado,false);
 assert.equal((await db.collection('orcamento').where('id_evento','==',evento).get()).size,0);
 await assert.rejects(aplicarEntradaAssistente(db,'outro-organizador',comando));
 console.log('Financeiro: confirmação assistida real no Firestore, origem/data, repetição e ausência de despesa/pagamento OK');
 }finally{await admin.app().delete();}}
main().catch(e=>{console.error(e);process.exitCode=1;});
