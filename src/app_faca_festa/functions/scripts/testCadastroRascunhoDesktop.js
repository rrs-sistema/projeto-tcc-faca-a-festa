// Exclusivamente emuladores locais; não altera projetos reais.
const {spawn} = require('node:child_process');
const path = require('node:path');
const local = /^(127\.0\.0\.1|localhost|\[::1\]):\d+$/;
for (const key of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!local.test(process.env[key] || '')) throw Error(`${key} deve apontar ao emulador local.`);
}
process.env.GCLOUD_PROJECT = 'demo-cadastro-vinculo';
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'demo-cadastro-vinculo'});
async function main() {
  try {
    for (const uid of ['cadastro-owner', 'cadastro-other']) {
      try { await admin.auth().getUser(uid); }
      catch (e) {
        if (e.code !== 'auth/user-not-found') throw e;
        await admin.auth().createUser({uid, email: `${uid}@example.test`, password: 'TesteLocal123!'});
      }
      await admin.firestore().doc(`usuarios/${uid}`).set({tipo: 'O', ativo: true});
    }
    await new Promise((resolve, reject) => {
      const command = 'flutter test integration_test/cadastro_rascunho_vinculo_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true';
      const child = spawn('cmd.exe', ['/d', '/s', '/c', command], {cwd: path.resolve(__dirname, '../..'), stdio: 'inherit'});
      child.on('error', reject); child.on('exit', code => code === 0 ? resolve() : reject(Error(`SDK Windows: ${code}`)));
    });
    for (const nome of ['cardapios', 'orcamento', 'tarefa']) {
      const docs = await admin.firestore().collection(nome).where('id_evento', '==', 'cadastro-duravel').get();
      if (!docs.empty) throw Error(`Salvamento criou conteúdo indevido em ${nome}`);
    }
    console.log('Cadastro/vínculo SDK real: OK');
  } finally { await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
