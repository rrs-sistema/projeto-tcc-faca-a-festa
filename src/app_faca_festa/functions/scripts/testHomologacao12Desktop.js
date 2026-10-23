const fs = require('node:fs'), path = require('node:path');
const {spawn} = require('node:child_process');
const assert = require('node:assert/strict');
for (const k of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Somente emuladores locais.');
}
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== 'demo-jornada12') throw Error('Projeto inesperado.');
process.env.GCLOUD_PROJECT = 'demo-jornada12';
const admin = require('firebase-admin'); admin.initializeApp({projectId:'demo-jornada12'});
const root = path.resolve(__dirname,'../..');
async function main() {
  let env;
  try {
    const arquivo = path.join(root,'.dart_tool','homologacao12-config.json');
    const anterior = process.env.QA12_RETOMAR === '1' ? JSON.parse(fs.readFileSync(arquivo,'utf8')) : null;
    if (anterior && (anterior.projeto !== 'demo-jornada12' ||
      !path.resolve(anterior.pasta).startsWith(path.join(root,'.dart_tool') + path.sep))) throw Error('Checkpoint fora da QA local.');
    const run = Date.now().toString(36), uid = anterior?.uid || `qa12owner_${run}`;
    const pasta = anterior?.pasta || path.join(root,'.dart_tool',`homologacao12-${run}`);
    fs.mkdirSync(pasta,{recursive:true});
    const db = admin.firestore();
    const email = anterior?.email || `${uid}@example.test`;
    if (!anterior) {
    await admin.auth().createUser({uid,email,password:'TesteLocal12!'});
    await db.doc(`usuarios/${uid}`).set({id_usuario:uid,nome:'Organizador sintético',tipo:'O',ativo:true,email,versao_politica_privacidade:'2026-10-07'});
    for (const [id,nome] of [['corporativo12','Corporativo'],['infantil12','Festa Infantil'],['casamento12','Casamento'],['retiro12','Retiro'],['churrasco12','Churrasco']]) {
      await db.doc(`tipo_evento/${id}`).set({id_tipo_evento:id,nome,ativo:true,descricao:'Fixture QA12',icone:'celebration'});
    }
    await db.doc('estado/pr12').set({nome:'Paraná',uf:'PR'});
    await db.doc('estado/pr12/cidades/9999999').set({nome:'Cidade sintética',uf:'PR',id_cidade:9999999});
    // Apenas referências de apoio: o evento-alvo e seu cardápio nascem na UI.
    const referencia = {schema:1,motor_minimo:1,versao:1,
      aliases:['Alimento sintético'],alimento_receita:'Alimento sintético',
      servicos:['lanche'],formatos:['buffet'],periodos:['qualquer'],publicos:['todos'],
      obtencoes:['pronto','servir'],papel:'outro',unidade:'quilo',
      estado_consumo:'pronto',estado_compra:'pronto',
      contexto:'Exclusivo de QA12; não é recomendação alimentar.',limitacoes:'Dados sintéticos, sem preço.',
      fonte:'https://example.test/qa12',verificado_em:null,revisao_editorial:'Fixture QA12',
      minimo:.1,maximo:.1,padrao:.1,aprovado_por:'fixture-qa12',aprovado_em:'2026-10-21T10:00:00Z'};
    for (const [id,tipo,nome] of [['modelo_qa12','modelo','Lanche sintético QA12'],['porcao_qa12','porcao','Porção sintética QA12']]) {
      await db.doc(`calculadora_itens_base/${id}`).set({ativo:true,
        referencia_contextual:{...referencia,id,tipo,nome,
          ...(tipo === 'modelo' ? {itens:[{nome:'Alimento sintético',tipo:'comida'}]} : {})}});
    }
    const fixture = `outra12_${run}`;
    await db.doc(`evento/${fixture}`).set({id_evento:fixture,id_usuario:uid,id_tipo_evento:'corporativo12',nome_evento:'Outra festa fixture',data:admin.firestore.Timestamp.now(),data_cadastro:admin.firestore.Timestamp.now(),ativo:true,total_convidados:999,total_adultos:999});
    } else {
      assert.equal((await admin.auth().getUser(uid)).email,email,'Importe o checkpoint dos emuladores antes de retomar.');
      assert.ok(fs.existsSync(path.join(pasta,'evento-checkpoint.json')));
    }
    // Uma publicação válida tem também sua versão editorial imutável.
    // O executor compara esse documento com o snapshot aprovado na interface.
    for (const id of ['modelo_qa12','porcao_qa12']) {
      const atual = (await db.doc(`calculadora_itens_base/${id}`).get()).data().referencia_contextual;
      assert.equal(atual.fonte,'https://example.test/qa12');
      const versao = db.doc(`calculadora_itens_base/${id}/versoes_contextuais/1`);
      if (!(await versao.get()).exists) await versao.create(atual);
    }
    const regras = fs.readFileSync(path.join(root,'firestore.rules'),'utf8');
    const {initializeTestEnvironment} = require(path.join(root,'node_modules/@firebase/rules-unit-testing'));
    env = await initializeTestEnvironment({projectId:'demo-jornada12',firestore:{rules:regras}});
    const fases = (process.env.QA12_FASES || 'rascunho,evento,vinculo,planejamento,retomada').split(',');
    for (const fase of fases) {
      let regrasFase = regras;
      if (fase === 'evento') {
        const inicio = regras.indexOf('match /calculadora_festa/{id}');
        const antes = regras.slice(0,inicio), trecho = regras.slice(inicio);
        assert.ok(inicio > 0 && trecho.includes('allow create: if isAdmin() || ('));
        regrasFase = antes + trecho.replace('allow create: if isAdmin() || (','allow create: if isAdmin() || (false &&');
      }
      await env.cleanup();
      env = await initializeTestEnvironment({projectId:'demo-jornada12',firestore:{rules:regrasFase}});
      fs.writeFileSync(arquivo,JSON.stringify({projeto:'demo-jornada12',pasta,fase,email,uid,estendida:true}));
      console.log(`QA12: iniciando processo novo para ${fase}.`);
      await new Promise((resolve,reject) => {
        const command = `flutter test integration_test/homologacao_cadastro_retomada_test.dart -d windows --dart-define=CALCULADORA_QA=true --dart-define=QA12_CONFIG=${arquivo}`;
        const child = spawn('cmd.exe',['/d','/s','/c',command],{cwd:root,stdio:'inherit'});
        child.on('error',reject);child.on('exit',n=>n===0 ? resolve() : reject(Error(`Fase ${fase}: ${n}`)));
      });
      const checkpoint = JSON.parse(fs.readFileSync(path.join(pasta,`${fase}-checkpoint.json`),'utf8'));
      let encerrado = false;
      for (let i=0;i<30;i++) {
        try { process.kill(checkpoint.pid,0); }
        catch (e) { if (e.code !== 'ESRCH') throw e; encerrado = true; break; }
        await new Promise(r=>setTimeout(r,100));
      }
      assert.ok(encerrado,`O processo ${checkpoint.pid} precisa estar encerrado antes da fase seguinte.`);
      console.log(`QA12: processo ${checkpoint.pid} encerrado no SO; checkpoint ${fase} preservado.`);
    }
    if (fases.includes('retomada')) {
      const checkpoints = ['rascunho','evento','vinculo','planejamento','retomada'];
      const registros = checkpoints.map(f=>JSON.parse(fs.readFileSync(path.join(pasta,`${f}-checkpoint.json`),'utf8')));
      assert.equal(new Set(registros.map(r=>r.pid)).size,checkpoints.length,'Processos do app precisam ser distintos.');
      const target = registros[1].evento;
      const docs = await db.collection('evento').where('nome_evento','==','Homologação UI 12').get();
      assert.equal(docs.size,1);assert.equal(docs.docs[0].id,target);
      assert.equal((await db.collection('calculadora_festa').where('id_evento','==',target).get()).size,2);
      assert.equal((await db.collection('cardapios').where('id_evento','==',target).get()).size,1);
      assert.equal((await db.collection(`calculadora_operacao/${target}/aplicacoes`).get()).size,1);
      console.log('QA12: cadastro por UI, interrupções em processos distintos e vínculo único confirmados no Firestore.');
      fs.writeFileSync(path.join(pasta,'resultado.json'),JSON.stringify({
        projeto:'demo-jornada12',executado_em:new Date().toISOString(),
        fases:checkpoints,processos:registros.map(r=>r.pid),evento:target,
        eventos:docs.size,historicos:2,cardapios:1,recibos:1,
        externo:{cep:'fixture determinística local',gps:'desligado',ia:'não homologada'},
        resultado:'aprovado no roteiro UI coberto'
      },null,2));
    }
    console.log(`QA12: evidências locais em ${pasta}.`);
  } finally { if (env) await env.cleanup(); await admin.app().delete(); }
}
main().catch(e=>{console.error(e);process.exitCode=1;});
