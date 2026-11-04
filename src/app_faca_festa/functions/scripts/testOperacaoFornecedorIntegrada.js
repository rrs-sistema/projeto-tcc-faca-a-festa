"use strict";
const {exigirEmuladorDemo}=require('./exigirEmuladorDemo');
exigirEmuladorDemo('demo-operacao-fornecedor');
const {spawnSync}=require('node:child_process'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../..');
const out=path.join(root,'docs/evidencias_validacao/operacao-fornecedor/10-logs','run-'+new Date().toISOString().replace(/[:.]/g,'-'));
console.log('EVIDENCIAS',path.relative(root,out));fs.mkdirSync(out,{recursive:true});
const resultados=[];
for(const [cenario,projeto,script] of require('./casosOperacaoFornecedor.json')) {
 const env={...process.env,GCLOUD_PROJECT:projeto,GOOGLE_CLOUD_PROJECT:projeto,FIREBASE_PROJECT_ID:projeto,FIREBASE_CONFIG:JSON.stringify({projectId:projeto})};
 exigirEmuladorDemo(projeto,env);
 const inicio=new Date().toISOString();
 console.log('INÍCIO',cenario,projeto);
 const r=spawnSync(process.execPath,[script],{cwd:root,env,encoding:'utf8',timeout:600000,maxBuffer:30*1024*1024});
 fs.writeFileSync(path.join(out,cenario+'.txt'),(r.stdout||'')+(r.stderr||'')+(r.error?'\n'+r.error.stack:''));
 const resultado={cenario,projeto,script,inicio,fim:new Date().toISOString(),exitCode:r.status,erro:r.error?.message||null};
 resultados.push(resultado);fs.writeFileSync(path.join(out,'resultados.json'),JSON.stringify(resultados,null,2)+'\n');
 console.log(r.status===0?'PASS':'FAIL',cenario,'exit',r.status);
}
if(resultados.some(r=>r.exitCode!==0))process.exitCode=1;
