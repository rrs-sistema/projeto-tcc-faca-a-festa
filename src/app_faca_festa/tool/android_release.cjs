// APK assinado do Faça a Festa: publicação imutável no bucket deste projeto.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');
const root = path.resolve(__dirname, '..');
const origin = 'https://faca-a-festa.web.app';
const identity = 'faca-festa-android';

async function main() {
  const argument = process.argv.find((value) => value.startsWith('--apk='));
  if (!argument) throw Error('Informe --apk=caminho');
  const apk = path.resolve(argument.slice(6));
  const match = fs.readFileSync(path.join(root, 'pubspec.yaml'), 'utf8')
    .match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/m);
  if (!match) throw Error('Versão inválida.');
  const [, version, buildText] = match;
  const build = Number(buildText);
  const sdkProperty = fs.readFileSync(path.join(root, 'android/local.properties'), 'utf8')
    .match(/^sdk\.dir=(.+)$/m);
  if (!sdkProperty) throw Error('Android SDK não configurado.');
  const sdk = sdkProperty[1].trim().replace(/\\:/g, ':').replace(/\\\\/g, '\\');
  const versions = fs.readdirSync(path.join(sdk, 'build-tools')).filter((name) => /^\d+\.\d+\.\d+$/.test(name))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  const tools = path.join(sdk, 'build-tools', versions.at(-1));
  const java = path.join(process.env.ProgramFiles || 'C:/Program Files', 'Android/Android Studio/jbr/bin/java.exe');
  execFileSync(java, ['-jar', path.join(tools, 'lib/apksigner.jar'), 'verify', '--verbose', apk], { stdio: 'pipe' });
  const badging = execFileSync(path.join(tools, 'aapt2.exe'), ['dump', 'badging', apk], { encoding: 'utf8' });
  const packageInfo = badging.match(/package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'/);
  if (!packageInfo || packageInfo[1] !== 'com.rrs.system.technology.facafesta' ||
      packageInfo[2] !== buildText || packageInfo[3] !== version) {
    throw Error('APK não corresponde ao aplicativo e à versão selecionada.');
  }
  const bytes = fs.readFileSync(apk);
  const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
  const manifest = { identity, version, build, sha256, size: bytes.length,
    published: process.argv.includes('--publish'), url: `${origin}/android/packages/FacaFesta_${version}+${build}.apk` };
  if (manifest.published) {
    const current = await fetch(`${origin}/android/latest.json`, { signal: AbortSignal.timeout(15000) });
    if (current.ok && (current.headers.get('content-type') || '').includes('application/json')) {
      const previous = await current.json();
      if (previous.identity !== identity || !Number.isInteger(previous.build) || previous.build > build ||
          (previous.build === build && (previous.sha256 !== sha256 || previous.version !== version))) {
        throw Error('Build Android publicado é imutável. Publique um build maior.');
      }
    } else if (current.status !== 404 && !current.ok) {
      throw Error('Não foi possível consultar o catálogo Android publicado.');
    }
    const { Storage } = require('../functions/node_modules/@google-cloud/storage');
    const bucket = new Storage({ projectId: 'faca-a-festa' }).bucket('faca-a-festa.firebasestorage.app');
    const object = bucket.file(`android-faca-festa/releases/build-${build}/FacaFesta.apk`);
    const [exists] = await object.exists();
    let token;
    if (exists) {
      const [metadata] = await object.getMetadata();
      if (metadata.metadata?.sha256 !== sha256 || metadata.metadata?.version !== version) {
        throw Error('Este build Android já foi publicado com outros bytes.');
      }
      token = metadata.metadata.firebaseStorageDownloadTokens;
    } else {
      token = crypto.randomUUID();
      await bucket.upload(apk, { destination: object.name, preconditionOpts: { ifGenerationMatch: 0 }, metadata: {
        contentType: 'application/vnd.android.package-archive',
        contentDisposition: `attachment; filename="FacaFesta_${version}+${build}.apk"`,
        cacheControl: 'public,max-age=31536000,immutable',
        metadata: { sha256, version, build: buildText, identity, firebaseStorageDownloadTokens: token },
      } });
    }
    if (!token) throw Error('Pacote Android sem token de download.');
    manifest.url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(object.name)}?alt=media&token=${token}`;
  }
  const directory = path.join(root, 'release/android-feed/android');
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, 'latest.json'), JSON.stringify(manifest, null, 2));
  fs.copyFileSync(path.join(root, 'web/android/index.html'), path.join(directory, 'index.html'));
  if (!manifest.published) {
    fs.mkdirSync(path.join(directory, 'packages'), { recursive: true });
    fs.copyFileSync(apk, path.join(directory, 'packages', `FacaFesta_${version}+${build}.apk`));
  }
  console.log(JSON.stringify({ directory, version, build, sha256, size: bytes.length, published: manifest.published, signature: 'APK verified' }));
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
