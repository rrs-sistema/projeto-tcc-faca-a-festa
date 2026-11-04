const {spawnSync}=require('child_process');
for(const [id,file] of [['demo-avaliacoes-verificadas','testAvaliacoesVerificadasEmulator.js'],['demo-gestao-reputacao','testGestaoReputacaoEmulator.js']]) {
const env={...process.env,GCLOUD_PROJECT:id,GOOGLE_CLOUD_PROJECT:id,FIREBASE_PROJECT_ID:id,FIREBASE_CONFIG:JSON.stringify({projectId:id})};
const r=spawnSync(process.execPath,['functions/scripts/'+file],{env,stdio:'inherit',timeout:180000});
if(r.status!==0)process.exit(1);
}
