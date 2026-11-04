require('./exigirEmuladorDemo').exigirEmuladorDemo('demo-economia-consultas');
const assert = require('node:assert/strict');
const {admin} = require('../lib/shared/firebaseAdmin');
const db = admin.firestore();
const {consultarResumoFinanceiroFornecedor} = require('../lib/functions/financeiro/comandosFinanceiroFornecedor');
const money = centavos => ({centavos, moeda: 'BRL'});

(async () => {
  await db.doc('usuarios/f').set({tipo: 'F', ativo: true});
  await db.doc('fornecedor/f').set({nome: 'Fornecedor sintético'});
  await db.doc('evento/e').set({id_usuario: 'o', status: 'finalizado'});
  await db.doc('orcamento/c').set({id_evento: 'e', id_fornecedor: 'f',
    id_solicitante: 'o', status: 'fechado', orcamento_fechado: true,
    valor_contratado_centavos: 315000,
    contrato_financeiro: {id_contrato: 'c', estado_comercial: 'contratado'}});
  await db.doc('plataforma_comissao_obrigacoes/comissao-c').set({
    id_obrigacao: 'comissao-c', id_contrato: 'c', id_evento: 'e', id_fornecedor: 'f',
    id_pagador: 'f', base_elegivel: money(315000), valor_original: money(15750),
    valor_liquidado: money(0), valor_ajustes_centavos: 0, saldo_centavos: 15750,
    politica_aplicada: {percentual_bps: 500, pagador: 'fornecedor', reversao: 'proporcional'},
    status: 'a_vencer',
  });
  await db.doc('plataforma_repasses/r').set({id_orcamento: 'c', id_fornecedor: 'f',
    valor_centavos: 100000, estado: 'confirmado', confirmado_em: admin.firestore.Timestamp.now()});

  const base = db.doc('fornecedor/f');
  const consultas = {
    contratos: db.collection('orcamento').where('id_fornecedor', '==', 'f'),
    comissao: db.collection('plataforma_comissao_obrigacoes').where('id_contrato', '==', 'c'),
    repasses: db.collection('plataforma_repasses').where('id_orcamento', '==', 'c'),
    custos: base.collection('custos_internos'),
    recebimentos: base.collection('contas_receber'),
    movimentos: base.collection('movimentos_caixa'),
  };
  const leituras = Object.fromEntries(Object.keys(consultas).map(k => [k, 0]));
  const transacao = db.runTransaction.bind(db);
  db.runTransaction = (executar, opcoes) => transacao(async tx => {
    const get = tx.get.bind(tx);
    tx.get = (ref, ...args) => {
      if (typeof ref.where === 'function') {
        for (const [nome, query] of Object.entries(consultas)) {
          if (ref.isEqual(query)) leituras[nome]++;
        }
      }
      return get(ref, ...args);
    };
    return executar(tx);
  }, opcoes);
  try {
    const r = await consultarResumoFinanceiroFornecedor.run({auth: {uid: 'f'}, data: {idFornecedor: 'f'}});
    assert.equal(r.origem, 'contratos_repasses');
    assert.equal(r.contratado, 3150);
    assert.equal(r.liquidoPrevisto, 2992.5);
    assert.equal(r.recebido, 1000);
    assert.equal(r.aReceber, 1992.5);
    assert.equal(r.entradasCaixa, 1000);
    for (const [nome, quantidade] of Object.entries(leituras)) {
      assert.equal(quantidade, 1, nome + ' deve ser consultado uma única vez por resumo');
    }
    console.log('PASS economia: fatos consultados uma vez, repasse reutilizado, totais preservados.', leituras);
  } finally {
    db.runTransaction = transacao;
  }
})().catch(e => {console.error(e); process.exitCode = 1;}).finally(() => db.terminate());
