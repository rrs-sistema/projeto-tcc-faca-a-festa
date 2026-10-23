const { spawn } = require('node:child_process'), path = require('node:path');
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Use somente emuladores locais.');
}
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'demo-ergonomia10' });
async function main() {
  try {
    const uid = 'ergonomia-owner', db = admin.firestore();
    await admin.auth().createUser({ uid, email: `${uid}@example.test`, password: 'TesteLocal123!' });
    await db.doc(`usuarios/${uid}`).set({ tipo: 'O', ativo: true });
    await db.doc('evento/festa10').set({ id_evento: 'festa10', id_usuario: uid, nome_evento: 'Evento sintético de ergonomia', total_adultos: 20, total_convidados: 20, total_criancas: 0, total_bebes: 0, custo_estimado: 2500, data: admin.firestore.Timestamp.now() });
    await db.doc('calculadora_operacao/festa10').set({ id_evento: 'festa10', id_usuario: uid, versao: 1, revisao: 1, configuracao_planejamento: { base: 'manual', base_confirmada: true, publico: { adultos: 20, criancas: 0, bebes: 0 }, duracao: 4, verba_alimentacao: 0 } });
    await db.doc('cardapios/almoco').set({ id_cardapio: 'almoco', id_evento: 'festa10', titulo: 'Almoço', ativo: true });
    await db.doc('cardapios/almoco/itens/arroz').set({ id_item: 'arroz', nome: 'Arroz', publico_alvo: 'todos', unidade: 'kg' });
    await new Promise((resolve, reject) => {
      const c = spawn('cmd.exe', ['/d', '/s', '/c', 'flutter test integration_test/ergonomia_planejamento_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true'], { cwd: path.resolve(__dirname, '../..'), stdio: 'inherit' });
      c.on('error', reject); c.on('exit', n => n === 0 ? resolve() : reject(Error(`Windows SDK: ${n}`)));
    });
    console.log('Ergonomia: editores, confirmação e retomada com Auth/Firestore reais OK.');
  } finally { await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
