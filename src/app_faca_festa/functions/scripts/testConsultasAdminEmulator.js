require('./exigirEmuladorDemo').exigirEmuladorDemo('demo-consultas-admin');
const assert = require('node:assert/strict');
const { admin } = require('../lib/shared/firebaseAdmin');
const { consultarCentralContratacoes, consultarDetalheContratacao } =
  require('../lib/functions/financeiro/consultarCentralContratacoes');
const { consultarDashboardFinanceiroAdmin } =
  require('../lib/functions/financeiro/consultarDashboardFinanceiroAdmin');
const { consultarCasoMediacaoFn } = require('../lib/functions/financeiro/comandosMediacao');

const db = admin.firestore();
const valor = centavos => ({ centavos, moeda: 'BRL' });
const chamar = (funcao, data, uid = 'adm') => funcao.run({ auth: { uid }, data });

(async () => {
  const lote = db.batch();
  const gravar = (path, dados) => lote.set(db.doc(path), dados);
  gravar('usuarios/adm', { tipo: 'A' });
  gravar('usuarios/org', { tipo: 'C', nome: 'Organizador sintético' });
  gravar('usuarios/terceiro', { tipo: 'C' });
  gravar('evento/e', { id_usuario: 'org', nome: 'Festa sintética', status: 'planejamento' });
  gravar('fornecedor/f', { razao_social: 'Fornecedor sintético' });
  for (let i = 0; i < 65; i++) {
    const id = `orc-${String(i).padStart(2, '0')}`;
    const contratado = i === 55;
    gravar(`orcamento/${id}`, {
      id_evento: 'e', id_fornecedor: contratado ? 'f' : 'outro', id_solicitante: 'org',
      nome: contratado ? 'Decoração sintética' : 'Oportunidade',
      status: contratado ? 'fechado' : 'pendente',
      ...(contratado ? {
        valor_contratado_centavos: 315000, pago: 0,
        contrato_financeiro: { id_contrato: 'canonico', estado_comercial: 'contratado' },
      } : {}),
    });
  }
  gravar('plataforma_comissao_obrigacoes/comissao-canonico', {
    id_contrato: 'canonico', id_evento: 'e', id_fornecedor: 'f', status: 'a_vencer',
    valor_original: valor(15750), valor_liquidado: valor(0), base_elegivel: valor(315000),
    politica_aplicada: { percentual_bps: 500, pagador: 'fornecedor' },
  });
  gravar('plataforma_alocacoes/alocacao', { id_orcamento: 'orc-55', valor_centavos: 200000 });
  gravar('plataforma_repasses/confirmado', {
    id_orcamento: 'orc-55', valor_centavos: 100000, estado: 'confirmado',
  });
  gravar('plataforma_repasses/pendente', {
    id_orcamento: 'orc-55', valor_centavos: 10000, estado: 'autorizado',
  });
  for (let i = 0; i < 51; i++) {
    gravar(`plataforma_mediacao_casos/encerrado-${i}`, {
      id_contrato: 'canonico', id_orcamento: 'orc-55', estado: 'fechado',
    });
  }
  gravar('plataforma_mediacao_casos/novo', {
    id_contrato: 'canonico', id_orcamento: 'orc-55', id_evento: 'e',
    id_contratante: 'org', estado: 'em_analise', id_responsavel: 'adm',
  });
  gravar('plataforma_mediacao_registros/nota', {
    id_caso: 'novo', texto: 'Nota sintética interna', tipo: 'nota_interna', visibilidade: 'interna',
  });
  gravar('plataforma_mediacao_registros/relato', {
    id_caso: 'novo', texto: 'Relato sintético', tipo: 'info_compartilhavel', visibilidade: 'compartilhavel',
  });
  await lote.commit();

  const comissoesLidas = [];
  const fornecedoresLidos = [];
  const getAll = db.getAll.bind(db);
  db.getAll = (...refs) => {
    comissoesLidas.push(...refs.filter(ref => ref.parent?.id === 'plataforma_comissao_obrigacoes'));
    fornecedoresLidos.push(...refs.filter(ref => ref.parent?.id === 'fornecedor').map(ref => ref.id));
    return getAll(...refs);
  };
  try {
    const primeira = await chamar(consultarCentralContratacoes, { limite: 5 });
    assert.equal(primeira.paginacao.total_filtrado_amostra, 65);
    assert.equal(primeira.linhas.length, 5);
    assert.equal(primeira.metricas_amostra.qtd_casos_abertos_amostra, 1);
    assert.equal(comissoesLidas.length, 5, 'Apenas a página recebe enriquecimento financeiro.');
    assert.deepEqual(fornecedoresLidos, ['outro'], 'A identidade de páginas seguintes fica sob demanda.');
  } finally {
    db.getAll = getAll;
  }

  const segunda = await chamar(consultarCentralContratacoes, { offset: 50, limite: 15 });
  const contrato = segunda.linhas.find(l => l.idOrcamento === 'orc-55');
  assert.equal(contrato.casoAberto, true);
  assert.equal(contrato.aReceberClienteCentavos, 115000);
  assert.equal(contrato.repassadoCentavos, 100000);
  assert.equal(contrato.pendenteRepasseCentavos, 199250);

  const busca = await chamar(consultarCentralContratacoes, { busca: 'fornecedor sintético', limite: 5 });
  assert.equal(busca.paginacao.total_filtrado_amostra, 1);
  assert.equal(busca.linhas[0].idOrcamento, 'orc-55');

  const filtrada = await chamar(consultarCentralContratacoes, { casoAberto: true, idResponsavel: 'adm' });
  assert.equal(filtrada.paginacao.total_filtrado_amostra, 1);
  assert.equal(filtrada.linhas[0].idCasoAberto, 'novo');
  const painel = await chamar(consultarDashboardFinanceiroAdmin, { idFornecedor: 'f' });
  assert.equal(painel.paginacao.retornados, 1);
  assert.equal(painel.volumeContratadoCentavos, 315000);
  assert.equal(painel.comissaoGeradasCentavos, 15750);

  const detalhe = await chamar(consultarDetalheContratacao, { idOrcamento: 'orc-55', incluirRegistros: true });
  const adminCaso = await chamar(consultarCasoMediacaoFn, { idCaso: 'novo' });
  assert.deepEqual(detalhe.historico_mediacao.consulta_caso, {
    caso: adminCaso.caso, registros: adminCaso.registros,
  });
  const orgCaso = await chamar(consultarCasoMediacaoFn, { idCaso: 'novo' }, 'org');
  assert.deepEqual(orgCaso.registros.map(r => r.id), ['relato']);
  await assert.rejects(chamar(consultarCasoMediacaoFn, { idCaso: 'novo' }, 'terceiro'), { code: 'permission-denied' });
  await assert.rejects(chamar(consultarDetalheContratacao, { idOrcamento: 'orc-55', incluirRegistros: true }, 'org'),
    { code: 'permission-denied' });
  console.log('PASS paginação, comissão, repasses, histórico consolidado e autorização.');
})().catch(e => { console.error(e); process.exitCode = 1; }).finally(() => db.terminate());
