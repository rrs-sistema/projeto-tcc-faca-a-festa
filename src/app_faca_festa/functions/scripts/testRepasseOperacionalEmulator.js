require("./exigirEmuladorDemo").exigirEmuladorDemo("demo-repasse-operacional");
// Executar somente no emulador: npm run test:repasse:operacional
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Exige Firestore Emulator.');
const admin = require('firebase-admin');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('../../node_modules/@firebase/rules-unit-testing');
const { prepararOuAutorizarRepasse, confirmarRepasseManual, autorizarRepasseOrganizador,
  cancelarRepassePendente, registrarRecebimentoPlataforma, alocarRecebimentoAContratos,
  consultarExtratoIntermediacao } = require('../lib/services/financeiro/intermediacaoPersistenciaService');
const projectId = 'demo-repasse-operacional';
admin.initializeApp({ projectId });
const db = admin.firestore();
const money = centavos => ({ centavos, moeda: 'BRL' });
const recusado = fn => assert.rejects(fn, e => ['failed-precondition', 'permission-denied', 'invalid-argument'].includes(e.code));

async function main() {
  await db.doc('evento/e').set({ id_usuario: 'org', status: 'planejamento', data: '2020-01-01' });
  await db.doc('usuarios/org').set({ tipo: 'O', ativo: true });
  await db.doc('usuarios/admin').set({ tipo: 'A', ativo: true });
  await db.doc('usuarios/forn').set({ tipo: 'F', ativo: true });
  // Jornada real de fechamento: callable, contrato, obrigação de pagamento e comissão.
  await db.doc('plataforma_comissao_politicas/p').set({ ativa: true, completa: true, percentual_bps: 800,
    pagador: 'fornecedor', gatilho_geracao: 'contratacao_confirmada', versao: 1 });
  await db.doc('orcamento/novo').set({ id_evento: 'e', id_fornecedor: 'forn', id_solicitante: 'org', status: 'pendente' });
  const { registrarContratoFinanceiro } = require('../lib/functions/financeiro/comandosFinanceiro');
  await registrarContratoFinanceiro.run({ auth: { uid: 'org' }, data: { idEvento: 'e', idOrcamento: 'novo', valorCentavos: 10000 } });
  assert.equal((await db.doc('orcamento/novo').get()).data().contrato_financeiro.estado_comercial, 'contratado');
  assert.equal((await db.doc('orcamento/novo/obrigacoes/parcela-1').get()).data().valor.centavos, 10000);
  assert.equal((await db.doc('plataforma_comissao_obrigacoes/comissao-novo').get()).data().valor_original.centavos, 800);
  await db.doc('cotacao/cot').set({ id_evento: 'e', id_usuario_solicitante: 'org', status: 'aberta' });
  await db.doc('cotacao/cot/fornecedores/forn').set({ id_fornecedor: 'forn', status: 'respondido', valor_cotado: 100 });
  await db.doc('cotacao/cot/fornecedores/forn/servicos/s').set({ valor_estimado: 100, quantidade: 1 });
  const { responderCotacao } = require('../lib/functions/cotacao/responderCotacao');
  const proposta = await responderCotacao.run({auth:{uid:'forn'},data:{idCotacao:'cot',idFornecedor:'forn',aceitou:true,valorBrutoCentavos:10000,descontoCentavos:0,validade:new Date(Date.now()+86400000).toISOString(),escopo:'Serviço sintético contratado',condicaoPagamento:'Conforme contrato',versaoEsperada:0,chave:'proposta-repasse'}});
  const { fecharCotacao } = require('../lib/functions/cotacao/fecharCotacao');
  const fechamentos = await Promise.allSettled([1, 2].map(() => fecharCotacao.run({ auth: { uid: 'org' }, data: {
    idCotacao: 'cot', idFornecedor: 'forn', versaoProposta:proposta.versao, assinaturaProposta:proposta.assinatura } })));
  assert.equal(fechamentos.filter(r => r.status === 'fulfilled').length, 2, 'Fechamento concorrente retorna a mesma contratação idempotentemente');
  assert.equal((await db.collection('orcamento').where('id_cotacao', '==', 'cot').get()).size, 1);

  const { autorizarRepasseOrganizadorFn } = require('../lib/functions/financeiro/comandosIntermediacaoFinanceira');
  await recusado(() => autorizarRepasseOrganizadorFn.run({ auth: { uid: 'admin' }, data: {
    idOrcamento: 'novo', autorizar: true, motivo: 'Admin não pode substituir consentimento.' } }));

  for (const id of ['c', 'c2', 'c3', 'sem-comissao']) {
    await db.doc(`orcamento/${id}`).set({ id_evento: 'e', id_fornecedor: 'forn', status: 'fechado',
      orcamento_fechado: true, valor_contratado_centavos: 10000,
      contrato_financeiro: { id_contrato: id, estado_comercial: 'contratado', estado_execucao: 'nao_iniciado' } });
    if (id !== 'sem-comissao') await db.doc(`plataforma_comissao_obrigacoes/comissao-${id}`).set({
      id_obrigacao: `comissao-${id}`, id_contrato: id, id_evento: 'e', id_fornecedor: 'forn',
      base_elegivel: money(10000), valor_original: money(500), valor_liquidado: money(0),
      politica_aplicada: { percentual_bps: 500, pagador: 'fornecedor' }, status: 'a_vencer' });
    await db.doc(`plataforma_alocacoes/${id}`).set({ id_evento: 'e', id_orcamento: id, valor_centavos: 10000 });
  }
  const { listarAcompanhamentoOrganizador } = require('../lib/services/financeiro/acompanhamentoPersistenciaService');
  const lerContrato = async () => (await listarAcompanhamentoOrganizador(db, {
    uid: 'org', idEvento: 'e',
  })).linhas.find(linha => linha.idOrcamento === 'c');
  assert.match((await lerContrato()).statusRepassePermitido, /pendente de configuração/);
  await db.doc('plataforma_liberacao_repasses/p').set({ ativa: true, permite_repasse_parcial: true });
  assert.equal((await lerContrato()).statusRepassePermitido, 'Ainda sem repasse ao fornecedor');
  const duplicada = db.doc('plataforma_liberacao_repasses/duplicada');
  await duplicada.set({ ativa: true });
  assert.match((await lerContrato()).statusRepassePermitido, /pendente de configuração/);
  await duplicada.delete();
  const pedido = (key, id = 'c') => ({ idContrato: id, idOrcamento: id, idFornecedor: 'forn',
    valorCentavos: 9500, percentualBps: 0, valorContratadoCentavos: 99999999,
    chaveIdempotencia: key, autorId: 'admin', forcarAutorizacaoSeElegivel: true });
  const autorizacao = (autorId, autorizar = true) => autorizarRepasseOrganizador(db, {
    idOrcamento: 'c', autorId, autorizar, motivo: 'Autorização expressa para este contrato.' });

  await recusado(() => prepararOuAutorizarRepasse(db, pedido('antes')));
  await recusado(() => autorizacao('intruso'));
  await Promise.all([autorizacao('org'), autorizacao('org')]);
  const auditoria = db.collection('plataforma_intermediacao_auditoria').where('id_orcamento', '==', 'c');
  const registros = await auditoria.get();
  assert.equal(registros.size, 1, 'Solicitações iguais não duplicam auditoria ou push.');
  const log = registros.docs[0];
  assert.equal(log.data().acao, 'organizador_autorizou_repasse');
  assert.equal(log.data().autor_id, 'org');
  assert.equal(log.data().id_fornecedor, 'forn');
  assert.equal(log.data().id_contrato, 'c');
  assert.equal(log.data().ativa_anterior, null);
  assert.equal(log.data().motivo, 'Autorização expressa para este contrato.');
  assert.ok(log.data().criado_em.toMillis() > 0);
  assert.equal(log.data().push.estado, 'pendente');

  await db.doc('usuarios/org/dispositivos_push/a').set({ token: 'token-organizador' });
  await db.doc('usuarios/forn/dispositivos_push/a').set({ token: 'token-fornecedor-1' });
  await db.doc('usuarios/forn/dispositivos_push/b').set({ token: 'token-fornecedor-2' });
  const { enviarPushAutorizacaoRepasse, notificarAutorizacaoRepasse } =
    require('../lib/functions/financeiro/notificarAutorizacaoRepasse');
  const pushes = [];
  const messaging = { sendEachForMulticast: async payload => {
    pushes.push(payload);
    return { responses: pushes.length === 1
      ? [{ success: true }, { success: false, error: { code: 'messaging/server-unavailable' } }]
      : [{ success: true }] };
  } };
  await assert.rejects(() => enviarPushAutorizacaoRepasse(db, messaging, log.id));
  await enviarPushAutorizacaoRepasse(db, messaging, log.id);
  await enviarPushAutorizacaoRepasse(db, messaging, log.id);
  assert.equal(pushes.length, 2, 'Reprocessar envio concluído não dispara outro push.');
  assert.deepEqual(pushes[0].tokens, ['token-fornecedor-1', 'token-fornecedor-2']);
  assert.deepEqual(pushes[1].tokens, ['token-fornecedor-2']);
  assert.deepEqual(pushes[0].data, {
    screen: 'autorizacao_repasse', id_destinatario: 'forn', id_orcamento: 'c',
  });
  assert.ok(!JSON.stringify(pushes).includes(log.data().motivo));
  assert.equal((await log.ref.get()).data().push.estado, 'enviado');

  const evento = { id: 'teste-autorizacao-c', data: await log.ref.get(), params: { idAuditoria: log.id } };
  await notificarAutorizacaoRepasse.run(evento);
  await notificarAutorizacaoRepasse.run(evento);
  const geral = await db.collection('auditoria_eventos').where('acao', '==', 'REPASSE_ANTECIPADO_AUTORIZADO').get();
  assert.equal(geral.size, 1);
  assert.equal(geral.docs[0].data().ator_uid, 'org');
  assert.equal(geral.docs[0].data().id_orcamento, 'c');
  assert.equal(geral.docs[0].data().visivel_fornecedor, false);

  let extrato = await consultarExtratoIntermediacao(db, 'e');
  assert.equal(extrato.contratos.find(c => c.id_orcamento === 'c').elegivel_centavos, 9500);
  assert.equal(extrato.contratos.find(c => c.id_orcamento === 'sem-comissao').elegivel_centavos, 0);
  const tentativas = await Promise.allSettled([
    prepararOuAutorizarRepasse(db, pedido('concorrente-a')),
    prepararOuAutorizarRepasse(db, pedido('concorrente-b')),
  ]);
  assert.equal(tentativas.filter(r => r.status === 'fulfilled').length, 1, 'Não duplica reserva concorrente');
  const repasse = tentativas.find(r => r.status === 'fulfilled').value;
  const salvo = (await db.doc(`plataforma_repasses/${repasse.id}`).get()).data();
  assert.equal(salvo.divisao_contrato.comissaoCentavos, 500, 'Taxa enviada pelo cliente é ignorada');
  assert.equal(salvo.divisao_contrato.direitoFornecedorCentavos, 9500);
  const confirmar = () => confirmarRepasseManual(db, { idRepasse: repasse.id, autorId: 'admin', evidencias: 'PIX referência teste-123' });
  await autorizacao('org', false);
  const revogacao = (await auditoria.get()).docs.find(d => d.data().acao === 'organizador_revogou_autorizacao');
  assert.equal(revogacao.data().ativa_anterior, true);
  assert.equal(revogacao.data().push, undefined);
  await recusado(confirmar);
  await autorizacao('org');
  await db.doc('plataforma_liberacao_repasses/p').update({ ativa: false });
  await recusado(confirmar);
  await db.doc('plataforma_liberacao_repasses/p').update({ ativa: true });
  await db.doc('plataforma_mediacao_casos/caso').set({ id_orcamento: 'c', id_evento: 'e', estado: 'aberto' });
  await recusado(confirmar);
  await db.doc('plataforma_mediacao_casos/caso').update({ estado: 'fechado', retencao_efetiva_ativa: true });
  await recusado(confirmar);
  await db.doc('plataforma_mediacao_casos/caso').update({ retencao_efetiva_ativa: false });
  await recusado(() => confirmarRepasseManual(db, { idRepasse: repasse.id, autorId: 'admin' }));
  assert.equal((await confirmar()).estado, 'confirmado');
  assert.equal((await confirmar()).estado, 'confirmado', 'Repetição não duplica pagamento');
  const comissao = (await db.doc('plataforma_comissao_obrigacoes/comissao-c').get()).data();
  assert.equal(comissao.valor_liquidado.centavos, 500);
  assert.equal(comissao.status, 'recebida');
  assert.equal((await db.collection('plataforma_comissao_liquidacoes').get()).size, 1);
  await recusado(() => cancelarRepassePendente(db, repasse.id, 'admin'));

  // Passar a data não conclui evento; somente o estado finalizado dispensa autorização.
  await recusado(() => prepararOuAutorizarRepasse(db, pedido('data-passada', 'c2')));
  await db.doc('evento/e').update({ status: 'finalizado' });
  await db.doc('orcamento/c2').update({ 'contrato_financeiro.estado_execucao': 'cancelado_execucao' });
  await recusado(() => prepararOuAutorizarRepasse(db, pedido('execucao-cancelada', 'c2')));
  await db.doc('orcamento/c2').update({ 'contrato_financeiro.estado_execucao': 'nao_iniciado' });

  const segundo = await prepararOuAutorizarRepasse(db, pedido('apos-evento', 'c2'));
  await db.doc('plataforma_comissao_obrigacoes/comissao-c2').update({ valor_ajustes_centavos: 100 });
  await recusado(() => confirmarRepasseManual(db, { idRepasse: segundo.id, autorId: 'admin', evidencias: 'PIX teste-456' }));
  await cancelarRepassePendente(db, segundo.id, 'admin');
  await recusado(() => prepararOuAutorizarRepasse(db, pedido('sem-comissao', 'sem-comissao')));
  const parcial = await prepararOuAutorizarRepasse(db, { ...pedido('parcial-1', 'c3'), valorCentavos: 3000 });
  const restante = await prepararOuAutorizarRepasse(db, { ...pedido('parcial-2', 'c3'), valorCentavos: 6500 });
  for (const r of [parcial, restante]) await confirmarRepasseManual(db, {
    idRepasse: r.id, autorId: 'admin', evidencias: 'PIX referência de parcela' });
  assert.equal((await db.doc('plataforma_comissao_obrigacoes/comissao-c3').get()).data().valor_liquidado.centavos, 500);
  const liquidacoesC3 = await db.collection('plataforma_comissao_liquidacoes').where('id_obrigacao', '==', 'comissao-c3').get();
  assert.equal(liquidacoesC3.size, 2, 'Uma retenção proporcional em cada parcela');
  assert.equal(liquidacoesC3.docs.reduce((s,d) => s + d.data().valor.centavos, 0), 500, 'Parcelas não duplicam a comissão');


  const rec = { idEvento: 'e', valorCentavos: 100, nivelConfirmacao: 'declaracao', chaveIdempotencia: 'declaracao', autorId: 'admin' };
  const recebimentos = await Promise.all([registrarRecebimentoPlataforma(db, rec), registrarRecebimentoPlataforma(db, rec)]);
  assert.equal(recebimentos[0].id, recebimentos[1].id, 'Recebimento idempotente mesmo sob concorrência');
  await recusado(() => alocarRecebimentoAContratos(db, { idRecebimento: recebimentos[0].id,
    alocacoes: [{ idContrato: 'c2', idOrcamento: 'c2', valorCentavos: 100 }], chaveIdempotencia: 'aloc-decl', autorId: 'admin' }));

  await require('./testPendenciasOperacionais')(db);

  const env = await initializeTestEnvironment({ projectId, firestore: {
    rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
    host: '127.0.0.1', port: 8080,
  } });
  try {
    const org = env.authenticatedContext('org').firestore();
    const forn = env.authenticatedContext('forn').firestore();
    const adm = env.authenticatedContext('admin').firestore();
    await assertSucceeds(org.doc('plataforma_autorizacoes_repasses/c').get());
    await assertFails(forn.doc('plataforma_autorizacoes_repasses/c').get());
    await assertFails(org.doc('plataforma_autorizacoes_repasses/c').update({ ativa: true }));
    await assertSucceeds(adm.doc(log.ref.path).get());
    await assertFails(forn.doc(log.ref.path).get());
    await assertFails(forn.doc('orcamento/c').update({ estado_execucao: 'aceito_cliente' }));
    await assertFails(org.doc('orcamento/c').update({ contrato_financeiro: { estado_execucao: 'aceito_cliente' } }));
    await assertFails(adm.doc('orcamento/c').update({ valor_contratado_centavos: 1 }));
    await assertFails(adm.doc('plataforma_repasses/forjado').set({ estado: 'confirmado' }));
  } finally { await env.cleanup(); }
  console.log('✓ Repasse operacional: evento/autorização, comissão real, retenção, mediação, concorrência, idempotência e regras.');
}
main().then(() => admin.app().delete()).catch(e => { console.error(e); process.exitCode = 1; });
