// QA local autenticado. Não usa credenciais nem documentos de produção.
const { spawn, execFileSync } = require('node:child_process');
const path = require('node:path');
const fs = require('node:fs');
for (const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST']) if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Somente emuladores locais.');
process.env.GCLOUD_PROJECT = 'demo-calculadora-entrada';
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'demo-calculadora-entrada' });
const express = require('express');
const { onCall } = require('firebase-functions/v2/https');
const { prepararEntradaAssistente } = require('../lib/services/calculadora/entradaAssistenteService');
const { aplicarEntradaCalculadora } = require('../lib/functions/calculadora/interpretarEntradaCalculadora');
const { aplicarPlanoCalculadora, revisarRefeicaoCalculadora } = require('../lib/functions/calculadora/aplicarPlanoCalculadora');
const { normalizarFonte } = require('../lib/services/calculadora/executarPlanoService');
const { isDeepStrictEqual } = require('node:util');
async function main() {
  const db = admin.firestore();
  const device = process.env.CALCULADORA_QA_DEVICE ?? '192.168.5.104:5555';
  if (!/^[A-Za-z0-9_.:-]{1,100}$/.test(device)) throw Error('Identificador ADB inválido.');
  for (const port of [8080, 9099, 5001]) execFileSync('D:\\src\\android-sdk\\platform-tools\\adb.exe', ['-s', device, 'reverse', `tcp:${port}`, `tcp:${port}`], { stdio: 'pipe' });
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  for (const [uid, email] of [['owner', 'qa-calculadora@example.test'], ['other', 'outro@example.test']]) {
    try { await admin.auth().deleteUser(uid); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
    await admin.auth().createUser({ uid, email, password: 'TesteLocal123!' });
    await db.doc(`usuarios/${uid}`).set({ tipo: 'O', ativo: true });
  }
  const catalogo = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../config/calculadora_catalogo_v1.json'), 'utf8'));
  for (const row of catalogo) await db.doc(`calculadora_evento_itens/${row.id}`).set(row);
  const interpretar = onCall({ cors: true }, req => prepararEntradaAssistente(db, req.auth?.uid, req.data, async ctx => {
    const arroz = ctx.itens.find(i => i.id_item && i.nome === 'Arroz' && i.id_cardapio === 'plano_inicial_festa');
    if (!arroz) throw Error('Destino QA ausente.');
    const item = { id_cardapio: arroz.id_cardapio, id_item: arroz.id_item, unidade: 'kg', estado: 'cru' };
    return { resumo: 'Compra, preço e financeiro sintéticos', perguntas: [], documento: { tipo: 'nota_compra', numero: 'QA-JORNADA-1', emissor: 'Fornecedor fictício' }, acoes: [
      { id: 'c', tipo: 'compra_adicionar', ...item, quantidade: 1, evidencia: 'Comprei 1 kg de arroz cru' },
      { id: 'p', tipo: 'preco', ...item, valor: 6, evidencia: 'Preço de R$ 6/kg' },
      { id: 'd', tipo: 'despesa', nome: 'Compra de mantimentos QA', valor: 60, evidencia: 'Compra custou R$ 60' },
      { id: 'pg', tipo: 'pagamento', id_orcamento: 'nova:d', valor: 20, evidencia: 'Já paguei R$ 20 dessa compra' },
      { id: 'o', tipo: 'cotacao', nome: 'Decoração QA', valor: 500, evidencia: 'Cotação de decoração: R$ 500' },
    ] };
  }));
  const app = express(); app.use(express.json({ limit: '8mb' }));
  const diagnosticados = new Set();
  function decodificar(v) {
    if (Array.isArray(v)) return v.map(decodificar);
    if (v && typeof v === 'object') {
      if (v['@type'] === 'type.googleapis.com/google.protobuf.Int64Value') return Number(v.value);
      return Object.fromEntries(Object.entries(v).map(([k, a]) => [k, decodificar(a)]));
    }
    return v;
  }
  for (const [name, fn] of Object.entries({ interpretarEntradaCalculadora: interpretar, aplicarEntradaCalculadora, aplicarPlanoCalculadora, revisarRefeicaoCalculadora })) {
    app.post(`/demo-calculadora-entrada/southamerica-east1/${name}`, async (req, res, next) => {
      try {
        const pedido = req.body?.data?.pedido;
        if (name === 'aplicarPlanoCalculadora' && /^[\w-]+$/.test(pedido) && !diagnosticados.has(pedido)) {
          diagnosticados.add(pedido);
          const fontes = decodificar(req.body?.data?.plano?.fontes ?? {});
          const atuais = Object.fromEntries(await Promise.all(Object.keys(fontes).map(async p => [p, normalizarFonte((await db.doc(p).get()).data() ?? null)])));
          const diferentes = Object.keys(fontes).filter(p => !isDeepStrictEqual(fontes[p], atuais[p]));
          fs.writeFileSync(path.resolve(__dirname, `../../.dart_tool/jornada-fontes-qa-${pedido}.json`), JSON.stringify({ fontes, atuais, diferentes }, null, 2));
          console.log('QA comparação das fontes', pedido, JSON.stringify(diferentes));
        }
        return fn(req, res);
      } catch (e) { next(e); }
    });
  }
  const server = app.listen(5001, '0.0.0.0');
  try {
    await new Promise((resolve, reject) => {
      const child = spawn('cmd.exe', ['/c', `D:\\src\\flutter\\flutter_3.27.2\\bin\\flutter.bat test integration_test/jornada_calculadora_aparelho_test.dart -d ${device} --dart-define=CALCULADORA_QA=true --no-enable-impeller --no-dds`], { cwd: path.resolve(__dirname, '../..'), stdio: 'inherit' });
      child.on('error', reject); child.on('exit', code => code === 0 ? resolve() : reject(Error(`Jornada no aparelho: ${code}`)));
    });
    console.log('Cobertura suplementar de módulos concluída em demo. Cadastro pela UI e reinício do processo usam testHomologacao12Desktop.js.');
  } finally { await new Promise(resolve => server.close(resolve)); await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
