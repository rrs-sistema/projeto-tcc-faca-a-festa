// Falha controlada dentro de uma transação real; não substitui o banco por mock.
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
for (const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Somente emuladores locais.');
}
const projectId='demo-calculadora-execucao';
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT!==projectId) throw Error('Projeto inesperado.');
const admin=require('firebase-admin');admin.initializeApp({projectId});
const {initializeApp,deleteApp}=require('firebase/app');
const {getAuth,connectAuthEmulator,createUserWithEmailAndPassword}=require('firebase/auth');
const {executarPlano,normalizarFonte}=require('../lib/services/calculadora/executarPlanoService');
async function main() {
  const app=initializeApp({projectId,apiKey:'demo-key',appId:'demo-falha12'},'falha12');
  try {
    const auth=getAuth(app),db=admin.firestore();
    connectAuthEmulator(auth,`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`,{disableWarnings:true});
    const uid=(await createUserWithEmailAndPassword(auth,'falha12@example.test','TesteSintetico12!')).user.uid;
    const payload=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../../.dart_tool/calculadora-plano-fixture.json'),'utf8'));
    payload.plano.fontes['evento/evento'].id_usuario=uid;
    for (const [p,d] of Object.entries(payload.plano.fontes)) if(d!==null) await db.doc(p).set(d);
    await db.doc(`usuarios/${uid}`).set({tipo:'O',ativo:true});
    async function capturar() {
      const dados={};
      async function ler(col) {
        for(const d of (await col.get()).docs) {
          dados[d.ref.path]=normalizarFonte(d.data());
          for(const sub of await d.ref.listCollections()) await ler(sub);
        }
      }
      for(const col of await db.listCollections()) await ler(col);
      return dados;
    }
    const antes=await capturar();
    let enfileiradas=0,checks=0;
    const interrupcao=new Error('QA12: interrupção depois de enfileirar gravações');
    const comFalha=new Proxy(db,{get(alvo,chave) {
      if(chave==='runTransaction') return (trabalho,opcoes)=>alvo.runTransaction(async tx=> {
        let tentativa=0;
        const observado=new Proxy(tx,{get(transacao,metodo) {
          const valor=Reflect.get(transacao,metodo,transacao);
          if(typeof valor!=='function') return valor;
          return (...args)=> {
            const retorno=valor.apply(transacao,args); // SDK real enfileira a escrita.
            if(['set','create','update','delete'].includes(metodo)) {
              enfileiradas++;
              if(++tentativa===2) throw interrupcao;
            }
            return retorno;
          };
        }});
        return trabalho(observado);
      },opcoes);
      const valor=Reflect.get(alvo,chave,alvo);
      return typeof valor==='function'?valor.bind(alvo):valor;
    }});
    await assert.rejects(()=>executarPlano(comFalha,uid,payload),e=>e===interrupcao);checks++;
    assert.ok(enfileiradas>=2);checks++;
    // Consulta todos os documentos no servidor, incluindo itens, tarefas e recibos.
    assert.deepEqual(await capturar(),antes);checks++;
    assert.equal(await executarPlano(db,uid,payload),true);checks++;
    assert.equal(await executarPlano(db,uid,payload),false);checks++;
    assert.equal((await db.collection('calculadora_operacao/evento/aplicacoes').get()).size,1);checks++;
    console.log(`QA12 falha intermediária: ${checks} verificações OK; abortou sem efeito parcial, nova tentativa e repetição com recibo único.`);
  } finally {await deleteApp(app);await admin.app().delete();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
