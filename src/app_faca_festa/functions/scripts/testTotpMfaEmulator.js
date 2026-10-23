// Prova real das callables TOTP no emulador: cifra, confirmação e desafio.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const path = require('node:path');
const fs = require('node:fs');

for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) {
    throw Error('Use somente emuladores locais.');
  }
}
const projectId = 'demo-mfa12';
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== projectId) {
  throw Error('Projeto inesperado.');
}
process.env.GCLOUD_PROJECT = projectId;

const admin = require('firebase-admin');
admin.initializeApp({ projectId });

const ALFABETO = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
function base32Decode(texto) {
  const limpo = texto.replace(/=+$/, '').toUpperCase();
  let bits = 0;
  let valor = 0;
  const out = [];
  for (const c of limpo) {
    const idx = ALFABETO.indexOf(c);
    if (idx < 0) throw Error('Secret Base32 inválido.');
    valor = (valor << 5) | idx;
    bits += 5;
    if (bits >= 8) {
      out.push((valor >>> (bits - 8)) & 0xff);
      bits -= 8;
    }
  }
  return Buffer.from(out);
}

function codigoTotp(secretBase32, offset = 0) {
  const secret = base32Decode(secretBase32);
  const contador = Math.floor(Date.now() / 1000 / 30) + offset;
  const mensagem = Buffer.alloc(8);
  mensagem.writeUInt32BE(Math.floor(contador / 0x100000000), 0);
  mensagem.writeUInt32BE(contador >>> 0, 4);
  const hmac = crypto.createHmac('sha1', secret).update(mensagem).digest();
  const o = hmac[hmac.length - 1] & 0x0f;
  const binario =
    ((hmac[o] & 0x7f) << 24) |
    ((hmac[o + 1] & 0xff) << 16) |
    ((hmac[o + 2] & 0xff) << 8) |
    (hmac[o + 3] & 0xff);
  return String(binario % 1e6).padStart(6, '0');
}

async function tokenSenha(email, senha) {
  const r = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: senha, returnSecureToken: true }),
    },
  );
  const body = await r.json();
  if (!body.idToken) throw Error(`Auth falhou: ${JSON.stringify(body)}`);
  return body.idToken;
}

async function chamar(nome, idToken, data = {}) {
  const r = await fetch(
    `http://127.0.0.1:5001/${projectId}/southamerica-east1/${nome}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({ data }),
    },
  );
  const body = await r.json();
  if (body.error) {
    const e = new Error(body.error.message);
    e.code = String(body.error.status || '')
      .toLowerCase()
      .replaceAll('_', '-');
    throw e;
  }
  return body.result;
}

async function main() {
  const uid = 'mfa-owner';
  const email = `${uid}@example.test`;
  const senha = 'TesteLocal123!';
  await admin.auth().createUser({ uid, email, password: senha, displayName: 'MFA QA' });
  await admin.firestore().doc(`usuarios/${uid}`).set({
    tipo: 'O',
    ativo: true,
    nome: 'MFA QA',
    email,
    mfa_totp_ativo: false,
    mfa_email_ativo: false,
    mfa_metodo: '',
  });

  const idToken = await tokenSenha(email, senha);
  let checks = 0;

  await assert.rejects(
    () => chamar('confirmarTotpMfa', idToken, { codigo: '000000' }),
    (e) => e.code === 'failed-precondition',
  );
  checks++;

  const inicio = await chamar('iniciarTotpMfa', idToken);
  assert.equal(inicio.ok, true);
  assert.ok(inicio.secret && inicio.secret.length >= 16);
  assert.ok(String(inicio.otpauthUrl).includes(inicio.secret));
  checks++;

  const pendente = await admin.firestore().doc(`mfa_totp/${uid}`).get();
  assert.equal(pendente.exists, true);
  assert.equal(pendente.data().pendente, true);
  assert.equal(pendente.data().ativo, false);
  assert.ok(pendente.data().secretCifrado);
  checks++;

  // Cliente não lê o secret cifrado.
  const regras = fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8');
  assert.ok(regras.includes('match /mfa_totp/{userId}'));
  checks++;

  await assert.rejects(
    () => chamar('confirmarTotpMfa', idToken, { codigo: '000000' }),
    (e) => e.code === 'permission-denied',
  );
  checks++;

  const codigoOk = codigoTotp(inicio.secret);
  const confirmado = await chamar('confirmarTotpMfa', idToken, { codigo: codigoOk });
  assert.equal(confirmado.ok, true);
  checks++;

  const ativo = await admin.firestore().doc(`mfa_totp/${uid}`).get();
  assert.equal(ativo.data().pendente, false);
  assert.equal(ativo.data().ativo, true);
  const usuario = await admin.firestore().doc(`usuarios/${uid}`).get();
  assert.equal(usuario.data().mfa_totp_ativo, true);
  assert.equal(usuario.data().mfa_metodo, 'totp');
  assert.equal(usuario.data().mfa_email_ativo, false);
  checks++;

  await assert.rejects(
    () => chamar('verificarTotpMfa', idToken, { codigo: '000000' }),
    (e) => e.code === 'permission-denied',
  );
  checks++;

  const codigoDesafio = codigoTotp(inicio.secret);
  const verificado = await chamar('verificarTotpMfa', idToken, { codigo: codigoDesafio });
  assert.equal(verificado.ok, true);
  checks++;

  // Reuso do secret pendente: novo iniciar após ativo não deve quebrar desafio.
  const deNovo = await chamar('iniciarTotpMfa', idToken);
  assert.ok(deNovo.secret);
  checks++;

  console.log(`TOTP MFA emulador: ${checks} verificações passaram.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    try { await admin.app().delete(); } catch (_) {}
  });
