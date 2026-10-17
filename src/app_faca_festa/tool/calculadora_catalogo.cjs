const fs = require('fs');
const path = require('path');
const admin = require('../functions/node_modules/firebase-admin');
const root = path.resolve(__dirname, '..');
const rows = JSON.parse(fs.readFileSync(path.join(root, 'config/calculadora_catalogo_v1.json'), 'utf8'));
const apply = process.argv.includes('--apply');
const ids = new Set();
for (const row of rows) {
  if (ids.has(row.id) || !row.nome || row.tipo_evento !== 'todos' ||
      !Number.isFinite(row.quantidade_por_convidado_equivalente) ||
      row.quantidade_por_convidado_equivalente <= 0 || row.valor_unitario_medio !== 0 ||
      !/^https:\/\//.test(row.premissas.fonte)) throw Error('Catálogo inválido: ' + row.id);
  ids.add(row.id);
}
if (apply && process.env.FIRESTORE_EMULATOR_HOST) throw Error('Publicação não pode usar emulador.');
admin.initializeApp({projectId: 'faca-a-festa', credential: admin.credential.applicationDefault()});
const db = admin.firestore();
const editorial = [
  ['consumo_composicao_v2', 'Confira a composição da refeição',
    'Os itens do mesmo grupo dividem o consumo pelos pesos definidos. Confira se são alternativas ou porções completas independentes.'],
  ['precos_pendentes_v2', 'Complete os preços antes de concluir o orçamento',
    'Quantidades podem ser calculadas sem preços. Use valores reais por unidade de compra; não trate custo zero como gratuidade.'],
  ['cobertura_servicos_v2', 'Associe os itens cobertos por serviços',
    'Confirme quais itens estão integralmente cobertos por cada orçamento. Cotado, contratado e pago são estados diferentes.'],
];
async function main() {
  const documents = [];
  for (const row of rows) {
    documents.push(['calculadora_evento_itens', row.id, row]);
    documents.push(['calculadora_itens_base', row.id_item_base, {
      id: row.id_item_base, nome: row.nome, descricao: row.observacao,
      categoria_padrao: row.categoria, tipo_item: row.categoria,
      unidade_padrao: row.unidade, publico_alvo: 'todos', ativo: true,
      ordem: row.ordem, tags: row.premissas.aliases, fonte: row.premissas.fonte,
    }]);
  }
  for (const [id, titulo, descricao] of editorial) documents.push(['ia_sugestoes_base', id, {
    id, titulo, descricao, modulo: 'calculadora', tema: 'planejamento',
    tipo_evento: ['todos'], perfis_festa: ['todos'], ativo: true,
    versao: 1, origem: 'auditoria_2026_10_14', status_revisao: 'publicada',
    prioridade: 'alta', ordem: 0,
  }]);
  const refs = documents.map(([collection, id]) => db.collection(collection).doc(id));
  const result = await db.runTransaction(async transaction => {
    const snapshots = await transaction.getAll(...refs);
    const created = [];
    snapshots.forEach((doc, i) => {
      if (doc.exists) return; // Preserva ajustes administrativos existentes.
      created.push(`${documents[i][0]}/${documents[i][1]}`);
      if (apply) transaction.create(refs[i], {...documents[i][2],
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    return created;
  });
  console.log(JSON.stringify({project: 'faca-a-festa', mode: apply ? 'apply' : 'dry-run',
    validatedRules: rows.length, created: result, preserved: documents.length - result.length}, null, 2));
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
