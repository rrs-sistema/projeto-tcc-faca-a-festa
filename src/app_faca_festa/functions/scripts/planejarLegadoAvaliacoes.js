/* Entrada JSON [{path,data}], saída JSON revisável. Sem SDK, credenciais ou escrita remota. */
const fs=require('fs');
function planejar(registros) {
 if(!Array.isArray(registros))throw Error('Informe exportação [{path,data}].');
 return {modo:'dry-run',promocoesAutomaticas:0,operacoes:registros.map(r=>{
  if(typeof r.path!=='string'||!r.data||typeof r.data!=='object')throw Error('Registro inválido.');
  return {origem:r.path,acao:'preservar_historico',verificada:false,
   motivo:'Exige conferência humana do vínculo, objeto, autoria e prova de aceite; IDs aparentes não comprovam entrega.',
   destinoProposto:r.path,dadosOriginais:r.data};
 })};
}
module.exports={planejar};
if(require.main===module){
 if(process.argv.length!==3)throw Error('Uso: node functions/scripts/planejarLegadoAvaliacoes.js export-local.json > plano-local.json');
 process.stdout.write(JSON.stringify(planejar(JSON.parse(fs.readFileSync(process.argv[2],'utf8'))),null,2)+'\n');
}
