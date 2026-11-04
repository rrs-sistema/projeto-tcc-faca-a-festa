"use strict";
// Executado antes de qualquer import de Firebase ou escrita sintética.
function exigirEmuladorDemo(esperado, env = process.env) {
  if (!/^demo-[a-z0-9-]+$/.test(esperado)) throw Error("Projeto de teste precisa ser demo.");
  const local = v => /^(localhost|127\.0\.0\.1|\[::1\]):[1-9][0-9]{0,4}$/.test(v || "") && Number(v.slice(v.lastIndexOf(":") + 1)) <= 65535;
  if (!local(env.FIRESTORE_EMULATOR_HOST)) throw Error("Recusado: Firestore deve apontar para emulador loopback sem protocolo.");
  for (const nome of ["FIREBASE_AUTH_EMULATOR_HOST", "FIREBASE_DATABASE_EMULATOR_HOST", "FIREBASE_STORAGE_EMULATOR_HOST", "STORAGE_EMULATOR_HOST", "FUNCTIONS_EMULATOR_HOST"]) {
    if (env[nome] && !local(env[nome])) throw Error("Endpoint não local recusado: " + nome);
  }
  const projetos = [env.GCLOUD_PROJECT, env.GOOGLE_CLOUD_PROJECT, env.FIREBASE_PROJECT_ID];
  if (env.FIREBASE_CONFIG) {
    let config; try { config = JSON.parse(env.FIREBASE_CONFIG); } catch (_) { throw Error("FIREBASE_CONFIG deve ser JSON demo explícito, não arquivo externo."); }
    projetos.push(config.projectId);
    if (config.databaseURL) {
      const url = new URL(config.databaseURL);
      const localURL = ['localhost','127.0.0.1','[::1]'].includes(url.hostname);
      if (!localURL && ![esperado+'.firebaseio.com', esperado+'-default-rtdb.firebaseio.com'].includes(url.hostname)) throw Error('Non-local databaseURL refused.');
      // Remove the CLI-generated demo placeholder before importing any SDK.
      if (!localURL) delete config.databaseURL;
    }
    if (config.storageBucket) {
      if (![esperado+'.appspot.com',esperado+'.firebasestorage.app'].includes(config.storageBucket)) throw Error('Non-demo storage bucket refused.');
      delete config.storageBucket;
    }
    env.FIREBASE_CONFIG = JSON.stringify(config);
  }
  for (const id of projetos.filter(Boolean)) {
    if (!/^demo-[a-z0-9-]+$/.test(id)) throw Error("Projeto não-demo recusado: " + id);
    if (id !== esperado) throw Error("Projeto divergente recusado: " + id + " / " + esperado);
  }
  if (env === process.env) bloquearRedeExterna();
  env.GCLOUD_PROJECT = esperado;
  return esperado;
}
let bloqueada = false;
function bloquearRedeExterna() {
  if (bloqueada) return;
  bloqueada = true;
  function validar(destino) {
    const host = typeof destino === 'string' || destino instanceof URL
      ? new URL(destino).hostname : (destino?.hostname || destino?.host || 'localhost').replace(/:\d+$/, '');
    if (!['localhost', '127.0.0.1', '[::1]', '::1'].includes(host)) throw Error('External network refused by synthetic test: ' + host);
  }
  for (const nome of ['node:http', 'node:https']) {
    const mod = require(nome);
    for (const metodo of ['request', 'get']) {
      const original = mod[metodo];
      mod[metodo] = function(...args) { validar(args[0]); if (args[1] && typeof args[1] === 'object') validar(args[1]); return original.apply(this, args); };
    }
  }
  const http2 = require('node:http2'), conectar = http2.connect;
  http2.connect = function(destino, ...args) { validar(destino); return conectar.call(this, destino, ...args); };
  const fetchOriginal = globalThis.fetch;
  globalThis.fetch = async function(destino, ...args) { validar(destino?.url || destino); return fetchOriginal.call(this, destino, ...args); };
}
module.exports = { exigirEmuladorDemo, bloquearRedeExterna };
