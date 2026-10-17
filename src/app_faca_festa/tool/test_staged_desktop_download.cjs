// Downloads the actual locally staged installer through WinSparkle, never runs it.
const fs=require('fs'),path=require('path'),http=require('http'),assert=require('assert/strict');
const {spawn}=require('child_process');
const root=path.resolve(__dirname,'..');
const directory=path.join(root,'release/desktop-feed');
const manifest=JSON.parse(fs.readFileSync(path.join(directory,'desktop/updates/latest.json'),'utf8'));
const installer=path.join(directory,`desktop/packages/FacaFesta_${manifest.version}+${manifest.build}.exe`);
let base;
const server=http.createServer((req,res)=>{
  if(req.url==='/package.exe') {
    res.writeHead(200,{'Content-Type':'application/octet-stream','Content-Length':fs.statSync(installer).size});
    fs.createReadStream(installer).pipe(res); return;
  }
  if(req.url==='/feed.xml') {
    const xml=fs.readFileSync(path.join(directory,'desktop/updates/appcast.xml'),'utf8').replace(/url="[^"]+"/,`url="${base}/package.exe"`);
    res.writeHead(200,{'Content-Type':'application/xml'}); res.end(xml); return;
  }
  if(req.url==='/desktop/' || req.url==='/desktop/updates/latest.json') {
    res.end(fs.readFileSync(path.join(directory,req.url.endsWith('/')?'desktop/index.html':'desktop/updates/latest.json'))); return;
  }
  res.writeHead(404);res.end();
});
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  base=`http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(`${base}/desktop/`)).status,200);
  assert.equal((await (await fetch(`${base}/desktop/updates/latest.json`)).json()).build,manifest.build);
  const result=await new Promise((resolve,reject)=>{
    const child=spawn(path.join(root,'.codex_tmp/native-tests/smoke.exe'),[`${base}/feed.xml`,String(manifest.build-1),manifest.sha256],{windowsHide:true});
    let output='';const timer=setTimeout(()=>{child.kill();reject(Error('Actual download exceeded 100 seconds'));},100000);
    child.stdout.on('data',data=>output+=data);child.on('error',reject);
    child.on('close',code=>{clearTimeout(timer);resolve({code,output:output.trim()});});
  });
  assert.equal(result.code,0,result.output);assert.equal(JSON.parse(result.output).installerCallback,true);
  console.log(JSON.stringify({version:manifest.version,build:manifest.build,actualSignedInstallerDownload:result}));
})().catch(error=>{console.error(error.message);process.exitCode=1;}).finally(()=>server.close());
