const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');
const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require('../../node_modules/@firebase/rules-unit-testing');
const projectId = 'demo-mfa12';
const functionsPort = Number(process.env.MFA_TEST_FUNCTIONS_PORT || 5001);
for (const name of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  assert.match(process.env[name] || '', /^127\.0\.0\.1:\d+$/, 'Somente emuladores locais.');
}
admin.initializeApp({ projectId });

async function chamar(nome, token, data = {}) {
  const resposta = await fetch(
    'http://127.0.0.1:' + functionsPort + '/' + projectId + '/southamerica-east1/' + nome,
    {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
      body: JSON.stringify({ data }),
    },
  );
  const body = await resposta.json();
  if (body.error) {
    const erro = new Error(body.error.message);
    erro.status = body.error.status;
    throw erro;
  }
  return body.result;
}

async function login(uid, google) {
  const email = uid + '@example.test';
  await admin.auth().createUser(google ? { uid, email } : { uid, email, password: 'SenhaQA123!' });
  const endpoint = google ? 'signInWithIdp' : 'signInWithPassword';
  const payload = google ? {
    requestUri: 'http://localhost',
    postBody: new URLSearchParams({
      providerId: 'google.com',
      id_token: [
        Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url'),
        Buffer.from(JSON.stringify({ sub: uid, email, email_verified: true })).toString('base64url'),
        '',
      ].join('.'),
    }).toString(),
    returnSecureToken: true,
  } : { email, password: 'SenhaQA123!', returnSecureToken: true };
  const response = await fetch(
    'http://' + process.env.FIREBASE_AUTH_EMULATOR_HOST +
    '/identitytoolkit.googleapis.com/v1/accounts:' + endpoint + '?key=demo',
    {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    },
  );
  const body = await response.json();
  assert.ok(body.idToken, JSON.stringify(body.error));
  const decoded = JSON.parse(Buffer.from(body.idToken.split('.')[1], 'base64url'));
  assert.equal(typeof decoded.sub, 'string');
  return { uid: decoded.sub, token: body.idToken, authTime: decoded.auth_time, refreshToken: body.refreshToken };
}

async function renovarToken(refreshToken, authTime) {
  const response = await fetch(
    'http://' + process.env.FIREBASE_AUTH_EMULATOR_HOST + '/securetoken.googleapis.com/v1/token?key=demo',
    {
      method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: refreshToken }).toString(),
    },
  );
  const body = await response.json();
  assert.ok(body.id_token, JSON.stringify(body.error));
  const decoded = JSON.parse(Buffer.from(body.id_token.split('.')[1], 'base64url'));
  assert.equal(decoded.auth_time, authTime, 'Renovar o token preserva a sessão original.');
  return body.id_token;
}

async function main() {
  const db = admin.firestore();
  const host = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  const env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: host[0], port: Number(host[1]),
      rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
  try {
    for (const tipo of ['O', 'C', 'F', 'A']) {
      for (const google of [false, true]) {
        const { uid, token, authTime, refreshToken } = await login('perfil-' + tipo + '-' + google, google);
        const perfil = db.doc('usuarios/' + uid);
        await perfil.set({ tipo, ativo: true, nome: uid, email: uid + '@example.test' });
        await db.doc('evento/perfis-' + uid).set({ id_usuario: uid });
        if (tipo === 'F') await db.doc('fornecedor/' + uid).set({ ativo: true });
        const ctx = env.authenticatedContext(uid, { auth_time: authTime }).firestore();
        const prova = db.doc('mfa_sessoes/' + uid + '/autenticacoes/' + authTime);
        const privada = 'fornecedor/' + uid + '/custos_internos/custo';
        await db.doc(privada).set({ valor: 100 });
        await db.doc('auditoria_eventos/perfis-' + uid).set({ acao: 'QA' });
        const acesso = tipo === 'A'
          ? () => chamar('consultarDashboardFinanceiroAdmin', token)
          : tipo === 'F'
            ? () => chamar('consultarResumoFinanceiroFornecedor', token, { idFornecedor: uid })
            : () => chamar('consultarPrevisaoFinanceiraGerente', token, { idEvento: 'perfis-' + uid });
        // Organizadores têm acesso direto às operações permitidas ao próprio perfil.
        if (tipo === 'A' || tipo === 'F') {
          await assert.rejects(acesso, (erro) => erro.status === 'PERMISSION_DENIED');
          await assertFails(ctx.doc(privada).get());
          if (tipo === 'A') await assertFails(ctx.doc('auditoria_eventos/perfis-' + uid).get());
        } else {
          await acesso();
        }
        await assertSucceeds(ctx.doc('usuarios/' + uid).get());
        await assertSucceeds(ctx.doc('usuarios/' + uid).update({ mfa_login_opcional: false }));
        await assertFails(ctx.doc('usuarios/' + uid).update({ mfa_login_opcional: true }));
        await assertFails(ctx.doc(prova.path).set({ expiraEm: new Date(Date.now() + 60000) }));
        const inicio = await chamar('solicitarCodigoEmailMfa', token);
        assert.ok(inicio.emailMascarado);
        const record = await admin.auth().getUser(uid);
        const codigo = (await db.doc('_qa_mfa_email/' + record.email).get()).data().codigo;
        const verificado = await chamar('confirmarEmailMfa', token, { codigo });
        assert.ok(verificado.autorizacao);
        assert.equal((await chamar('consultarSessaoMfa', token)).verificada, true);
        if (tipo === 'A' || tipo === 'F') {
          const tokenRestaurado = await renovarToken(refreshToken, authTime);
          assert.equal((await chamar('consultarSessaoMfa', tokenRestaurado)).verificada, true);
          const confirmacao = (await prova.get()).data();
          await prova.update({ expiraEm: new Date(Date.now() - 1000) });
          assert.equal((await chamar('consultarSessaoMfa', tokenRestaurado)).verificada, false);
          await assert.rejects(acesso, (erro) => erro.status === 'PERMISSION_DENIED');
          await assertFails(ctx.doc(privada).get());
          await prova.set(confirmacao);
          await assertSucceeds(ctx.doc(privada).get());
          const outraSessao = env.authenticatedContext(uid, { auth_time: authTime + 1 }).firestore();
          await assertFails(outraSessao.doc(privada).get());
          if (tipo === 'A') await assertSucceeds(ctx.doc('auditoria_eventos/perfis-' + uid).get());
          await acesso();
          await assert.rejects(
            () => chamar('definirMfaOpcional', token, { ativar: false, autorizacao: verificado.autorizacao }),
            (erro) => erro.status === 'PERMISSION_DENIED',
          );
          await prova.delete();
          assert.equal((await chamar('consultarSessaoMfa', token)).verificada, false);
          await assert.rejects(acesso, (erro) => erro.status === 'PERMISSION_DENIED');
          await assertFails(ctx.doc(privada).get());
        } else {
          await chamar('definirMfaOpcional', token, { ativar: true, autorizacao: verificado.autorizacao });
          assert.equal((await perfil.get()).data().mfa_login_opcional, true);
          await assertFails(ctx.doc('usuarios/' + uid).update({ mfa_login_opcional: false }));
          await prova.delete();
          await assert.rejects(acesso, (erro) => erro.status === 'PERMISSION_DENIED');
          await chamar('definirMfaOpcional', token, { ativar: false, autorizacao: verificado.autorizacao });
          assert.equal((await perfil.get()).data().mfa_login_opcional, false);
          await acesso();
        }
      }
    }
    console.log('MFA por perfil: senha, Google, preferência opcional, sessão no servidor e regras validados.');
  } finally {
    await env.cleanup();
    await admin.app().delete();
  }
}
main().catch((erro) => { console.error(erro); process.exitCode = 1; });
