require("./exigirEmuladorDemo").exigirEmuladorDemo("demo-jornada-atendimentos");
const assert=require('node:assert/strict'),fs=require('fs');
if(!process.env.FIRESTORE_EMULATOR_HOST)throw Error('Somente emulador.');process.env.GCLOUD_PROJECT='demo-jornada-atendimentos';
const {admin}=require('../lib/shared/firebaseAdmin'),db=admin.firestore();
const {responderCotacao:R}=require('../lib/functions/cotacao/responderCotacao');
const {fecharCotacao:F}=require('../lib/functions/cotacao/fecharCotacao');
const {cancelarCotacao:C}=require('../lib/functions/cotacao/cancelarCotacao');
const {consultarJornadaAtendimentoFn:G,movimentarComercialJornadaFn:M,executarJornadaAtendimentoFn:E,comercialLegado,proximaAcaoJornada}=require('../lib/services/cotacao/jornadaAtendimentoService');
const {abrirCasoMediacaoParteFn:MED}=require('../lib/functions/financeiro/comandosAcompanhamentoPartes');
const {registrarAvaliacaoVerificada:AV}=require('../lib/services/avaliacoes/avaliacaoVerificadaService');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('../../node_modules/@firebase/rules-unit-testing');let env;
const call=(fn,uid,data)=>fn.run({auth:uid?{uid,token:{}}:undefined,data});
const futuro=()=>new Date(Date.now()+30*86400000).toISOString();
const proposta=(cot='q',extra={})=>({idCotacao:cot,idFornecedor:'f',aceitou:true,valorBrutoCentavos:200000,descontoCentavos:10000,validade:futuro(),prazoEntrega:futuro(),escopo:'Buffet para convidados conforme escopo aprovado',condicaoPagamento:'Sinal e saldo conforme prestação',versaoEsperada:0,chave:'prop-'+cot,...extra});
async function seed(cot){await db.doc('cotacao/'+cot).set({id_evento:'ev',id_usuario_solicitante:'c',nome_usuario_solicitante:'Cliente autorizado',categoria_nome:'Buffet',observacao:'Escopo compartilhado',status:'pendente',valor_estimado_total:999999,data_limite_resposta:admin.firestore.Timestamp.fromDate(new Date(futuro()))});for(const f of ['f','g']){await db.doc(`cotacao/${cot}/fornecedores/${f}`).set({id_fornecedor:f,status:'pendente'});await db.doc(`cotacao/${cot}/fornecedores/${f}/servicos/s`).set({id_produto_servico:'s',nome_produto_servico:'Buffet sintético',quantidade:20,valor_estimado:100});}}
async function get(cot='q',uid='f'){return call(G,uid,{idCotacao:cot,idFornecedor:'f'});}
async function contratar(cot){await call(R,'f',proposta(cot));const p=(await get(cot)).proposta;return call(F,'c',{idCotacao:cot,idFornecedor:'f',versaoProposta:p.versao,assinaturaProposta:p.assinatura});}
(async()=>{
 for(const [u,t]of[['c','O'],['f','F'],['g','F'],['x','O'],['admin','A']])await db.doc('usuarios/'+u).set({tipo:t,ativo:true,nome:u});
 await db.doc('fornecedor/f').set({razao_social:'Empresa sintética'});await db.doc('fornecedor/g').set({razao_social:'Concorrente não compartilhado'});
 await db.doc('evento/ev').set({id_usuario:'c',data:admin.firestore.Timestamp.fromDate(new Date(futuro())),local_evento:'Local autorizado',orcamento_global:987654,custos_privados:'NÃO EXPOR'});
 assert.equal(comercialLegado({status:'concluida'}),'ganho');assert.equal(comercialLegado({status:'perdeuCotacao'}),'perdido');assert.equal(proximaAcaoJornada('perdido','aceito').responsavel,null);
 await seed('q');assert.equal((await get()).estadoComercial,'nova_solicitacao');assert.equal((await get()).estadoExecucao,null);
 for(const uid of ['x','g','admin',null])await assert.rejects(()=>get('q',uid));
 await assert.rejects(()=>call(R,'c',proposta()),e=>e.code==='permission-denied');await assert.rejects(()=>call(R,'g',proposta()),e=>e.code==='permission-denied');
 for(const extra of [{valorBrutoCentavos:1.5},{descontoCentavos:200000},{validade:'ontem'},{escopo:''},{validade:new Date(0).toISOString()}])await assert.rejects(()=>call(R,'f',proposta('q',extra)));
 const p1=proposta();const rr=await Promise.all(Array.from({length:6},()=>call(R,'f',p1)));assert.equal(rr.filter(r=>!r.idempotente).length,1);
 await assert.rejects(()=>call(R,'f',{...p1,valorBrutoCentavos:300000}),e=>e.code==='already-exists');
 const primeira=(await get()).proposta;assert.equal(primeira.liquidoCentavos,190000);
 await call(M,'c',{idCotacao:'q',idFornecedor:'f',acao:'negociar',descricao:'Rever horário e condições',prazoRetorno:futuro(),chave:'negociacao'});assert.equal((await get()).estadoComercial,'negociacao');assert.equal((await get()).proxima.responsavel,'fornecedor');
 const revisoes=await Promise.allSettled([1,2].map(i=>call(R,'f',{...p1,chave:'revisao-'+i,versaoEsperada:1,valorBrutoCentavos:250000+i*10000})));assert.equal(revisoes.filter(r=>r.status==='fulfilled').length,1);if(revisoes.find(r=>r.status==='rejected').reason.code!=='aborted')console.error(revisoes.find(r=>r.status==='rejected').reason);assert.equal(revisoes.find(r=>r.status==='rejected').reason.code,'aborted');
 let j=await get();assert.equal(j.proposta.versao,2);assert.equal(j.propostas.length,2);assert.equal(j.propostas[0].liquidoCentavos,190000);
 await assert.rejects(()=>call(F,'c',{idCotacao:'q',idFornecedor:'f',versaoProposta:1,assinaturaProposta:primeira.assinatura}),e=>e.code==='aborted');
 const fechar={idCotacao:'q',idFornecedor:'f',versaoProposta:2,assinaturaProposta:j.proposta.assinatura};
 await assert.rejects(()=>call(F,'f',fechar),e=>e.code==='permission-denied');await assert.rejects(()=>call(F,'x',{...fechar,idSolicitante:'c'}),e=>e.code==='permission-denied');
 const confirms=await Promise.all(Array.from({length:6},()=>call(F,'c',fechar)));assert.equal(new Set(confirms.map(r=>r.idOrcamento)).size,1);assert.equal(confirms.filter(r=>!r.idempotente).length,1);
 const id=confirms[0].idOrcamento,orc=db.doc('orcamento/'+id),o=(await orc.get()).data();assert.equal(o.proposta_aceita.versao,2);assert.equal(o.estado_execucao,'nao_iniciado');assert.equal(o.contrato_financeiro.id_contrato,id);assert.equal(o.valor_contratado_centavos,j.proposta.liquidoCentavos);
 const {registrarOuAtualizarContrato}=require('../lib/services/financeiro/contratoFinanceiroService');await assert.rejects(()=>registrarOuAtualizarContrato(db,{idEvento:'ev',idOrcamento:id,valorCentavos:1,autorId:'c'}),e=>e.code==='failed-precondition');
 assert.equal((await orc.collection('orcamento_gasto').get()).size,1);assert.equal((await orc.collection('obrigacoes').get()).size,1);assert.equal((await db.collection('orcamento').where('id_cotacao','==','q').get()).size,1);
 const g=await call(G,'g',{idCotacao:'q',idFornecedor:'g'});assert.equal(g.estadoComercial,'perdido');assert.equal(g.idOrcamento,null);assert.equal(g.estadoExecucao,null);
 await assert.rejects(()=>call(R,'f',{...p1,chave:'pos-aceite',versaoEsperada:2}),e=>e.code==='failed-precondition');await assert.rejects(()=>call(C,'f',{idCotacao:'q'}),e=>e.code==='failed-precondition');
 j=await get();assert.equal(j.estadoComercial,'ganho');assert.equal(j.chatAberto,true);assert(!JSON.stringify(j).includes('987654'));assert(!JSON.stringify(j).includes('NÃO EXPOR'));assert(!JSON.stringify(j).includes('Concorrente não compartilhado'));
 env=await initializeTestEnvironment({projectId:'demo-jornada-atendimentos',firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync('firestore.rules','utf8')}});
 const cliente=env.authenticatedContext('c').firestore(),forn=env.authenticatedContext('f').firestore(),estranho=env.authenticatedContext('x').firestore();
 const msgs=await forn.collection('cotacao/q/fornecedores/f/mensagens').get();const m=msgs.docs[0];await assertSucceeds(m.ref.update({lido:true}));assert.equal((await orc.get()).data().estado_execucao,'nao_iniciado');
 const firebase=require('../../node_modules/firebase/compat/app');require('../../node_modules/firebase/compat/firestore');
 await assertSucceeds(forn.collection('cotacao/q/fornecedores/f/mensagens').add({id_usuario:'f',nome_usuario:'Fornecedor',mensagem:'Comunicação operacional após contratação',enviado_em:firebase.firestore.FieldValue.serverTimestamp(),lido:false}));
 await assertFails(estranho.collection('cotacao/q/fornecedores/f/mensagens').get());
 for(const cli of [cliente,forn,env.authenticatedContext('admin').firestore()]){await assertFails(cli.doc('cotacao/q/fornecedores/f/propostas/2').update({liquidoCentavos:1}));await assertFails(cli.doc('cotacao/q/fornecedores/f/historico_jornada/falso').set({acao:'contratar'}));await assertFails(cli.doc('cotacao/q/fornecedores/f/servicos/s').update({quantidade:1}));await assertFails(cli.doc('orcamento/'+id).update({proposta_aceita:{versao:99}}));await assertFails(cli.doc('orcamento/'+id).update({valor_contratado:1,escopo:'Troca silenciosa'}));await assertFails(cli.doc('orcamento/'+id).delete());await assertFails(cli.doc('orcamento/'+id+'/execucao_historico/falso').set({estado_novo:'aceito'}));}
 const executar=(uid,acao,rev,chave,extra={})=>call(E,uid,{idOrcamento:id,acao,versaoEsperada:rev,chave,...extra});
 await assert.rejects(()=>executar('c','agendar',0,'agenda-falsa',{dataAgendada:futuro()}),e=>e.code==='permission-denied');await assert.rejects(()=>executar('f','iniciar',0,'inicio-sem-preparo'),e=>e.code==='failed-precondition');
 const agenda={dataAgendada:futuro(),motivo:'Preparação de equipe e entrega'};const agendas=await Promise.all(Array.from({length:6},()=>executar('f','agendar',0,'agenda',agenda)));assert.equal(agendas.filter(r=>!r.idempotente).length,1);
 const {configurarCapacidade,confirmarAgendaContrato}=require('../lib/services/agenda/agendaFornecedorService');await configurarCapacidade(db,'f',{capacidade:2,revisao:0,chave:'cap-jornada'});await confirmarAgendaContrato(db,'f',{idOrcamento:id,agenda:{fuso:'America/Sao_Paulo',janelas:[{tipo:'execucao',inicio:'2030-01-01T10:00:00-03:00',fim:'2030-01-01T12:00:00-03:00'}]},unidades:1,revisao:0,chave:'agenda-jornada',motivo:'Planejamento operacional revisado'});
 await executar('f','iniciar',1,'inicio');await assert.rejects(()=>executar('f','informar_entrega',1,'versao-antiga'),e=>e.code==='aborted');await executar('f','informar_entrega',2,'entrega');
 await assert.rejects(()=>executar('f','aceitar',3,'aceite-falso'),e=>e.code==='permission-denied');const aceites=await Promise.all(Array.from({length:6},()=>executar('c','aceitar',3,'aceite')));assert.equal(aceites.filter(r=>!r.idempotente).length,1);
 j=await get();assert.equal(j.estadoExecucao,'aceito');assert.equal(j.estadoComercial,'ganho');assert.equal(j.idOrcamento,id);assert(j.historico.some(h=>h.acao==='agendar'));assert(j.historico.some(h=>h.acao==='aceitar'));assert.equal(j.proposta.versao,2);
 const av=await call(AV,'c',{idFornecedor:'f',idOrcamento:id,nota:4,comentario:'Entrega aceita na mesma contratação'});
 // Integração entre módulos: mesma contratação real da jornada até reputação/painel.
 const reputacao=require('../lib/services/avaliacoes/gestaoReputacaoService');
 await reputacao.responderReputacao(db,'f',{idFornecedor:'f',idAvaliacao:av.id,texto:'Resposta pública na mesma jornada',versaoEsperada:0,chave:'resposta-jornada'});
 assert.equal((await db.doc('fornecedor/f/avaliacoes/'+av.id).get()).data().nota,4);
 const reput=await reputacao.consultarGestaoReputacao(db,'f',{idFornecedor:'f',idAvaliacao:av.id});assert.equal(reput.resumo.media,4);assert.equal(reput.itens[0].resposta.versao,1);
 const agendaLida=await require('../lib/services/agenda/agendaFornecedorService').consultarAgendaFornecedor(db,'f');assert(agendaLida.compromissos.some(c=>c.idOrcamento===id));
 const painel=await require('../lib/services/fornecedores/painelOperacionalService').consultarPainelFornecedor(db,'f');assert.equal(painel.atendimentos.contratacoes,1);assert.equal(painel.reputacao.media,4);assert.equal(painel.reputacao.amostra,1);assert(!painel.fila.some(a=>a.argumentos?.idAvaliacao===av.id));
 console.log('PASS transversal: mesma identidade na jornada, agenda, avaliação, resposta e painel; nota preservada.');
 await seed('expirada');const exp=proposta('expirada',{validade:new Date(Date.now()+3000).toISOString()});await call(R,'f',exp);const ep=(await get('expirada')).proposta;await new Promise(r=>setTimeout(r,3100));await assert.rejects(()=>call(F,'c',{idCotacao:'expirada',idFornecedor:'f',versaoProposta:1,assinaturaProposta:ep.assinatura}),e=>e.code==='failed-precondition');
 await seed('cancelar');await call(R,'f',proposta('cancelar'));await call(M,'c',{idCotacao:'cancelar',idFornecedor:'f',acao:'cancelar',motivo:'cliente_desistiu',descricao:'Cancelamento antes da contratação',chave:'cancelamento'});assert.equal((await get('cancelar')).estadoComercial,'cancelado');await assert.rejects(()=>call(R,'f',proposta('cancelar',{chave:'reabrir',versaoEsperada:1})),e=>e.code==='failed-precondition');
 await seed('contestar');const co=await contratar('contestar');await call(E,'f',{idOrcamento:co.idOrcamento,acao:'informar_entrega',versaoEsperada:0,chave:'entrega-contestada'});await call(E,'c',{idOrcamento:co.idOrcamento,acao:'contestar',versaoEsperada:1,chave:'contestar',motivo:'Divergência explícita de escopo'});await assert.rejects(()=>call(E,'f',{idOrcamento:co.idOrcamento,acao:'informar_entrega',versaoEsperada:2,chave:'sobrescrever-contestacao'}),e=>e.code==='failed-precondition');
 const med=await call(MED,'f',{idOrcamento:co.idOrcamento,categoria:'cancelamento_solicitado',motivo:'Solicitação formal de alteração/cancelamento',descricao:'Revisão humana das condições aceitas',chaveIdempotencia:'pedido-alteracao'});assert(med.caso.id);assert.equal((await db.doc('plataforma_mediacao_casos/'+med.caso.id).get()).data().id_contrato,co.idOrcamento);assert.equal((await get('contestar')).mediacoes.length,1);
 await seed('legado');await db.doc('cotacao/legado').update({status:'concluida'});await db.doc('cotacao/legado/fornecedores/f').update({status:'fechado'});await db.doc('orcamento/contrato-legado').set({id_cotacao:'legado',id_evento:'ev',id_fornecedor:'f',status:'fechado',contrato_financeiro:{id_contrato:'identidade-legada',estado_comercial:'contratado',estado_execucao:'agendado'}});const legado=await get('legado');assert.equal(legado.idContrato,'identidade-legada');assert.equal(legado.idOrcamento,'contrato-legado');assert.equal(legado.estadoExecucao,'agendado');assert.equal((await db.collection('orcamento').where('id_cotacao','==','legado').get()).size,1);

 // Duas ofertas concorrentes: só um compromisso, nunca duas vendas.
 await seed('disputa');await call(R,'f',proposta('disputa'));
 await call(R,'g',proposta('disputa',{idFornecedor:'g',chave:'oferta-g'}));
 const ofertas=await Promise.all(['f','g'].map(async f=>{const j=await call(G,f,{idCotacao:'disputa',idFornecedor:f});return {idCotacao:'disputa',idFornecedor:f,versaoProposta:j.proposta.versao,assinaturaProposta:j.proposta.assinatura};}));
 const disputa=await Promise.allSettled(ofertas.map(d=>call(F,'c',d)));
 assert.equal(disputa.filter(r=>r.status==='fulfilled').length,1);
 assert.equal((await db.collection('orcamento').where('id_cotacao','==','disputa').get()).size,1);
 const estados=await db.collection('cotacao/disputa/fornecedores').get();assert.equal(estados.docs.filter(d=>d.data().estado_comercial==='ganho').length,1);
 // Cancelamento e aceite competem pelo mesmo estado transacional.
 await seed('corrida-cancelamento');await call(R,'f',proposta('corrida-cancelamento'));const pc=(await get('corrida-cancelamento')).proposta;
 const corrida=await Promise.allSettled([call(F,'c',{idCotacao:'corrida-cancelamento',idFornecedor:'f',versaoProposta:pc.versao,assinaturaProposta:pc.assinatura}),call(M,'c',{idCotacao:'corrida-cancelamento',idFornecedor:'f',acao:'cancelar',motivo:'cliente_desistiu',descricao:'Cancelamento antes de contratar',chave:'cancelamento-concorrente'})]);
 assert.equal(corrida.filter(r=>r.status==='fulfilled').length,1);
 const final=(await get('corrida-cancelamento')).estadoComercial;
 assert.equal((await db.collection('orcamento').where('id_cotacao','==','corrida-cancelamento').get()).size,final==='ganho'?1:0);
 console.log('PASS jornada: versões/CAS/validade, contratação única, estados comerciais separados, preparação/início/entrega/aceite/contestação, chat contratado, vínculo legado, mediação e regras.');
})().catch(e=>{console.error(e);process.exitCode=1}).finally(async()=>{if(env)await env.cleanup();await db.terminate();});
