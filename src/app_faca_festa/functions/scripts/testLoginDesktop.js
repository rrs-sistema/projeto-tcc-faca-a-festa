// Login pela LoginScreen real no emulador Auth. Conta sintética; sem Google/MFA.
const { spawn } = require('node:child_process');
const path = require('node:path');
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) {
    throw Error('Use somente emuladores locais.');
  }
}
const projectId = 'demo-login12';
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== projectId) {
  throw Error('Projeto inesperado.');
}
const admin = require('firebase-admin');
admin.initializeApp({ projectId });

async function main() {
  try {
    const uid = 'login-owner';
    await admin.auth().createUser({
      uid,
      email: `${uid}@example.test`,
      password: 'TesteLocal123!',
      displayName: 'Organizador QA',
    });
    await admin.firestore().doc(`usuarios/${uid}`).set({
      tipo: 'O',
      ativo: true,
      nome: 'Organizador QA',
      email: `${uid}@example.test`,
    });
    await new Promise((resolve, reject) => {
      const c = spawn('cmd.exe', ['/d', '/s', '/c',
        'flutter test integration_test/login_interface_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true'], {
        cwd: path.resolve(__dirname, '../..'),
        stdio: 'inherit',
      });
      c.on('error', reject);
      c.on('exit', (n) => n === 0 ? resolve() : reject(Error(`Windows login: ${n}`)));
    });
    console.log('Login pela interface: validação, negativa, confirmação e retomada com Auth real OK.');
  } finally {
    await admin.app().delete();
  }
}
main().catch((e) => { console.error(e); process.exitCode = 1; });
