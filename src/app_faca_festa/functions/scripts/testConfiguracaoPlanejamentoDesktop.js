// Exclusivamente emuladores locais; não altera projetos reais.
const {spawn} = require('node:child_process');
const path = require('node:path');
const local = /^(127\.0\.0\.1|localhost|\[::1\]):\d+$/;
for (const key of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!local.test(process.env[key] || '')) throw Error(`${key} deve apontar ao emulador local.`);
}
process.env.GCLOUD_PROJECT = 'demo-configuracao-planejamento';
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'demo-configuracao-planejamento'});
async function main() {
  const eventoId = `publico-festa-${Date.now()}`;
  try {
    for (const uid of ['publico-owner', 'publico-other']) {
      try { await admin.auth().getUser(uid); }
      catch (e) {
        if (e.code !== 'auth/user-not-found') throw e;
        await admin.auth().createUser({uid, email: `${uid}@example.test`, password: 'TesteLocal123!'});
      }
      await admin.firestore().doc(`usuarios/${uid}`).set({tipo: 'O', ativo: true});
    }
    // Executa o serviço de produção da entrada assistida com extrator sintético,
    // sem rede externa e sem substituir a transação do Firestore emulado.
    require.extensions['.ts'] = (m, file) => {
      const source = require('node:fs').readFileSync(file, 'utf8');
      const ts = require('typescript');
      m._compile(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,file);
    };
    const {prepararEntradaAssistente,aplicarEntradaAssistente} = require('../src/services/calculadora/entradaAssistenteService.ts');
    const eventoIA = `${eventoId}-ia`, db = admin.firestore();
    await db.doc(`evento/${eventoIA}`).set({id_usuario:'publico-owner',custo_estimado:2500});
    const acoes = [
      {id:'duracao',tipo:'duracao',quantidade:6}, {id:'perfil',tipo:'perfil',nome:'premium'},
      {id:'margem',tipo:'margem',valor:0.1}, {id:'verba',tipo:'verba',valor:1450}
    ].map(a=>({...a,evidencia:'Escolhas sintéticas fornecidas pelo organizador'}));
    const proposta = await prepararEntradaAssistente(db,'publico-owner',{evento:eventoIA,texto:'duração 6 horas, perfil premium, margem 10%, verba 1450',regras:[]},async()=>({resumo:'Teste',acoes,perguntas:[],documento:{}}));
    if (proposta.acoes.length !== 4) throw Error(JSON.stringify(proposta.perguntas));
    const comandoIA={evento:eventoIA,id:proposta.id,assinatura:proposta.assinatura,selecionadas:proposta.acoes.map(a=>a.id),conferiu_duplicidade:true};
    await aplicarEntradaAssistente(db,'publico-owner',comandoIA);
    if ((await aplicarEntradaAssistente(db,'publico-owner',comandoIA)).aplicado !== false) throw Error('Entrada repetida não foi idempotente.');
    const cfgIA=(await db.doc(`calculadora_operacao/${eventoIA}`).get()).data().configuracao_planejamento;
    for (const [k,v] of Object.entries({duracao:6,perfil:'premium',margem:0.1,verba_alimentacao:1450})) if(cfgIA[k]!==v) throw Error(`Entrada assistida perdeu ${k}`);
    console.log('Configuração via entrada assistida em Firestore real emulado: OK');
    await new Promise((resolve, reject) => {
      const command = `flutter test integration_test/configuracao_planejamento_emulator_test.dart -d windows --dart-define=CALCULADORA_QA=true --dart-define=PUBLICO_QA_EVENTO=${eventoId}`;
      const child = spawn('cmd.exe', ['/d', '/s', '/c', command], {cwd: path.resolve(__dirname, '../..'), stdio: 'inherit'});
      child.on('error', reject); child.on('exit', code => code === 0 ? resolve() : reject(Error(`SDK Windows: ${code}`)));
    });
    const evento = (await admin.firestore().doc(`evento/${eventoId}`).get()).data();
    if (evento.configuracao_planejamento || evento.lista_completude || evento.base_confirmada) throw Error('Conteúdo privado no evento compartilhado.');
    console.log('Configuração corrente SDK real: OK');
  } finally { await admin.app().delete(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
