const assert = require('node:assert/strict');
const { prepararOuAutorizarRepasse, confirmarRepasseManual, autorizarRepasseOrganizador } = require('../lib/services/financeiro/intermediacaoPersistenciaService');
const { abrirCasoMediacao, registrarDecisao, fecharCaso } = require('../lib/services/financeiro/mediacaoPersistenciaService');
const { resolverExecucaoMediacao } = require('../lib/functions/financeiro/resolverExecucaoMediacao');
const { consultarDetalheContratacao } = require('../lib/functions/financeiro/consultarCentralContratacoes');
const dinheiro = centavos => ({ centavos, moeda: 'BRL' });
const rejeita = fn => assert.rejects(fn, e => ['failed-precondition','permission-denied','invalid-argument'].includes(e.code));

module.exports = async function testar(db) {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Somente no emulador.');
  const contrato = async (id, pagoExterno = 0, pagador = 'fornecedor', alocado = 10000) => {
    await db.doc(`orcamento/${id}`).set({ id_evento: 'e', id_fornecedor: 'forn', id_solicitante: 'org',
      status: 'fechado', orcamento_fechado: true, valor_contratado_centavos: 10000,
      contrato_financeiro: { id_contrato: id, estado_comercial: 'contratado', estado_execucao: 'nao_iniciado' } });
    await db.doc(`plataforma_comissao_obrigacoes/comissao-${id}`).set({ id_obrigacao: `comissao-${id}`,
      id_contrato: id, id_evento: 'e', id_fornecedor: 'forn', base_elegivel: dinheiro(10000),
      valor_original: dinheiro(500), valor_liquidado: dinheiro(pagoExterno),
      politica_aplicada: { percentual_bps: 500, pagador }, status: pagoExterno === 500 ? 'recebida' : 'a_vencer' });
    await db.doc(`plataforma_alocacoes/${id}`).set({ id_evento: 'e', id_orcamento: id, valor_centavos: alocado });
  };
  const pedido = (id, valor) => ({ idContrato: id, idOrcamento: id, idFornecedor: 'forn', valorCentavos: valor,
    percentualBps: 9999, valorContratadoCentavos: 999999, chaveIdempotencia: `rep-${id}-${valor}`, autorId: 'admin' });
  for (const [id, externo, pagador, alocado, repasse, retida] of [
    ['externo-parcial', 200, 'fornecedor', 10000, 9700, 300],
    ['externo-integral', 500, 'fornecedor', 10000, 10000, 0],
    ['externo-organizador', 200, 'organizador', 10300, 10000, 300],
  ]) {
    await contrato(id, externo, pagador, alocado);
    const rep = await prepararOuAutorizarRepasse(db, pedido(id, repasse));
    await confirmarRepasseManual(db, { idRepasse: rep.id, autorId: 'admin', evidencias: 'PIX referência de conferência' });
    const o = (await db.doc(`plataforma_comissao_obrigacoes/comissao-${id}`).get()).data();
    assert.equal(o.valor_liquidado.centavos, 500, 'Comissão nunca cobrada duas vezes');
    assert.equal(o.liquidado_por_retencao_repasse_centavos || 0, retida);
    const dossie = await consultarDetalheContratacao.run({ auth: { uid: 'admin' }, data: { idOrcamento: id } });
    assert.equal(dossie.financeiro.pendenteRepasseCentavos, 0, 'Dossiê não apresenta a comissão como saldo do fornecedor');
    assert.equal(dossie.financeiro.aReceberClienteCentavos, 0);
  }
  console.log('✓ Comissão externa parcial/integral e pagador organizador conciliados sem duplicidade.');

  await contrato('mediado');
  await db.doc('evento/e').update({ status: 'planejamento' });
  const autoriza = () => autorizarRepasseOrganizador(db, { idOrcamento: 'mediado', autorId: 'org',
    motivo: 'Autorização explícita do organizador.', autorizar: true });
  await autoriza();
  const reserva = await prepararOuAutorizarRepasse(db, pedido('mediado', 9500));
  const abre = chave => abrirCasoMediacao(db, { idEvento: 'e', idContrato: 'mediado', idOrcamento: 'mediado',
    idFornecedor: 'forn', idContratante: 'org', categoria: 'divergencia_servico', motivo: 'Serviço contestado pelas partes',
    descricao: '', chaveIdempotencia: chave, autorId: 'admin' });
  const aberturas = await Promise.allSettled([abre('mediacao-operacional-a'), abre('mediacao-operacional-b')]);
  assert.equal(aberturas.filter(r => r.status === 'fulfilled').length, 1, 'Não duplica mediação concorrente');
  const { caso } = aberturas.find(r => r.status === 'fulfilled').value;
  await db.doc('orcamento/mediado').update({ 'contrato_financeiro.estado_execucao': 'contestado', estado_execucao: 'contestado' });
  const resolver = (extra = {}, uid = 'admin') => resolverExecucaoMediacao.run({ auth: { uid }, data: {
    idCaso: caso.id, estadoExecucao: 'em_execucao', motivo: 'Acordo documentado: retomar o serviço.', retirarBloqueio: true, ...extra } });
  await rejeita(() => resolver({}, 'forn'));
  await rejeita(() => resolver());
  await rejeita(() => fecharCaso(db, { idCaso: caso.id, conclusao: 'Sem decisão ainda', autorId: 'admin' }));
  await registrarDecisao(db, { idCaso: caso.id, tipoDecisao: 'manter', texto: 'Manter a contratação após acordo documentado.', autorId: 'admin' });
  await fecharCaso(db, { idCaso: caso.id, conclusao: 'Acordo registrado e análise concluída.', autorId: 'admin' });
  await rejeita(() => resolver({ estadoExecucao: 'cancelado_execucao' }));
  await db.doc(`plataforma_mediacao_casos/${caso.id}`).update({ retencao_efetiva_ativa: true });
  await rejeita(() => resolver({ retirarBloqueio: false }));
  await db.doc(`plataforma_repasses/${reserva.id}`).update({ estado: 'em_processamento' });
  await rejeita(() => resolver());
  await db.doc(`plataforma_repasses/${reserva.id}`).update({ estado: 'autorizado' });
  const r = await resolver();
  assert.equal((await resolver()).idempotente, true);
  assert.equal(r.efeitoFinanceiroExecutado, false);
  assert.equal((await db.doc('orcamento/mediado').get()).data().estado_execucao, 'em_execucao');
  assert.equal((await db.doc(`plataforma_repasses/${reserva.id}`).get()).data().estado, 'cancelado');
  assert.equal((await db.doc('plataforma_autorizacoes_repasses/mediado').get()).data().ativa, false);
  await rejeita(() => prepararOuAutorizarRepasse(db, { ...pedido('mediado', 9500), chaveIdempotencia: 'novo-sem-consentimento' }));
  const dossie = await consultarDetalheContratacao.run({ auth: { uid: 'admin' }, data: { idOrcamento: 'mediado' } });
  assert.equal(dossie.historico_mediacao.ultimo_caso_encerrado.id, caso.id);
  await autoriza();
  assert.equal((await prepararOuAutorizarRepasse(db, { ...pedido('mediado', 9500), chaveIdempotencia: 'novo-consentido' })).estado, 'autorizado');
  console.log('✓ Mediação: decisão e encerramento, resolução administrativa, revogação e nova conferência de repasse.');
};
