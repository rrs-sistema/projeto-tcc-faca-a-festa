// Real WinSparkle, local HTTP server, synthetic signed package. No app install.
const fs=require('fs'), path=require('path'), os=require('os'), crypto=require('crypto');
const http=require('http'), assert=require('assert/strict');
const {execFileSync,spawn}=require('child_process');
const root=path.resolve(__dirname,'..');
const executable=path.join(root,'.codex_tmp/native-tests/smoke.exe');
const tool=path.join(root,'.dart_tool/winsparkle-0.9.4/WinSparkle-0.9.4/bin/winsparkle-tool.exe');
const key=process.env.FACA_FESTA_UPDATE_PRIVATE_KEY || path.join(process.env.LOCALAPPDATA,'FacaFesta/publishing/desktop-ed25519.key');
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'faca-festa-download-test-'));
const file=path.join(temporary,'fixture.exe');
const bytes=Buffer.from('Synthetic package for signature verification only.');
fs.writeFileSync(file,bytes);
const signature=execFileSync(tool,['sign','--private-key-file',key,file],{encoding:'utf8'}).match(/[A-Za-z0-9+/]{86}==/)[0];
const hash=crypto.createHash('sha256').update(bytes).digest('hex');
let base;
const server=http.createServer((req,res)=>{
  if(req.url.endsWith('.exe')) { res.writeHead(200,{'Content-Type':'application/octet-stream'}); res.end(req.url==='/bad.exe'?Buffer.from('tampered package'):bytes); return; }
  const url=`${base}/${req.url==='/bad.xml'?'bad':'good'}.exe`;
  const length=req.url==='/bad.xml'?Buffer.byteLength('tampered package'):bytes.length;
  res.writeHead(200,{'Content-Type':'application/xml'});
  res.end(`<?xml version="1.0"?><rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><title>Faça a Festa test</title><item><title>Fixture</title><enclosure url="${url}" sparkle:version="8" sparkle:shortVersionString="1.0.6" sparkle:os="windows" sparkle:edSignature="${signature}" length="${length}" type="application/octet-stream" /></item></channel></rss>`);
});
function run(feed,build='7') {
  return new Promise((resolve,reject)=>{
    const child=spawn(executable,[feed,build,hash],{windowsHide:true});
    let output=''; const timer=setTimeout(()=>{child.kill();reject(Error('Smoke exceeded 100 seconds'));},100000);
    child.stdout.on('data',data=>output+=data); child.on('error',reject);
    child.on('close',code=>{clearTimeout(timer);resolve({code,output:output.trim()});});
  });
}
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  base=`http://127.0.0.1:${server.address().port}`;
  const good=await run(`${base}/good.xml`); assert.equal(good.code,0,good.output); assert.equal(JSON.parse(good.output).installerCallback,true);
  const bad=await run(`${base}/bad.xml`); assert.equal(bad.code,1,bad.output); assert.equal(JSON.parse(bad.output).installerCallback,false);
  const old=await run(`${base}/good.xml`,'8'); assert.equal(old.code,3,old.output); assert.equal(JSON.parse(old.output).installerCallback,false);
  console.log(JSON.stringify({signedDownload:good,tamperedDownload:bad,oldBuild:old}));
})().catch(error=>{console.error(error);process.exitCode=1;}).finally(()=>{server.close();fs.unlinkSync(file);fs.rmdirSync(temporary);});
