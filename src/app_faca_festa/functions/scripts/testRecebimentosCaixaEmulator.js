require("./exigirEmuladorDemo").exigirEmuladorDemo("demo-caixa-fornecedor");
const assert=require('node:assert/strict');
const fs=require('node:fs');
if(!process.env.FIRESTORE_EMULATOR_HOST)throw Error('Somente emulador');
const admin=require('firebase-admin');admin.initializeApp({projectId:'demo-caixa-fornecedor'});const db=admin.firestore();
const {registrarRecebimentoFornecedor:reg,consultarResumoFinanceiroFornecedor:resumo,consultarOperacaoRecebimentoFornecedor:consulta}=require('../lib/functions/financeiro/comandosFinanceiroFornecedor');
const {registrarOperacaoRecebimento}=require('../lib/services/financeiro/recebimentoFornecedorService');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('../../node_modules/@firebase/rules-unit-testing');
const m=centavos=>({centavos,moeda:'BRL'});
const auth={uid:'f'};const base=db.doc('fornecedor/f');
const pedir=(chave,valorCentavos,idOrcamento='c1',extra={})=>({idFornecedor:'f',idEvento:'e',chaveIdempotencia:chave,valorCentavos,tipo:'recebimento',...(idOrcamento?{idOrcamento}:{}),...extra});
const enviar=data=>reg.run({auth,data});const ler=()=>resumo.run({auth,data:{idFornecedor:'f'}});
async function seed(){
 for(const [u,tipo] of [['f','F'],['f2','F'],['o','O'],['admin','A']])await db.doc('usuarios/'+u).set({tipo,ativo:true});
 await base.set({nome:'Empresa sintética'});await db.doc('evento/e').set({id_usuario:'o',status:'planejamento'});
 for(const [id,valor] of [['c1',200000],['c2',300000]]){
 await db.doc('orcamento/'+id).set({id_fornecedor:'f',id_evento:'e',status:'fechado',orcamento_fechado:true,valor_contratado_centavos:valor,contrato_financeiro:{id_contrato:id,estado_comercial:'contratado',estado_execucao:'nao_iniciado'}});
 await db.doc('plataforma_comissao_obrigacoes/'+id).set({id_contrato:id,id_evento:'e',id_fornecedor:'f',valor_original:m(0),valor_liquidado:m(0),base_elegivel:m(valor),politica_aplicada:{percentual_bps:0,pagador:'fornecedor'},status:'recebida'});
 }
}
(async()=>{
 await seed();
 const pedido=pedir('recebimento-500',50000,'c1',{execucaoConfirmada:true});
 const resultados=await Promise.all(Array.from({length:8},()=>enviar(pedido)));
 assert.equal(resultados.filter(r=>!r.idempotente).length,1);
 for(const col of ['contas_receber','movimentos_caixa','financeiro_auditoria'])assert.equal((await base.collection(col).get()).size,1);
 let r=await ler();const saldo=(r,id)=>r.contratos.find(c=>c.id===id).aReceber;
 assert.equal(saldo(r,'c1'),1500);assert.equal(saldo(r,'c2'),3000);assert.equal(r.entradasCaixa,500);assert.equal(r.recebido,500);assert.equal(r.receitaRealizada,0);
 assert.equal((await base.collection('contas_receber').doc('recebimento-500').get()).data().execucao_confirmada,false);
 for(const extra of [{valorCentavos:50001},{idOrcamento:'c2'},{tipo:'adiantamento'},{execucaoConfirmada:false},{motivo:'alterado'}])await assert.rejects(()=>enviar({...pedido,...extra}),e=>e.code==='already-exists');
 // Timeout depois da persistência real: concilia pelo endpoint e reenvia a mesma operação.
 await assert.rejects(async()=>{await enviar(pedido);throw Error('timeout após persistência');});
 const q=await consulta.run({auth,data:{idFornecedor:'f',chaveIdempotencia:pedido.chaveIdempotencia,pedido}});assert.equal(q.encontrado,true);
 await enviar(pedido);r=await ler();assert.equal(r.entradasCaixa,500);assert.equal(saldo(r,'c1'),1500);
 // Leitura em listener seguida de refresh não fabrica segunda entrada.
 const env=await initializeTestEnvironment({projectId:'demo-caixa-fornecedor',firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync('firestore.rules','utf8')}});
 const cliente=env.authenticatedContext('f').firestore();
 const vistos=[];let cancel;
 await new Promise((resolve,reject)=>{cancel=cliente.collection('fornecedor/f/contas_receber').onSnapshot(s=>{vistos.push(s.size);if(s.size===1)resolve();},reject);});
 await enviar(pedido);assert.equal((await ler()).entradasCaixa,500);cancel();assert(vistos.every(v=>v===1));
 await assert.rejects(()=>registrarOperacaoRecebimento(db,pedir('falha-pre-commit',10000),'f',{antesCommit:()=>{throw Error('Falha injetada depois de enfileirar as escritas, antes do commit');}}));
 for(const col of ['contas_receber','movimentos_caixa','financeiro_auditoria'])assert.equal((await base.collection(col).doc('falha-pre-commit').get()).exists,false);
 await assert.rejects(()=>registrarOperacaoRecebimento(db,pedir('falha-estorno',10000,'c1',{tipo:'estorno',referenciaRecebimento:'recebimento-500'}),'f',{antesCommit:()=>{throw Error('Abortar estorno');}}));
 assert.equal((await base.collection('contas_receber').doc('recebimento-500').get()).data().estornado_centavos || 0,0);
await enviar(pedir('multi',70000,null,{alocacoes:[{idContrato:'c1',valorCentavos:20000},{idContrato:'c2',valorCentavos:30000}]}));
 r=await ler();assert.equal(saldo(r,'c1'),1300);assert.equal(saldo(r,'c2'),2700);assert.equal(r.entradasCaixa,1200);assert.equal(r.recebimentoNaoAlocado,200);
 await assert.rejects(()=>enviar(pedir('superalocacao',100,null,{alocacoes:[{idContrato:'c1',valorCentavos:101}]})));
 await enviar(pedir('adiantamento',5000,'c2',{tipo:'adiantamento',execucaoConfirmada:true}));r=await ler();assert.equal(r.adiantamentosCaixa,50);assert.equal(r.receitaRealizada,0);
 await enviar(pedir('estorno-125',12500,'c1',{tipo:'estorno',referenciaRecebimento:'recebimento-500'}));
 r=await ler();assert.equal(saldo(r,'c1'),1425);assert.equal(r.saidasCaixa,125);assert.equal(r.entradasCaixa,1250);assert.equal(r.movimentoLiquido,1125);
 const concorrentes=await Promise.allSettled([1,2].map(i=>enviar(pedir('estorno-concorrente-'+i,25000,'c1',{tipo:'estorno',referenciaRecebimento:'recebimento-500'}))));
 assert.equal(concorrentes.filter(x=>x.status==='fulfilled').length,1);assert.equal((await base.collection('contas_receber').doc('recebimento-500').get()).data().valor.centavos,50000);
 await assert.rejects(()=>enviar(pedir('estorno-excesso',50000,'c1',{tipo:'estorno',referenciaRecebimento:'recebimento-500'})));
 await enviar(pedir('excedente',300000,'c1'));r=await ler();assert.equal(saldo(r,'c1'),-1325);assert.equal(r.contratos.find(c=>c.id==='c1').creditoExcedente,1325);assert.equal(r.creditoExcedente,1325);
 const antes=saldos=>JSON.stringify(saldos.contratos.map(c=>[c.id,c.aReceber]));const saldosAntes=antes(r);
 await base.collection('contas_receber').doc('legado').set({schema:1,id_evento:'e',valor:m(7500),tipo:'recebimento',chave_idempotencia:'legado',autor_id:'f'});
 await base.collection('movimentos_caixa').doc('legado').set({schema:1,id_evento:'e',valor:m(7500),entrada:true,chave_idempotencia:'legado',origem:'recebimento'});
 r=await ler();assert.equal(antes(r),saldosAntes);assert.equal(r.recebimentoNaoAlocado,275);const caixa=r.entradasCaixa;
 await base.collection('contas_receber').doc('legado-sem-espelho').set({schema:1,id_evento:'e',valor:m(2500),tipo:'recebimento'});
 r=await ler();assert.equal(r.entradasCaixa,caixa+25);assert.equal(r.recebimentoNaoAlocado,300);
 await assert.rejects(()=>enviar(pedir('legado',7500,'c1')));
 for(const uid of ['f','f2','o','admin']){
 const d=env.authenticatedContext(uid).firestore();
 for(const col of ['contas_receber','movimentos_caixa','financeiro_auditoria']){
 const ref=d.doc('fornecedor/f/'+col+'/recebimento-500');await (uid==='f'?assertSucceeds:assertFails)(ref.get());
 await assertFails(ref.update({valor:m(1)}));await assertFails(ref.delete());await assertFails(d.doc('fornecedor/f/'+col+'/fraude').set({valor:m(1)}));
 }
 }
 const movimentoOriginal=(await base.collection('movimentos_caixa').doc('recebimento-500').get()).data();
 await base.collection('movimentos_caixa').doc('recebimento-500').update({valor:m(1)});
 await assert.rejects(ler);
 await assert.rejects(()=>consulta.run({auth,data:{idFornecedor:'f',chaveIdempotencia:'recebimento-500',pedido}}));
 await assert.rejects(()=>enviar(pedido));
 await base.collection('movimentos_caixa').doc('recebimento-500').set(movimentoOriginal);
 const {listarAcompanhamentoFornecedor}=require('../lib/services/financeiro/acompanhamentoPersistenciaService');
 const acompanhamento=await listarAcompanhamentoFornecedor(db,{idFornecedor:'f'});
 const final=await ler();
 for(const l of acompanhamento.linhas) assert.equal(l.saldoContratoCentavos,Math.round(final.contratos.find(c=>c.id===l.idContrato).saldoContrato*100));
 const corrida=await Promise.allSettled([enviar(pedir('chave-divergente-concorrente',1,'c1')),enviar(pedir('chave-divergente-concorrente',1,'c2'))]);
 assert.equal(corrida.filter(x=>x.status==='fulfilled').length,1);assert.equal(corrida.filter(x=>x.status==='rejected' && x.reason.code==='already-exists').length,1);
 await env.cleanup();
 console.log('PASS recebimentos/caixa: 2000+3000, recebimento500 => 1500/3000, caixa500 uma vez; concorrência, assinatura completa, timeout, listener/refresh, rollback real, multi-alocação, adiantamento, estornos concorrentes, crédito e legado não alocado; regras privadas.');
 await db.terminate();
})().catch(e=>{console.error(e);process.exitCode=1;});
