const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const ts = require('typescript');
const source = fs.readFileSync(path.join(__dirname, '../src/functions/cotacao/fecharCotacao.ts'), 'utf8');
const codigo = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
const writes = [];
let commits = 0;
const dados = {
  'cotacao/pedido': {id_evento: 'festa', id_usuario_solicitante: 'owner', status: 'respondida', categoria_nome: 'Buffet'},
  'cotacao/pedido/fornecedores/fornecedor': {nome_fornecedor: 'Buffet'},
  'usuarios/owner': {nome: 'Organizador'},
};
function ref(caminho) { return {
  path: caminho, id: caminho.split('/').pop(),
  doc: (id = 'orcamento-novo') => ref(`${caminho}/${id}`),
  collection: (nome) => ref(`${caminho}/${nome}`),
  get: async () => {
    if (caminho.endsWith('/servicos')) return {docs: [{data: () => ({valor_estimado: 100, quantidade: 2, id_produto_servico: 'buffet'})}]};
    if (caminho.endsWith('/fornecedores')) return {docs: [{ref: ref(`${caminho}/fornecedor`), id: 'fornecedor', data: () => ({id_fornecedor: 'fornecedor'})}]};
    return {exists: !!dados[caminho], data: () => dados[caminho]};
  },
}; }
class HttpsError extends Error { constructor(code, msg) { super(msg); this.code = code; } }
const modulo = {exports: {}};
const stubs = {
  'firebase-admin/firestore': {FieldValue: {serverTimestamp: () => 'agora'}},
  'firebase-functions/v2/https': {onCall: (_, handler) => handler, HttpsError},
  'firebase-functions': {logger: {error: () => {}}},
  '../../shared/auth': {exigirUsuarioAutenticado: async (uid) => ({uid, tipo: 'O'}), exigirTipo: () => {}},
  '../../shared/firebaseAdmin': {admin: {firestore: () => ({collection: ref, batch: () => ({
    set: (r, data) => writes.push({path: r.path, data}),
    update: (r, data) => writes.push({path: r.path, data}), commit: async () => {commits++;},
  })})}},
};
new Function('module', 'exports', 'require', codigo)(modulo, modulo.exports, (nome) => stubs[nome] ?? require(nome));
(async () => {
  const fechar = modulo.exports.fecharCotacao;
  await assert.rejects(() => fechar({auth: {uid: 'outro'}, data: {idCotacao: 'pedido', idFornecedor: 'fornecedor'}}), (e) => e.code === 'permission-denied');
  assert.equal(commits, 0);
  const resultado = await fechar({auth: {uid: 'owner'}, data: {idCotacao: 'pedido', idFornecedor: 'fornecedor'}});
  assert.equal(resultado.idEvento, 'festa');
  const orc = writes.find((w) => w.path === 'orcamento/orcamento-novo').data;
  assert.equal(orc.status, 'fechado');
  assert.equal(orc.orcamento_fechado, true);
  assert.equal(orc.custo_estimado, 200);
  const gasto = writes.find((w) => w.path.includes('/orcamento_gasto/')).data;
  assert.equal(gasto.pago, 0);
  assert.equal(gasto.custo, 200);
  assert.equal(writes.find((w) => w.path === 'cotacao/pedido').data.status, 'concluida');
  dados['cotacao/pedido'].status = 'concluida';
  await assert.rejects(() => fechar({auth: {uid: 'owner'}, data: {idCotacao: 'pedido', idFornecedor: 'fornecedor'}}), (e) => e.code === 'failed-precondition');
  assert.equal(commits, 1);
  console.log('Cotação concluída: contratação consistente, pago zero e autorização preservada. OK');
})().catch((e) => { console.error(e); process.exitCode = 1; });
