// Complementos autenticados. Execute depois da jornada principal, em série:
// o build nativo e as portas dos emuladores não podem ser compartilhados.
const fs = require('node:fs'), path = require('node:path');
const {spawn} = require('node:child_process');
const root = path.resolve(__dirname,'../..');
async function executar(nome, comando) {
  const log = path.join(root,'.dart_tool',`p12-${nome}.log`);
  const fd = fs.openSync(log,'w');
  console.log(`QA12 complementar: ${nome}; log ${log}`);
  const env = {...process.env,FUNCTIONS_DISCOVERY_TIMEOUT:'120'};
  delete env.GCLOUD_PROJECT;
  try {
    const codigo = await new Promise((resolve,reject)=> {
      // /s remove apenas as aspas externas; as aspas do comando entregue ao
      // Firebase devem chegar intactas, sem escape CRT de Node para cmd.exe.
      const p = spawn('cmd.exe',['/d','/s','/c',`"${comando}"`],{
        cwd:root,env,windowsVerbatimArguments:true,stdio:['ignore',fd,fd]});
      p.on('error',reject); p.on('exit',resolve);
    });
    console.log(`QA12 complementar: ${nome} terminou com código ${codigo}.`);
    return {nome,codigo,log:path.relative(root,log)};
  } finally {fs.closeSync(fd);}
}
async function main() {
  const resultados = [];
  for(const s of ['prepararHomologacao12','prepararMfa12','prepararExecucaoEmulador','prepararMigracaoEmulador']) {
    const r=await executar(s,`node functions/scripts/${s}.js`);
    if(r.codigo!==0) throw Error(`Preparação ${s} falhou.`);
  }
  const casos = [
    ['ui-final-cobertura','demo-jornada12','firebase.homologacao12-test.json','firestore,auth,functions','testHomologacao12Desktop'],
    ['publico-sdk','demo-publico-planejamento','firebase.homologacao12-test.json','firestore,auth','testPublicoPlanejamentoDesktop'],
    ['financeiro-sdk','demo-financeiro08','firebase.homologacao12-test.json','firestore,auth','testFinanceiroDesktop'],
    ['ergonomia-sdk','demo-ergonomia10','firebase.homologacao12-test.json','firestore,auth','testErgonomiaDesktop'],
    ['editor-regras-sdk','demo-regras12','firebase.homologacao12-test.json','firestore,auth','testEditorRegrasDesktop'],
    ['login-interface','demo-login12','firebase.homologacao12-test.json','firestore,auth','testLoginDesktop'],
    ['login-google','demo-google12','firebase.homologacao12-test.json','firestore,auth','testLoginGoogleDesktop'],
    ['mfa-totp-ui','demo-mfa12','firebase.homologacao12-test.json','firestore,auth','testMfaTotpDesktop'],
    ['mfa-totp-backend','demo-mfa12','firebase.mfa12-test.json','firestore,auth,functions','testTotpMfaEmulator'],

    ['execucao-backend','demo-calculadora-execucao','firebase.execucao-test.json','firestore,auth,functions','testPlanoExecucaoEmulator'],
    ['execucao-falha-intermediaria','demo-calculadora-execucao','firebase.execucao-test.json','firestore,auth','testHomologacao12FalhaIntermediaria'],
    ['execucao-sdk','demo-calculadora-execucao','firebase.execucao-test.json','firestore,auth,functions','testExecucaoDesktop'],
    ['migracao-regras','demo-migracao11','firebase.migracao-test.json','firestore,auth,functions','testMigracaoSuite'],
  ];
  const filtro = process.env.QA12_COMPLEMENTOS?.split(',');
  if (filtro && filtro.some(n=>!casos.some(c=>c[0]===n))) throw Error('Complemento desconhecido.');
  for (const [nome,projeto,config,servicos,script] of casos) {
    if (filtro && !filtro.includes(nome)) continue;
    if (!projeto.startsWith('demo-')) throw Error('Projeto real recusado.');
    resultados.push(await executar(nome,
      `firebase emulators:exec --project ${projeto} --config ${config} --only ${servicos} "node functions/scripts/${script}.js"`));
  }
  fs.writeFileSync(path.join(root,'.dart_tool/p12-complementos.json'),
    JSON.stringify({executado_em:new Date().toISOString(),parcial:!!filtro,resultados},null,2));
  if (resultados.some(r=>r.codigo!==0)) throw Error('Há complemento reprovado; consulte os logs individuais.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
