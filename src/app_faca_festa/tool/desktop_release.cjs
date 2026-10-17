// Own application identity/key/catalog. No reference-project credentials.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const {execFileSync} = require('child_process');
const root = path.resolve(__dirname, '..');
const project = 'faca-a-festa';
const origin = 'https://faca-a-festa.web.app';
const identity = 'faca-festa-windows-x64';
const key = process.env.FACA_FESTA_UPDATE_PRIVATE_KEY || path.join(process.env.LOCALAPPDATA || '', 'FacaFesta/publishing/desktop-ed25519.key');
const tool = process.env.WINSPARKLE_TOOL || path.join(root, '.dart_tool/winsparkle-0.9.4/WinSparkle-0.9.4/bin/winsparkle-tool.exe');
const run = args => execFileSync(tool, args, {encoding:'utf8'});
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function assertAdvance(current, next) {
  if (current.identity !== identity || !Number.isInteger(current.build)) throw Error('Catálogo existente inválido.');
  if (current.build > next.build || current.build === next.build && (current.sha256 !== next.sha256 || current.version !== next.version)) {
    throw Error('Build publicado é imutável. Publique um build maior.');
  }
}
function writeFeed(manifest) {
  const directory = path.join(root, 'release/desktop-feed/desktop');
  fs.mkdirSync(path.join(directory, 'updates'), {recursive:true});
  fs.writeFileSync(path.join(directory,'updates/latest.json'), JSON.stringify(manifest,null,2));
  const url = manifest.url.replaceAll('&','&amp;');
  fs.writeFileSync(path.join(directory,'updates/appcast.xml'), `<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><title>Faça a Festa</title><item><title>Versão ${manifest.version}</title><enclosure url="${url}" sparkle:version="${manifest.build}" sparkle:shortVersionString="${manifest.version}" sparkle:os="windows" sparkle:edSignature="${manifest.signature}" length="${manifest.size}" type="application/octet-stream" /></item></channel></rss>`);
  fs.copyFileSync(path.join(root,'web/desktop/index.html'),path.join(directory,'index.html'));
  return directory;
}
async function main() {
  const relativeKey = path.relative(root,path.resolve(key));
  if (relativeKey === '' || (!relativeKey.startsWith(`..${path.sep}`) && !path.isAbsolute(relativeKey))) {
    throw Error('Mantenha a chave privada fora do diretório do projeto.');
  }
  const installerArg = process.argv.find(v => v.startsWith('--installer='));
  if (!installerArg) throw Error('Informe --installer=caminho');
  const installer = path.resolve(installerArg.slice(12));
  const match = fs.readFileSync(path.join(root,'pubspec.yaml'),'utf8').match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/m);
  if (!match) throw Error('Versão inválida');
  const [,version,buildText] = match;
  const build = Number(buildText);
  if (!Number.isInteger(build) || build < 1 || build > 65535 || version.split('.').some(v => Number(v)>65535)) throw Error('Versão excede os campos Windows (1..65535 para build).');
  const stamp = execFileSync('powershell.exe',['-NoProfile','-Command','(Get-Item -LiteralPath $env:FACA_FESTA_INSTALLER).VersionInfo.FileVersion'],{encoding:'utf8',env:{...process.env,FACA_FESTA_INSTALLER:installer}}).trim();
  if (stamp !== `${version}.${build}`) throw Error('Instalador não corresponde ao pubspec');
  const publicKey = run(['public-key','--private-key-file',key]).match(/[A-Za-z0-9+/]{43}=/)?.[0];
  if (!publicKey || !fs.readFileSync(path.join(root,'windows/runner/updater_public_key.h'),'utf8').includes(`"${publicKey}"`)) throw Error('Chave privada não corresponde à chave incorporada. Restaure o backup; não gere outra chave.');
  const signature = run(['sign','--private-key-file',key,installer]).match(/[A-Za-z0-9+/]{86}==/)?.[0];
  if (!signature) throw Error('Assinatura inválida');
  run(['verify','--public-key',publicKey,'--signature',signature,installer]);
  const bytes = fs.readFileSync(installer);
  const manifest = {identity,platform:'windows-x64',version,build,sha256:hash(bytes),signature,size:bytes.length,published:process.argv.includes('--publish'),
    url:`${origin}/desktop/packages/FacaFesta_${version}+${build}.exe`};
  const local = path.join(root,'release/desktop-feed/desktop/updates/latest.json');
  if (fs.existsSync(local)) {
    const previous = JSON.parse(fs.readFileSync(local,'utf8'));
    if (previous.published) assertAdvance(previous,manifest);
  }
  if (process.argv.includes('--publish')) {
    const current = await fetch(`${origin}/desktop/updates/latest.json`,{signal:AbortSignal.timeout(15000)});
    if (current.status === 200) {
      if ((current.headers.get('content-type') || '').includes('application/json')) {
        assertAdvance(await current.json(),manifest);
      } else if (process.env.FACA_FESTA_FIRST_PUBLICATION !== '1') {
        throw Error('Endpoint ainda não é um catálogo. Na primeira publicação autorizada, defina FACA_FESTA_FIRST_PUBLICATION=1.');
      }
    }
    else if (current.status !== 404) throw Error('Falha ao verificar o catálogo publicado.');
    const {Storage} = require('../functions/node_modules/@google-cloud/storage');
    const bucketName = process.env.FACA_FESTA_UPDATE_BUCKET || `${project}.firebasestorage.app`;
    if (!bucketName.startsWith(`${project}.`)) throw Error('Bucket deve pertencer ao Faça a Festa.');
    const bucket = new Storage({projectId:project}).bucket(bucketName);
    const object = bucket.file(`desktop-faca-festa/releases/build-${build}/FacaFesta_Setup.exe`);
    const [exists] = await object.exists();
    let token;
    if (exists) {
      const [metadata] = await object.getMetadata();
      if (metadata.metadata?.sha256 !== manifest.sha256 || metadata.metadata?.version !== version) throw Error('Este build já foi publicado com outros bytes/versão.');
      token = metadata.metadata.firebaseStorageDownloadTokens;
    } else {
      token = crypto.randomUUID();
      await bucket.upload(installer,{destination:object.name,preconditionOpts:{ifGenerationMatch:0},metadata:{
        contentType:'application/octet-stream',contentDisposition:'attachment; filename="FacaFesta_Setup.exe"',cacheControl:'public,max-age=31536000,immutable',
        metadata:{sha256:manifest.sha256,version,build:buildText,firebaseStorageDownloadTokens:token,identity}}});
    }
    if (!token) throw Error('Pacote sem token');
    manifest.url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(object.name)}?alt=media&token=${token}`;
  }
  const directory = writeFeed(manifest);
  if (!process.argv.includes('--publish')) {
    const packages = path.join(directory, 'packages');
    fs.mkdirSync(packages,{recursive:true});
    fs.copyFileSync(installer,path.join(packages,`FacaFesta_${version}+${build}.exe`));
  }
  console.log(JSON.stringify({directory,...manifest}));
}
module.exports={assertAdvance,hash,writeFeed};
if(require.main === module) main().catch(error=>{console.error(error.message);process.exitCode=1;});
