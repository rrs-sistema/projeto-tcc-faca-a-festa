const {spawn}=require('node:child_process'),path=require('node:path');
for(const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST'])if(!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k]||''))throw Error(`${k} exige localhost.`);
process.env.GCLOUD_PROJECT='demo-planejador-hibrido';
const admin=require('firebase-admin');admin.initializeApp({projectId:'demo-planejador-hibrido'});
async function main(){try{
 const evento=`planejador-${Date.now()}`,db=admin.firestore();
 for(const [uid,tipo] of [['planejador-admin','A'],['planejador-owner','O']]){await admin.auth().createUser({uid,email:`${uid}@example.test`,password:'TesteLocal123!'});await db.doc(`usuarios/${uid}`).set({tipo,ativo:true});}
 await db.doc(`evento/${evento}`).set({id_evento:evento,id_usuario:'planejador-owner',nome_evento:'Corporativo sintético',id_tipo_evento:'evento_corporativo',total_convidados:40,total_adultos:40,total_criancas:0,total_bebes:0,ativo:true});
 const menu=`${evento}_menu`;
 await db.doc(`cardapios/${menu}`).set({id_cardapio:menu,id_evento:evento,titulo:'Serviço sintético',ativo:true,escopo:'refeicao',publico_alvo:'todos'});
 await db.doc(`cardapios/${menu}/itens/item`).set({id_item:'item',id_evento:evento,id_cardapio:menu,nome:'Alimento sintético',tipo:'comida',publico_alvo:'todos',unidade:'kg',quantidade_final:0,quantidade_sugerida:0,confirmado:false});
 await db.doc(`calculadora_operacao/${evento}`).set({id_evento:evento,id_usuario:'planejador-owner',versao:1,revisao:1,configuracao_planejamento:{base:'previstos',base_confirmada:true}});
 const r={schema:1,motor_minimo:1,id:'teste_porcoes',versao:1,tipo:'porcao',nome:'Alimento sintético',aliases:['Alimento sintético'],alimento_receita:'Receita sintética',servicos:['lanche'],formatos:['buffet'],periodos:['qualquer'],publicos:['todos'],obtencoes:['servir','pronto','preparar'],papel:'outro',unidade:'quilo',estado_consumo:'pronto',estado_compra:'pronto',contexto:'Fixture sintética de teste, sem recomendação real.',limitacoes:'Somente cenário sintético.',fonte:'https://example.test/referencia',verificado_em:null,revisao_editorial:'Fixture sintética.',minimo:.1,maximo:.1,padrao:.1,aprovado_por:'admin-qa',aprovado_em:'2026-10-19T12:00:00Z'};
 await db.doc('calculadora_itens_base/teste_porcoes').set({ativo:true,referencia_contextual:r});
 await db.doc('calculadora_itens_base/teste_porcoes/versoes_contextuais/1').set(r);
 await new Promise((resolve,reject)=>{const c=spawn('cmd.exe',['/d','/s','/c',`flutter test integration_test/planejador_hibrido_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true --dart-define=PLANEJADOR_QA_EVENTO=${evento}`],{cwd:path.resolve(__dirname,'../..'),stdio:'inherit'});c.on('error',reject);c.on('exit',n=>n===0?resolve():reject(Error(`SDK Windows: ${n}`)));});
 const fs=require('node:fs'),ts=require('typescript'),assert=require('node:assert/strict');
 require.extensions['.ts']=(m,p)=>m._compile(ts.transpileModule(fs.readFileSync(p,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,p);
 const {sugerirCandidatosPlanejador,confirmarPlanejador}=require('../src/services/calculadora/planejadorHibridoService.ts');
 const {lerFontesEntrada}=require('../src/services/calculadora/entradaAssistenteService.ts');
 const {normalizarFonte}=require('../src/services/calculadora/executarPlanoService.ts');
 // Modelo substituído só nesta prova de contrato: Firestore e serviço de produção reais.
 for(const saida of [{candidatos:[{id_item:'item',referencia_id:'inventada',versao:1}]},{candidatos:[{id_item:'item',referencia_id:r.id,versao:1,quantidade:999}]}]){
  const resultado=await sugerirCandidatosPlanejador(db,'planejador-owner',{evento,cardapio:menu,texto:'Alimento sintético'},async()=>saida);
  assert.equal(resultado.origem,'parser_local_limitado');
 }
 const observado=`${evento}-observado`,destino=`${observado}_menu`;
 await db.doc(`evento/${observado}`).set({id_usuario:'planejador-owner',total_convidados:40,total_adultos:40,total_criancas:0,total_bebes:0});
 await db.doc(`cardapios/${destino}`).set({id_evento:observado,ativo:true,titulo:'Lanche',escopo:'refeicao'});
 await db.doc(`cardapios/${destino}/itens/item`).set({nome:'Alimento sintético',unidade:'kg',tipo:'comida',publico_alvo:'todos',confirmado:false});
 const dimensoes={servico:'lanche',formato:'buffet',duracao_minutos:null,hora_local:null,infraestrutura:{}};
 await db.doc(`calculadora_operacao/${observado}`).set({versao:1,revisao:1,id_evento:observado,id_usuario:'planejador-owner',configuracao_planejamento:{base:'previstos',base_confirmada:true},refeicoes:{[destino]:{servico:'lanche'}},agenda:[{id:destino,id_cardapio:destino,id_evento:observado,id_modelo:'modelo_qa',titulo:'Lanche',formato:'buffet',data_local:null,hora_local:null,fuso:null,duracao_minutos:null}]});
 const contexto=JSON.stringify(['contexto_v3',['todos'],[],'lanche','congresso',[],'receita_qa','alimento_sintetico','todos','kg','pronto','outro',1,4,1,1,1,[],{servico_planejador_v1:dimensoes}]);
 const baseRegra={id:'historica',nome:'Alimento sintético',categoria:'comida',tipo:'comida',publico:'todos',unidade:'quilo',consumo:.2,preco:0,selecionado:true,premissas:{receita:'Receita QA',estado:'pronto',estado_compra:'pronto',papel_na_refeicao:'outro',numero_servicos:1,peso_crianca:1,peso_bebe:1,rendimento:1}};
 const eventos=['medido1','medido2','medido3'];
 for(const e of eventos)await db.doc(`calculadora_festa/${e}`).set({id_usuario:'planejador-owner',consumo_observado:{item:{id_evento:e,contexto,data_registro:new Date().toISOString(),data_consumo:new Date().toISOString(),adultos:40,criancas:0,bebes:0,faltou:false,disponibilizado_pronto:4,sobra_pronta:0,desperdicio_pronto:.2,regra:baseRegra}}});
 const fontes=await db.runTransaction(tx=>lerFontesEntrada(db,tx,observado,'planejador-owner',true));
 const regra={...baseRegra,id:`menu_${destino}_item`,consumo:.1,premissas:{...baseRegra.premissas,id_evento:observado,id_cardapio:destino,id_item_cardapio:'item',origem:'consumo_observado',contexto_consumo:contexto,eventos_origem:eventos,revisada_pelo_organizador:true,ajustar_por_duracao:false,ajustar_por_perfil:false,consumo_min:null,consumo_max:null}};
 const entrada={evento:observado,cardapio:destino,pedido:'adocao',revisao:1,fontes:normalizarFonte(fontes),decisao:{versao:1,objetivo:'manter_receitas',infraestrutura:{},respostas:{objetivo:'manter_receitas',origem_item:'observado'},assinatura_material:'a'.repeat(64)},regras:[regra]};
 await assert.rejects(confirmarPlanejador(db,'planejador-owner',{...entrada,regras:[{...regra,consumo:99}]}));
 await db.doc('calculadora_festa/medido3').update({'consumo_observado.item.adultos':30,'consumo_observado.item.criancas':10});
 await assert.rejects(confirmarPlanejador(db,'planejador-owner',entrada));
 await db.doc('calculadora_festa/medido3').update({'consumo_observado.item.adultos':40,'consumo_observado.item.criancas':0});
 const aplicado=await confirmarPlanejador(db,'planejador-owner',entrada);assert.equal(aplicado.execucao.regras[0].consumo,.1);
 assert.equal((await db.doc(`cardapios/${destino}/itens/item`).get()).data().confirmado,false);
 console.log('Planejador Firestore real: IA inválida, mediana adulterada, público incompatível e adoção verificável OK');
 console.log('Planejador SDK/Callable reais: OK');
 }finally{await admin.app().delete();}}
main().catch(e=>{console.error(e);process.exitCode=1;});
