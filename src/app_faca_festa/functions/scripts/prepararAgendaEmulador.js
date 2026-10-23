// Prepara somente artefatos ignorados de teste; não compila nem publica o projeto.
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../..'),destino=path.join(root,'.dart_tool/agenda-functions');
fs.mkdirSync(destino,{recursive:true});
const modulo=path.join(root,'functions/node_modules');
const link=path.join(destino,'node_modules');
if(!fs.existsSync(link)) fs.symlinkSync(modulo,link,'junction');
fs.writeFileSync(path.join(destino,'package.json'),JSON.stringify({name:'agenda-demo-functions',private:true,main:'index.js',engines:{node:'22'},dependencies:{'firebase-functions':'^6.0.1','firebase-admin':'^12.7.0'}},null,2));
const arquivo=path.join(root,'functions/src/functions/calculadora/confirmarAgendaCalculadora.ts');
const typescript=path.join(modulo,'typescript');
fs.writeFileSync(path.join(destino,'index.js'),`const fs=require('node:fs'),ts=require(${JSON.stringify(typescript)});
require.extensions['.ts']=(m,file)=>m._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,file);
exports.confirmarAgendaCalculadora=require(${JSON.stringify(arquivo)}).confirmarAgendaCalculadora;
`);
console.log('Fonte de Functions demo preparada em .dart_tool/agenda-functions.');
