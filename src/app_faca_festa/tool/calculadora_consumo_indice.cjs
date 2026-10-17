// Cria somente o índice da consulta privada de consumo; não remove outros índices.
const {GoogleAuth} = require('../functions/node_modules/google-auth-library');
const fs = require('fs');
const path = require('path');
const project = 'faca-a-festa';
const fields = [{fieldPath:'id_usuario',order:'ASCENDING'},
  {fieldPath:'consumo_registrado_em',order:'DESCENDING'}];
const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/collectionGroups/calculadora_festa/indexes`;
async function main() {
  const auth = new GoogleAuth({scopes:['https://www.googleapis.com/auth/datastore']});
  const client = await auth.getClient();
  const {data} = await client.request({url,timeout:30000});
  if (data.nextPageToken) throw Error('Paginação de índices excedeu o limite da consulta.');
  const current = (data.indexes ?? []).find(i => i.queryScope === 'COLLECTION' &&
    JSON.stringify(i.fields.filter(f=>f.fieldPath !== '__name__')) === JSON.stringify(fields));
  let result = {project, mode:'dry-run', state:current?.state ?? 'MISSING'};
  if (current) result.name = current.name;
  if (!current && process.argv.includes('--apply')) {
    const response = await client.request({url,method:'POST',data:{queryScope:'COLLECTION',fields},timeout:30000});
    result = {project,mode:'apply',operation:response.data.name,state:'CREATING'};
  }
  const directory = path.resolve(__dirname,'../.dart_tool');
  fs.mkdirSync(directory,{recursive:true});
  fs.writeFileSync(path.join(directory,'calculadora-consumo-index.json'),JSON.stringify(result,null,2));
  console.log(JSON.stringify(result,null,2));
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
