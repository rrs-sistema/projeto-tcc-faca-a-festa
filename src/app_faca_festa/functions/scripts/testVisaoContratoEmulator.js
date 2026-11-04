require("./exigirEmuladorDemo").exigirEmuladorDemo("demo-financeiro-contratos");
// Integração real de projeção/callables/repasse/comissão contra Firestore Emulator.
const assert = require('node:assert/strict');
if (!process.env.FIRESTORE_EMULATOR_HOST) throw Error('Exige emulador.');
const admin=require('firebase-admin');
admin.initializeApp({projectId:'demo-financeiro-contratos'});
const db=admin.firestore();
const {consultarResumoFinanceiroFornecedor: resumoFn,registrarRecebimentoFornecedor}=require('../lib/functions/financeiro/comandosFinanceiroFornecedor');
const {listarAcompanhamentoFornecedor}=require('../lib/services/financeiro/acompanhamentoPersistenciaService');
const {consultarExtratoIntermediacao,prepararOuAutorizarRepasse,confirmarRepasseManual}=require('../lib/services/financeiro/intermediacaoPersistenciaService');
const {liquidarComissaoManual,consultarExtratoComissao,registrarAjusteComissao}=require('../lib/functions/financeiro/comandosComissaoPlataforma');
const money=centavos=>({centavos,moeda:'BRL'});
const resumo=()=>resumoFn.run({auth:{uid:'f'},data:{idFornecedor:'f'}});
async function seed(id,pagador='fornecedor',valor=315000) {
 await db.doc('orcamento/'+id).set({id_evento:'e',id_fornecedor:'f',id_solicitante:'o',status:'fechado',orcamento_fechado:true,valor_contratado_centavos:valor,contrato_financeiro:{id_contrato:id,estado_comercial:'contratado'}});
 await db.doc('plataforma_comissao_obrigacoes/comissao-'+id).set({id_obrigacao:'comissao-'+id,id_contrato:id,id_evento:'e',id_fornecedor:'f',id_pagador:pagador==='fornecedor'?'f':pagador==='organizador'?'o':null,base_elegivel:money(valor),valor_original:money(Math.round(valor*.05)),valor_liquidado:money(0),valor_ajustes_centavos:0,saldo_centavos:Math.round(valor*.05),politica_aplicada:{percentual_bps:500,pagador,reversao:'proporcional'},status:'a_vencer'});
 await db.doc('plataforma_alocacoes/'+id).set({id_evento:'e',id_orcamento:id,valor_centavos:valor+(pagador==='organizador'?Math.round(valor*.05):0)});
}
async function check(id,esperado,pendente) {
 const r=await resumo(); const c=r.contratos.find(c=>c.id===id);
 assert.equal(c.liquidoPrevisto,esperado/100);assert.equal(c.aReceber,pendente/100);
 const a=await listarAcompanhamentoFornecedor(db,{idFornecedor:'f'});const l=a.linhas.find(l=>l.idContrato===id);
 assert.equal(l.direitoLiquidoPrevistoCentavos,esperado);assert.equal(l.saldoPrevistoRepasseCentavos,pendente);assert.equal(l.revisao,c.revisao);
 if(id==='separada') assert.equal(l.comissaoJaDescontadaDoRepasse,false);
 const e=await consultarExtratoIntermediacao(db,'e');const ec=e.contratos.find(c=>c.id_contrato===id);
 assert.equal(ec.direito_fornecedor_centavos,esperado);
 return r;
}
async function repasse(id,valor,chave) {
 const p=await prepararOuAutorizarRepasse(db,{idContrato:id,idOrcamento:id,idFornecedor:'f',valorCentavos:valor,chaveIdempotencia:chave,autorId:'admin',forcarAutorizacaoSeElegivel:true});
 await confirmarRepasseManual(db,{idRepasse:p.id,autorId:'admin',evidencias:'PIX sintético '+chave});return p;
}
(async()=>{
 for(const [id,tipo] of [['f','F'],['o','O'],['admin','A'],['f2','F']])await db.doc('usuarios/'+id).set({tipo,ativo:true});
 await db.doc('fornecedor/f').set({nome:'Sintético'});
 await db.doc('evento/e').set({id_usuario:'o',status:'finalizado'});
 await db.doc('plataforma_liberacao_repasses/p').set({ativa:true,permite_repasse_parcial:true});
 await seed('c');let r=await check('c',299250,299250);assert.equal(r.aReceber,2992.5);assert.equal(r.contratado,3150);assert.equal(r.contratos[0].comissao,157.5);
 await db.doc('plataforma_recebimentos/declarado').set({id_evento:'e',id_orcamento_declarado:'c',nivel_confirmacao:'declaracao',valor_centavos:315000});
 r=await check('c',299250,299250);assert.equal(r.recebido,0);
 await repasse('c',100000,'parcial'); r=await check('c',299250,199250);assert.equal(r.aReceber,1992.5);assert.equal(r.recebido,1000);
 let obr=(await db.doc('plataforma_comissao_obrigacoes/comissao-c').get()).data();assert(obr.valor_liquidado.centavos>0&&obr.valor_liquidado.centavos<15750);
 await repasse('c',199250,'restante');await check('c',299250,0);
 obr=(await db.doc('plataforma_comissao_obrigacoes/comissao-c').get()).data();assert.equal(obr.valor_liquidado.centavos,15750);assert.equal(obr.liquidado_por_retencao_repasse_centavos,15750);
 await assert.rejects(()=>liquidarComissaoManual.run({auth:{uid:'admin'},data:{idObrigacao:'comissao-c',valorCentavos:15750,chaveIdempotencia:'duplicada'}}));
 await seed('adicionada','organizador');await check('adicionada',315000,315000);
 await seed('absorvida','plataforma_absorve');await check('absorvida',315000,315000);
 await seed('separada');await liquidarComissaoManual.run({auth:{uid:'admin'},data:{idObrigacao:'comissao-separada',valorCentavos:15750,chaveIdempotencia:'separada'}});
 await check('separada',315000,315000);await repasse('separada',315000,'sem-reter');
 assert.equal((await db.doc('plataforma_comissao_obrigacoes/comissao-separada').get()).data().liquidado_por_retencao_repasse_centavos||0,0);
 await seed('mista');await repasse('mista',100000,'mista');obr=(await db.doc('plataforma_comissao_obrigacoes/comissao-mista').get()).data();
 await liquidarComissaoManual.run({auth:{uid:'admin'},data:{idObrigacao:'comissao-mista',valorCentavos:15750-obr.valor_liquidado.centavos,chaveIdempotencia:'mista-separada'}});
 const recebidoSeparado=15750-obr.valor_liquidado.centavos;await check('mista',299250+recebidoSeparado,199250+recebidoSeparado);
 // Espelho legado com a mesma identidade não duplica contrato nem recebimento.
 await db.doc('orcamento/espelho').set((await db.doc('orcamento/adicionada').get()).data());
 await db.doc('fornecedor/f/contas_receber/proprio').set({id_evento:'e',id_orcamento:'adicionada',valor:money(12300),confirmacao:'declarada_manual'});
 r=await resumo();assert.equal(r.contratos.filter(c=>c.id==='adicionada').length,1);assert.equal(r.contratos.find(c=>c.id==='adicionada').recebimentoProprioDeclarado,123);assert.equal(r.contratos.find(c=>c.id==='absorvida').recebimentoProprioDeclarado,0);
 const pedidoProprio={auth:{uid:'f'},data:{idFornecedor:'f',idEvento:'e',idOrcamento:'adicionada',valorCentavos:5000,chaveIdempotencia:'proprio-atomico'}};
 await Promise.all([registrarRecebimentoFornecedor.run(pedidoProprio),registrarRecebimentoFornecedor.run(pedidoProprio)]);
 assert.equal((await db.doc('fornecedor/f/contas_receber/proprio-atomico').get()).data().id_contrato,'adicionada');
 assert((await db.doc('fornecedor/f/movimentos_caixa/proprio-atomico').get()).exists);
 await assert.rejects(()=>registrarRecebimentoFornecedor.run({...pedidoProprio,data:{...pedidoProprio.data,valorCentavos:999}}));
 await assert.rejects(()=>registrarRecebimentoFornecedor.run({auth:{uid:'f'},data:{idFornecedor:'f',idEvento:'e',valorCentavos:5000,chaveIdempotencia:'ambiguo'}}));
 // Legado em reais usa identidade do orçamento e a política registrada, sem taxa implícita.
 await seed('legado');await db.doc('orcamento/legado').set({id_evento:'e',id_fornecedor:'f',status:'fechado',orcamento_fechado:true,valor_contratado:3150});await check('legado',299250,299250);
 await db.doc('orcamento/c').update({'contrato_financeiro.estado_comercial':'cancelado'});
 r=await resumo();assert.equal(r.contratos.find(c=>c.id==='c').situacao,'cancelado');assert.equal(r.contratos.find(c=>c.id==='c').recebido,2992.5);
 await registrarAjusteComissao.run({auth:{uid:'admin'},data:{idObrigacao:'comissao-c',reducaoBaseCentavos:315000,chaveIdempotencia:'estorno-c',motivo:'Cancelamento sintético'}});
 const ajustada=(await db.doc('plataforma_comissao_obrigacoes/comissao-c').get()).data();
 assert.equal(ajustada.valor_ajustes_centavos,-15750);assert.equal(ajustada.saldo_centavos,-15750);
 assert.equal((await db.doc('plataforma_comissao_ajustes/estorno-c').get()).data().autor_id,'admin');
 assert.equal((await db.doc('plataforma_comissao_obrigacoes/comissao-c').get()).data().valor_liquidado.centavos,15750);
 await db.doc('fornecedor/f/custos_internos/privado').set({id_evento:'e',valor_incorrido:money(5000),previsto_restante:money(0),valor_desembolso:money(5000)});
 r=await resumo();assert.equal(r.custoRealizado,50);
 const extratoComissao=await consultarExtratoComissao.run({auth:{uid:'f'},data:{idPagador:'f'}});
 assert(extratoComissao.obrigacoes.every(o=>!('custos_internos' in o)));
 const rc=r.contratos.find(c=>c.id==='mista'), oc=extratoComissao.obrigacoes.find(o=>o.id_contrato==='mista');
 assert.equal(rc.revisaoComissao,oc.revisaoComissao);
 await seed('ausente');await db.doc('plataforma_comissao_obrigacoes/comissao-ausente').delete();
 await assert.rejects(resumo,e=>e.code==='failed-precondition');await assert.rejects(()=>listarAcompanhamentoFornecedor(db,{idFornecedor:'f'}));
 await assert.rejects(()=>resumoFn.run({auth:{uid:'o'},data:{idFornecedor:'f'}}),e=>e.code==='permission-denied');
 await assert.rejects(()=>resumoFn.run({auth:{uid:'admin'},data:{idFornecedor:'f'}}),e=>e.code==='permission-denied');
 console.log('PASS integração contratos: aceite 3150/157,50/2992,50/1992,50; modos; retenção parcial/integral; separado/misto; legado; cancelamento/estorno; indisponibilidade; privacidade.');
 await db.terminate();
})().catch(e=>{console.error(e);process.exitCode=1;});
