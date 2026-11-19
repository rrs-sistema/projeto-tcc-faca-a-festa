// Executa após o Hosting: nunca remove um pacote antes de publicar o catálogo.
// Sem --apply apenas lista o que seria removido.
const assert = require('node:assert/strict');
const project = 'faca-a-festa';
const origin = 'https://faca-a-festa.web.app';
const day = 24 * 60 * 60 * 1000;
const platforms = [
  { name: 'windows', identity: 'faca-festa-windows-x64',
    feed: '/desktop/updates/latest.json', prefix: 'desktop-faca-festa/releases/',
    filename: 'FacaFesta_Setup.exe', appcast: '/desktop/updates/appcast.xml' },
  { name: 'android', identity: 'faca-festa-android',
    feed: '/android/latest.json', prefix: 'android-faca-festa/releases/',
    filename: 'FacaFesta.apk' },
];

function objectName(spec, build) {
  return `${spec.prefix}build-${build}/${spec.filename}`;
}

function validateCatalog(catalog, spec, bucketName) {
  assert.equal(catalog.identity, spec.identity, 'Identidade do catálogo inválida');
  assert.equal(catalog.published, true, 'Catálogo não publicado');
  assert.ok(Number.isSafeInteger(catalog.build) && catalog.build > 0, 'Build inválido');
  assert.match(catalog.sha256, /^[a-f0-9]{64}$/);
  assert.ok(Number.isSafeInteger(catalog.size) && catalog.size > 0, 'Tamanho inválido');
  const url = new URL(catalog.url);
  assert.equal(url.origin, 'https://firebasestorage.googleapis.com');
  assert.equal(url.pathname,
    `/v0/b/${bucketName}/o/${encodeURIComponent(objectName(spec, catalog.build))}`,
    'Catálogo deve apontar para o pacote do próprio bucket');
}

function planRetention(files, spec, catalog, now = Date.now()) {
  const known = files.flatMap(file => {
    const metadata = file.metadata || {};
    const suffix = file.name.startsWith(spec.prefix) ? file.name.slice(spec.prefix.length) : '';
    const match = suffix.match(/^build-([1-9]\d*)\/([^/]+)$/);
    if (!match || match[2] !== spec.filename || metadata.metadata?.identity !== spec.identity) return [];
    const build = Number(match[1]);
    const created = Date.parse(metadata.timeCreated);
    if (!Number.isSafeInteger(build) || !Number.isFinite(created) ||
        !/^\d+$/.test(String(metadata.generation || '')) ||
        !/^\d+$/.test(String(metadata.size || ''))) return [];
    return [{ name: file.name, build, created, generation: String(metadata.generation),
      bytes: Number(metadata.size), sha256: metadata.metadata?.sha256 }];
  });
  const current = known.find(file => file.name === objectName(spec, catalog.build));
  assert.ok(current && current.sha256 === catalog.sha256 && current.bytes === catalog.size,
    'Pacote atual ausente ou divergente: limpeza cancelada');
  const previous = known.filter(file => file.build < catalog.build)
    .sort((a, b) => b.build - a.build).slice(0, 2);
  const protectedNames = new Set([current, ...previous].map(file => file.name));
  const remove = known.filter(file => !protectedNames.has(file.name) &&
    file.build < catalog.build && now - file.created >= 7 * day);
  return { platform: spec.name, currentBuild: catalog.build,
    retained: known.filter(file => !remove.includes(file)).map(file => file.name),
    remove, bytesToRemove: remove.reduce((sum, file) => sum + file.bytes, 0) };
}

async function readCatalog(spec, bucketName, request = fetch) {
  const response = await request(origin + spec.feed, {
    cache: 'no-store', signal: AbortSignal.timeout(15000),
  });
  if (response.status === 404) return null; // Plataforma ainda não publicada.
  assert.ok(response.ok && response.headers.get('content-type')?.includes('application/json'),
    'Não foi possível verificar o catálogo publicado');
  const catalog = await response.json();
  validateCatalog(catalog, spec, bucketName);
  if (spec.appcast) {
    const xmlResponse = await request(origin + spec.appcast, {
      cache: 'no-store', signal: AbortSignal.timeout(15000),
    });
    assert.ok(xmlResponse.ok, 'Appcast indisponível');
    const xml = await xmlResponse.text();
    const enclosure = xml.match(/<enclosure\b[^>]*>/)?.[0] || '';
    const url = enclosure.match(/\burl="([^"]+)"/)?.[1]?.replaceAll('&amp;', '&');
    const build = enclosure.match(/sparkle:version="(\d+)"/)?.[1];
    assert.equal(url, catalog.url, 'Appcast e catálogo divergentes: limpeza cancelada');
    assert.equal(build, String(catalog.build), 'Build do appcast divergente');
  }
  return catalog;
}

async function applyPlan(bucket, plan, spec, catalog, read = readCatalog) {
  for (const file of plan.remove) {
    // Se outra publicação ocorreu durante a limpeza, interrompe o plano antigo.
    const current = await read(spec, bucket.name);
    assert.ok(current && current.build === catalog.build &&
      current.sha256 === catalog.sha256 && current.url === catalog.url,
    'O catálogo mudou durante a limpeza; execute novamente');
    // Uma substituição concorrente do objeto nunca é apagada pelo plano antigo.
    await bucket.file(file.name).delete({ ifGenerationMatch: file.generation });
  }
}

async function hostingRetention(client, apply = false) {
  const name = `sites/${project}/channels/live`;
  const url = `https://firebasehosting.googleapis.com/v1beta1/${name}`;
  const { data } = await client.request({ url, timeout: 15000 });
  assert.equal(data.name, name, 'Canal Hosting fora do projeto');
  assert.ok(Number.isInteger(data.retainedReleaseCount) && data.retainedReleaseCount >= 1,
    'Retenção atual do Hosting desconhecida');
  // A API conta releases ANTERIORES; dois anteriores + o atual = três.
  // Respeita uma configuração existente que retenha ainda menos versões.
  const previousReleases = Math.min(data.retainedReleaseCount, 2);
  if (apply && data.retainedReleaseCount > previousReleases) {
    await client.request({ url, method: 'PATCH',
      params: { updateMask: 'retainedReleaseCount' },
      data: { retainedReleaseCount: previousReleases }, timeout: 15000 });
  }
  return { channel: name, previousReleasesBefore: data.retainedReleaseCount,
    previousReleasesAfter: previousReleases, totalReleasesAfter: previousReleases + 1 };
}

async function main() {
  const args = process.argv.slice(2);
  assert.ok(args.every(arg => ['--apply', '--dry-run'].includes(arg)), 'Argumento desconhecido');
  assert.ok(!(args.includes('--apply') && args.includes('--dry-run')), 'Escolha apply ou dry-run');
  const bucketName = process.env.FACA_FESTA_UPDATE_BUCKET || `${project}.firebasestorage.app`;
  assert.ok(bucketName.startsWith(`${project}.`), 'Bucket fora do projeto');
  const { Storage } = require('../functions/node_modules/@google-cloud/storage');
  const bucket = new Storage({ projectId: project }).bucket(bucketName);
  const [bucketMetadata] = await bucket.getMetadata();
  const { GoogleAuth } = require('../functions/node_modules/google-auth-library');
  const hostingClient = await new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/firebase'],
  }).getClient();
  const hosting = await hostingRetention(hostingClient);
  const prepared = [];
  // Prepara e valida todas as plataformas antes de remover qualquer objeto.
  for (const spec of platforms) {
    const catalog = await readCatalog(spec, bucketName);
    if (!catalog) continue;
    const [files] = await bucket.getFiles({ prefix: spec.prefix });
    prepared.push({ spec, catalog, plan: planRetention(files, spec, catalog) });
  }
  if (args.includes('--apply')) {
    await hostingRetention(hostingClient, true);
    for (const entry of prepared) await applyPlan(bucket, entry.plan, entry.spec, entry.catalog);
  }
  console.log(JSON.stringify({ mode: args.includes('--apply') ? 'applied' : 'dry-run',
    keepVersions: 3, graceDays: 7,
    softDeleteRetentionSeconds: bucketMetadata.softDeletePolicy?.retentionDurationSeconds || 0,
    hosting, plans: prepared.map(entry => entry.plan) }, null, 2));
}

module.exports = { platforms, objectName, validateCatalog, planRetention, readCatalog, applyPlan, hostingRetention };
if (require.main === module) main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
