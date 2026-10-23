const fs = require('node:fs'), path = require('node:path'), { spawn } = require('node:child_process');
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Use apenas emuladores locais.');
}
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'demo-calculadora-execucao' });
async function main() {
  try {
    const db = admin.firestore();
    for (const uid of ['execucao-owner', 'execucao-other']) {
      await admin.auth().createUser({ uid, email: `${uid}@example.test`, password: 'TesteLocal123!' });
      await db.doc(`usuarios/${uid}`).set({ tipo: 'O', ativo: true });
    }
    const fixture = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../.dart_tool/calculadora-plano-fixture.json'), 'utf8'));
    for (const [key, value] of Object.entries(fixture.plano.fontes)) {
      if (value != null) await db.doc(key).set(key === 'evento/evento' ? { ...value, id_usuario: 'execucao-owner' } : value);
    }
    await new Promise((resolve, reject) => {
      const c = spawn('cmd.exe', ['/d', '/s', '/c', 'flutter test integration_test/execucao_recuperacao_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true'], { cwd: path.resolve(__dirname, '../..'), stdio: 'inherit' });
      c.on('error', reject); c.on('exit', n => n === 0 ? resolve() : reject(Error(`Windows SDK: ${n}`)));
    });
    console.log('Execução: SDK Windows + callable + recuperação durável reais OK.');
  } finally { await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
