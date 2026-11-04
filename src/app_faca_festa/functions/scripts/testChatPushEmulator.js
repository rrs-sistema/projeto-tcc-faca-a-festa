"use strict";
require('./exigirEmuladorDemo').exigirEmuladorDemo('demo-chat-push');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const { admin } = require('../lib/shared/firebaseAdmin');
const { enviarPushMensagemChat } = require('../lib/functions/cotacao/notificarMensagemChat');

(async () => {
  const env = await initializeTestEnvironment({ projectId: 'demo-chat-push', firestore: {
    host: '127.0.0.1', port: 8080, rules: fs.readFileSync('firestore.rules', 'utf8'),
  }});
  const db = admin.firestore();
  const ids = { idCotacao: 'c', idFornecedor: 'f', idMensagem: 'm' };
  const ref = db.doc('cotacao/c/fornecedores/f/mensagens/m');
  const normal = { id_usuario: 'o', nome_usuario: 'Organizador', mensagem: 'Olá', lido: false };
  const enviados = [];
  let respostas;
  const messaging = { sendEachForMulticast: async payload => {
    enviados.push(payload);
    return { responses: respostas || payload.tokens.map(() => ({ success: true })) };
  }};
  const enviar = () => enviarPushMensagemChat(db, messaging, ids);
  try {
    await env.clearFirestore();
    await db.doc('usuarios/o').set({ tipo: 'O', ativo: true });
    await db.doc('usuarios/f').set({ tipo: 'F', ativo: true });
    await db.doc('cotacao/c').set({ id_usuario_solicitante: 'o' });
    await db.doc('cotacao/c/fornecedores/f').set({ id_fornecedor: 'f' });
    for (const uid of ['o', 'f']) await db.doc(`usuarios/${uid}/dispositivos_push/a`).set({ token: uid + '-token' });
    await db.doc('usuarios/f/dispositivos_push/b').set({ token: 'f-token-2' });
    await ref.set(normal);
    await enviar();
    assert.deepEqual(enviados[0].tokens.sort(), ['f-token', 'f-token-2']);
    assert.equal(enviados[0].data.id_destinatario, 'f');
    assert.equal(enviados[0].data.id_cotacao, 'c');
    await ref.set({ ...normal, id_usuario: 'f' });
    await enviar();
    assert.deepEqual(enviados[1].tokens, ['o-token']);
    for (const alteracao of [{ lido: true }, { sistema: true }, { id_usuario: 'sistema' }, { id_usuario: 'intruso' }, { mensagem: ' ' }]) {
      await ref.set({ ...normal, ...alteracao });
      await enviar();
      assert.equal(enviados.length, 2);
    }
    await ref.set(normal);
    await db.doc('usuarios/f').update({ preferencias_notificacao: { chat: false } });
    await enviar();
    assert.equal(enviados.length, 2);
    await db.doc('usuarios/f').update({ preferencias_notificacao: { chat: true }, ativo: false });
    await enviar();
    assert.equal(enviados.length, 2);
    await db.doc('usuarios/f').update({ ativo: true });
    respostas = [{ success: false, error: { code: 'messaging/registration-token-not-registered' } }, { success: true }];
    await enviar();
    assert.equal((await db.doc('usuarios/f/dispositivos_push/a').get()).exists, false);
    assert.equal((await db.doc('usuarios/f/dispositivos_push/b').get()).exists, true);
    await db.doc('cotacao/c/fornecedores/f').delete();
    await enviar();
    assert.equal(enviados.length, 3);

    const owner = env.authenticatedContext('o').firestore();
    const other = env.authenticatedContext('f').firestore();
    const device = owner.doc('usuarios/o/dispositivos_push/web');
    const data = { token: 'synthetic', plataforma: 'WEB', atualizado_em: firebase.firestore.FieldValue.serverTimestamp() };
    await assertSucceeds(device.set(data));
    await assertSucceeds(device.get());
    await assertFails(other.doc(device.path).get());
    await assertFails(other.doc(device.path).set(data));
    await assertFails(other.doc(device.path).delete());
    await assertFails(env.unauthenticatedContext().firestore().doc(device.path).get());
    await assertFails(device.set({ ...data, plataforma: 'WINDOWS' }));
    await assertFails(device.set({ ...data, token: '' }));
    await assertFails(device.set({ ...data, id_usuario: 'f' }));
    await assertSucceeds(device.delete());
    console.log('Chat push: destinatários, múltiplos dispositivos, preferências, tokens inválidos e isolamento validados; nenhum push real enviado.');
  } finally {
    await env.cleanup();
    await admin.app().delete();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
