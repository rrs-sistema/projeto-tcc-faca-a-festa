// Editor de regras no emulador: cancelar não grava; confirmar persiste uma regra.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) {
    throw Error('Use somente emuladores locais.');
  }
}
const projectId = 'demo-regras12';
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== projectId) {
  throw Error('Projeto inesperado.');
}
const admin = require('firebase-admin');
admin.initializeApp({ projectId });

async function main() {
  const db = admin.firestore();
  try {
    const uid = 'regras-owner';
    await admin.auth().createUser({
      uid,
      email: `${uid}@example.test`,
      password: 'TesteLocal123!',
    });
    await admin.auth().createUser({
      uid: 'regras-outro',
      email: 'regras-outro@example.test',
      password: 'TesteLocal123!',
    });
    await db.doc(`usuarios/${uid}`).set({ tipo: 'O', ativo: true });
    await db.doc('usuarios/regras-outro').set({ tipo: 'O', ativo: true });
    await db.doc('evento/festa-regras').set({
      id_evento: 'festa-regras',
      id_usuario: uid,
      nome_evento: 'Evento sintético de regra',
      total_adultos: 20,
      total_convidados: 20,
      total_criancas: 0,
      total_bebes: 0,
      custo_estimado: 2500,
      data: admin.firestore.Timestamp.now(),
    });
    await db.doc('cardapios/almoco').set({
      id_cardapio: 'almoco',
      id_evento: 'festa-regras',
      titulo: 'Almoço',
      ativo: true,
    });
    await db.doc('cardapios/almoco/itens/arroz').set({
      id_item: 'arroz',
      nome: 'Arroz',
      publico_alvo: 'todos',
      unidade: 'kg',
    });
    await db.doc('calculadora_operacao/festa-regras').set({
      id_evento: 'festa-regras',
      id_usuario: uid,
      versao: 1,
      revisao: 1,
      configuracao_planejamento: {
        base: 'manual',
        base_confirmada: true,
        publico: { adultos: 20, criancas: 0, bebes: 0 },
        duracao: 4,
        verba_alimentacao: 0,
      },
      execucao: {
        regras: [{
          id: 'menu_almoco_arroz',
          categoria: 'comida',
          nome: 'Arroz',
          tipo: 'comida',
          publico: 'todos',
          unidade: 'quilo',
          consumo: 0.05,
          preco: 5.75,
          selecionado: true,
          premissas: {
            id_evento: 'festa-regras',
            id_cardapio: 'almoco',
            id_item_cardapio: 'arroz',
            estado: 'pronto',
            rendimento: 2,
            revisada_pelo_organizador: true,
          },
        }],
      },
    });
    await db.doc('calculadora_festa/hist-regras12').set({
      id_evento: 'festa-regras',
      id_usuario: uid,
      origem: 'fixture-qa12',
      snapshot: { marcador: 'historico-aprovado', preco: 1 },
    });
    await new Promise((resolve, reject) => {
      const c = spawn('cmd.exe', ['/d', '/s', '/c',
        'flutter test integration_test/editor_regras_persistencia_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true'], {
        cwd: path.resolve(__dirname, '../..'),
        stdio: 'inherit',
      });
      c.on('error', reject);
      c.on('exit', (n) => n === 0 ? resolve() : reject(Error(`Windows SDK: ${n}`)));
    });
    const op = (await db.doc('calculadora_operacao/festa-regras').get()).data();
    const regra = op.execucao.regras[0];
    assert.equal(op.execucao.regras.length, 1);
    assert.equal(regra.id, 'menu_almoco_arroz');
    assert.equal(regra.preco, 8.5);
    assert.ok(Math.abs(regra.consumo - 0.08) < 1e-9);
    assert.equal(regra.premissas.id_evento, 'festa-regras');
    assert.ok(op.revisao > 1);
    assert.equal(op.configuracao_planejamento.duracao, 4);
    assert.equal(op.configuracao_planejamento.verba_alimentacao, 0);
    assert.equal(op.configuracao_planejamento.publico.adultos, 20);
    const evento = (await db.doc('evento/festa-regras').get()).data();
    assert.equal(evento.total_adultos, 20);
    assert.equal(evento.custo_estimado, 2500);
    const hist = (await db.doc('calculadora_festa/hist-regras12').get()).data();
    assert.deepEqual(hist.snapshot, { marcador: 'historico-aprovado', preco: 1 });
    assert.equal(
      (await db.collection('calculadora_operacao/festa-regras/aplicacoes').get()).size,
      0);
    console.log('Editor de regras: cancelar e fechar sem gravação; confirmar, repetir e retomar com Auth/Firestore reais OK.');
  } finally {
    await admin.app().delete();
  }
}
main().catch((e) => { console.error(e); process.exitCode = 1; });
