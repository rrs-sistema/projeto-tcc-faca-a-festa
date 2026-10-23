// Exclusivamente emuladores locais; não altera projetos reais.
const {spawn} = require('node:child_process');
const path = require('node:path');
const local = /^(127\.0\.0\.1|localhost|\[::1\]):\d+$/;
for (const key of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!local.test(process.env[key] || '')) throw Error(`${key} deve apontar ao emulador local.`);
}
process.env.GCLOUD_PROJECT = 'demo-publico-planejamento';
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'demo-publico-planejamento'});
async function main() {
  const eventoId = `publico-festa-${Date.now()}`;
  try {
    for (const uid of ['publico-owner', 'publico-other']) {
      try { await admin.auth().getUser(uid); }
      catch (e) {
        if (e.code !== 'auth/user-not-found') throw e;
        await admin.auth().createUser({uid, email: `${uid}@example.test`, password: 'TesteLocal123!'});
      }
      await admin.firestore().doc(`usuarios/${uid}`).set({tipo: 'O', ativo: true});
    }
    await new Promise((resolve, reject) => {
      const command = `flutter test integration_test/publico_planejamento_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true --dart-define=PUBLICO_QA_EVENTO=${eventoId}`;
      const child = spawn('cmd.exe', ['/d', '/s', '/c', command], {cwd: path.resolve(__dirname, '../..'), stdio: 'inherit'});
      child.on('error', reject); child.on('exit', code => code === 0 ? resolve() : reject(Error(`SDK Windows: ${code}`)));
    });
    const evento = (await admin.firestore().doc(`evento/${eventoId}`).get()).data();
    if (evento.configuracao_planejamento || evento.lista_completude || evento.base_confirmada) throw Error('Conteúdo privado no evento compartilhado.');
    console.log('Público/completude SDK real: OK');
  } finally { await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
