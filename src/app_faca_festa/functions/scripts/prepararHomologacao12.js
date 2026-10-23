const fs = require('node:fs'), path = require('node:path');
const root = path.resolve(__dirname,'../..'), destino = path.join(root,'.dart_tool/homologacao12-functions');
fs.mkdirSync(destino,{recursive:true});
const modulos = path.join(root,'functions/node_modules'), link = path.join(destino,'node_modules');
if (!fs.existsSync(link)) fs.symlinkSync(modulos,link,'junction');
fs.writeFileSync(path.join(destino,'package.json'),JSON.stringify({name:'homologacao12-demo',private:true,main:'index.js',engines:{node:'22'},dependencies:{'firebase-functions':'^6.0.1','firebase-admin':'^12.7.0'}}));
const codigo = `const fs=require('node:fs'),ts=require(${JSON.stringify(path.join(modulos,'typescript'))});
require.extensions['.ts']=(m,file)=>m._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,file);
const {onRequest,onCall,HttpsError}=require('firebase-functions/v2/https');
// Somente fronteiras externas determinísticas; domínio e persistência são reais.
exports.buscarCepGoogle=onRequest({region:'southamerica-east1'},(req,res)=>res.json({sucesso:true,cep:'87000000',logradouro:'Rua sintética',numero:'',bairro:'Bairro sintético',cidade:'Cidade sintética',uf:'PR',possuiCoordenadas:false,origemCalculo:'fixture_qa12'}));
exports.analisarCalculadoraFestaIA=onCall({region:'southamerica-east1'},()=>{throw new HttpsError('unavailable','Provedor externo não habilitado neste teste demo.');});
`;
const funcoes = ['confirmarAgendaCalculadora','editarCatalogoCalculadora','migrarPlanejamentoCalculadora'];
let saida = codigo;
for (const f of funcoes) saida += `exports.${f}=require(${JSON.stringify(path.join(root,`functions/src/functions/calculadora/${f}.ts`))}).${f};\n`;
for (const [arquivo,nomes] of [['planejarServicoCalculadora',['sugerirCandidatosCalculadora','confirmarPlanejadorCalculadora']],['aplicarPlanoCalculadora',['aplicarPlanoCalculadora','revisarRefeicaoCalculadora']],['interpretarEntradaCalculadora',['aplicarEntradaCalculadora']]]) {
  for (const f of nomes) saida += `exports.${f}=require(${JSON.stringify(path.join(root,`functions/src/functions/calculadora/${arquivo}.ts`))}).${f};\n`;
}
// Interpretação determinística será usada na matriz de equivalência; não prova OpenAI.
saida += `const {admin}=require(${JSON.stringify(path.join(root,'functions/src/shared/firebaseAdmin.ts'))});
const {prepararEntradaAssistente}=require(${JSON.stringify(path.join(root,'functions/src/services/calculadora/entradaAssistenteService.ts'))});
exports.interpretarEntradaCalculadora=onCall({region:'southamerica-east1'},req=>prepararEntradaAssistente(admin.firestore(),req.auth?.uid,req.data,async()=>({resumo:'Fixture determinística QA12',perguntas:[],acoes:[{id:'duracao12',tipo:'duracao',quantidade:6,evidencia:'6 horas'},{id:'verba12',tipo:'verba',valor:300,evidencia:'verba alimentar de 300'}]})));
`;
fs.writeFileSync(path.join(destino,'index.js'),saida);
console.log('Composição de Functions QA12 preparada em .dart_tool, sem deploy.');

