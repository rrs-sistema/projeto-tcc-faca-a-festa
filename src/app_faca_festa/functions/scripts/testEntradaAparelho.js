// Harness local: wrapper callable/autenticação/serviço reais; extrator determinístico.
// Nunca exportado em index.ts nem publicado. Provedor é testado separadamente.
const assert = require('node:assert/strict');
const { spawn, execFileSync } = require('node:child_process');
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw Error('Somente emuladores.');
process.env.GCLOUD_PROJECT = 'demo-calculadora-entrada';
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'demo-calculadora-entrada' });
const express = require('express');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { prepararEntradaAssistente } = require('../lib/services/calculadora/entradaAssistenteService');
const { aplicarEntradaCalculadora } = require('../lib/functions/calculadora/interpretarEntradaCalculadora');
const db = admin.firestore();
async function main() {
  // adb reverse is cleared whenever the physical device reconnects.
  for (const port of [8080, 9099, 5001]) execFileSync('D:\\src\\android-sdk\\platform-tools\\adb.exe', ['-s', '192.168.5.104:5555', 'reverse', `tcp:${port}`, `tcp:${port}`], { stdio: 'pipe' });
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  try { await admin.auth().deleteUser('owner'); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
  await admin.auth().createUser({ uid: 'owner', email: 'qa-calculadora@example.test', password: 'TesteLocal123!' });
  await db.doc('usuarios/owner').set({ tipo: 'O', ativo: true });
  await db.doc('evento/festa').set({ id_usuario: 'owner', custo_estimado: 1500 });
  await db.doc('cardapios/almoco').set({ id_evento: 'festa', titulo: 'Almoço', ativo: true });
  await db.doc('cardapios/almoco/itens/arroz').set({ nome: 'Arroz', unidade: 'kg', publico_alvo: 'todos', quantidade_final: 10, confirmado: true, disponibilidade: { nome: 'Arroz', unidade: 'kg', estado: 'cru', publico: 'todos', comprado: 2, estoque: 0 } });
  const interpretar = onCall({ cors: true }, req => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Entre na sua conta.');
    assert.equal(req.auth.uid, 'owner');
    return prepararEntradaAssistente(db, req.auth.uid, req.data, async () => ({ resumo: 'Compra de teste', perguntas: [], documento: { tipo: 'nota_compra', numero: 'QA-1', emissor: 'Fictício' }, acoes: [{ id: 'c', tipo: 'compra_adicionar', evidencia: 'Comprei 5 kg de arroz cru', id_cardapio: 'almoco', id_item: 'arroz', nome: 'Arroz', unidade: 'kg', estado: 'cru', quantidade: 5 }] }));
  });
  const app = express(); app.use(express.json({ limit: '8mb' }));
  app.use((req, _res, next) => { console.log('QA HTTP', req.method, req.path); next(); });
  app.post('/demo-calculadora-entrada/southamerica-east1/interpretarEntradaCalculadora', interpretar);
  app.post('/demo-calculadora-entrada/southamerica-east1/aplicarEntradaCalculadora', aplicarEntradaCalculadora);
  const server = app.listen(5001, '0.0.0.0');
  try {
    await new Promise((resolve, reject) => {
      const child = spawn('cmd.exe', ['/c', 'D:\\src\\flutter\\flutter_3.27.2\\bin\\flutter.bat test integration_test/entrada_inteligente_aparelho_test.dart -d 192.168.5.104:5555 --dart-define=CALCULADORA_QA=true --no-enable-impeller --no-dds'], { cwd: require('node:path').resolve(__dirname, '../..'), stdio: 'inherit' });
      child.on('error', reject); child.on('exit', code => code === 0 ? resolve() : reject(Error(`Teste no aparelho: ${code}`)));
    });
    console.log('Aparelho: SDK autenticado, callable, transação e duplicidade OK.');
  } finally { await new Promise(resolve => server.close(resolve)); await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
