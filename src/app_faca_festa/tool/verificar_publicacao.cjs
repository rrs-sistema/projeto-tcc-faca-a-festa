const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const root = path.resolve(__dirname, '..');
const version = process.argv[2];
const build = Number(process.argv[3]);
if (!version || !Number.isInteger(build)) throw Error('Informe versão e build.');
const origin = 'https://faca-a-festa.web.app';
const directory = path.join(root, '.dart_tool', `publication-${version}-${build}`);
fs.mkdirSync(directory, {recursive:true});
async function json(url) {
  const response = await fetch(url, {signal:AbortSignal.timeout(30000)});
  if (!response.ok || !response.headers.get('content-type')?.includes('application/json')) {
    throw Error('Resposta JSON inválida em ' + url);
  }
  return response.json();
}
async function download(manifest, platform) {
  if (manifest.version !== version || manifest.build !== build || manifest.published !== true) {
    throw Error('Versão pública divergente: ' + platform);
  }
  const url = new URL(manifest.url);
  if (url.hostname !== 'firebasestorage.googleapis.com' ||
      !url.pathname.startsWith('/v0/b/faca-a-festa.firebasestorage.app/o/')) {
    throw Error('Download fora do bucket do projeto.');
  }
  const response = await fetch(url, {signal:AbortSignal.timeout(180000)});
  if (!response.ok) throw Error('Download HTTP ' + response.status);
  const bytes = Buffer.from(await response.arrayBuffer());
  const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
  if (bytes.length !== manifest.size || sha256 !== manifest.sha256) throw Error('Integridade inválida: ' + platform);
  fs.writeFileSync(path.join(directory, platform === 'windows' ? 'setup.exe' : 'app.apk'), bytes);
  let signatureVerified;
  if (platform === 'windows') {
    const header = fs.readFileSync(path.join(root,'windows/runner/updater_public_key.h'),'utf8');
    const publicKey = header.match(/kUpdaterPublicKey\s*=\s*"([^"]+)"/)[1];
    const key = crypto.createPublicKey({key:Buffer.concat([
      Buffer.from('302a300506032b6570032100','hex'), Buffer.from(publicKey,'base64')]),
      format:'der',type:'spki'});
    signatureVerified = crypto.verify(null, bytes, key, Buffer.from(manifest.signature,'base64'));
    if (!signatureVerified) throw Error('Assinatura Windows inválida.');
  }
  return {platform, size:bytes.length, sha256, verified:true, signatureVerified};
}
async function main() {
  const web = await json(origin+'/version.json');
  if (web.version !== version || Number(web.build_number) !== build) throw Error('Versão web divergente.');
  const manifests = await Promise.all([
    json(origin+'/desktop/updates/latest.json'), json(origin+'/android/latest.json')]);
  const downloads = await Promise.all([download(manifests[0],'windows'), download(manifests[1],'android')]);
  for (const suffix of ['/', '/desktop/', '/android/', '/desktop/updates/appcast.xml']) {
    const response = await fetch(origin+suffix, {signal:AbortSignal.timeout(30000)});
    if (!response.ok) throw Error('Página indisponível: ' + suffix);
    await response.arrayBuffer();
  }
  const callable = await fetch('https://southamerica-east1-faca-a-festa.cloudfunctions.net/analisarCalculadoraFestaIA', {
    method:'POST', headers:{'Content-Type':'application/json'},body:'{"data":{}}',
    signal:AbortSignal.timeout(30000)});
  if (callable.status !== 401) throw Error('Callable sem autenticação retornou ' + callable.status);
  const result = {version,build,web:true,downloads,functionUnauthenticatedStatus:callable.status};
  fs.writeFileSync(path.join(directory,'verified.json'),JSON.stringify(result,null,2));
  console.log(JSON.stringify(result,null,2));
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
