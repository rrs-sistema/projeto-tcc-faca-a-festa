// Prova offline ponta a ponta no aparelho Android, somente contra emuladores.
// O aparelho fala com os emuladores por `adb reverse` -> proxy TCP local.
// Cortar a rede = fechar o proxy e derrubar as conexões abertas; com isso o
// app enxerga a mesma falha de um aparelho em modo avião.
const { spawn, execFileSync } = require('node:child_process');
const path = require('node:path');
const fs = require('node:fs');
const net = require('node:net');

for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[k] || '')) throw Error('Somente emuladores locais.');
}
const PROJETO = 'demo-offline-mobile';
process.env.GCLOUD_PROJECT = PROJETO;
const admin = require('firebase-admin');
admin.initializeApp({ projectId: PROJETO });
const express = require('express');
const { onCall } = require('firebase-functions/v2/https');
const { abrirConvitePorToken } = require('../lib/functions/convite/abrirConvitePorToken');

const RAIZ = path.resolve(__dirname, '../..');
const ADB = process.env.ADB ?? 'D:\\src\\android-sdk\\platform-tools\\adb.exe';
const FLUTTER = process.env.FLUTTER_BAT ?? 'D:\\src\\flutter\\flutter_3.27.2\\bin\\flutter.bat';
const DEVICE = process.env.OFFLINE_QA_DEVICE ?? '192.168.5.107:5555';
const MODO = process.env.OFFLINE_QA_MODO ?? 'final';
const SENHA = 'TesteOffline123!';
const EVENTO = 'evt-offline';
const TOKEN = 'TOKEN-OFFLINE-QA-0001';
// Pacote próprio do QA (build.gradle): nunca toca no app instalado do usuário.
const PACOTE = 'com.rrs.system.technology.facafesta.offlineqa';
if (!/^[A-Za-z0-9_.:-]{1,100}$/.test(DEVICE)) throw Error('Identificador ADB inválido.');
if (!/^[a-z_]{1,20}$/.test(MODO)) throw Error('Modo inválido.');

/** Proxy que pode ser desligado e religado. */
class Ponte {
  constructor(porta, destino) { this.porta = porta; this.destino = destino; this.sockets = new Set(); this.servidor = null; }
  ligar() {
    if (this.servidor) return Promise.resolve();
    this.servidor = net.createServer(cliente => {
      const alvo = net.connect(this.destino, '127.0.0.1');
      for (const s of [cliente, alvo]) { this.sockets.add(s); s.on('close', () => this.sockets.delete(s)); s.on('error', () => s.destroy()); }
      cliente.pipe(alvo); alvo.pipe(cliente);
    });
    return new Promise((ok, falha) => this.servidor.once('error', falha).listen(this.porta, '127.0.0.1', ok));
  }
  desligar() {
    const servidor = this.servidor; this.servidor = null;
    for (const s of this.sockets) s.destroy();
    this.sockets.clear();
    return servidor ? new Promise(ok => servidor.close(() => ok())) : Promise.resolve();
  }
}

const pontes = [new Ponte(18080, 8080), new Ponte(19099, 9099), new Ponte(15001, 5001)];
const rede = {
  ligada: false,
  async ligar() { await Promise.all(pontes.map(p => p.ligar())); this.ligada = true; console.log('[QA] rede do aparelho LIGADA'); },
  async cortar() { await Promise.all(pontes.map(p => p.desligar())); this.ligada = false; console.log('[QA] rede do aparelho CORTADA'); },
};

function adb(...args) { return execFileSync(ADB, ['-s', DEVICE, ...args], { stdio: 'pipe' }).toString(); }

async function semear(db) {
  for (const colecao of await db.listCollections()) await db.recursiveDelete(colecao);
  const usuarios = [['org', 'org@offline.test', 'O', 'Organizadora QA'], ['forn', 'forn@offline.test', 'F', 'Fornecedor QA']];
  for (const [uid, email, tipo, nome] of usuarios) {
    try { await admin.auth().deleteUser(uid); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
    await admin.auth().createUser({ uid, email, password: SENHA, displayName: nome });
    await db.doc(`usuarios/${uid}`).set({ id_usuario: uid, tipo, ativo: true, nome, email, aceite_politica: true });
  }
  const agora = admin.firestore.Timestamp.now();
  const daqui = d => admin.firestore.Timestamp.fromMillis(Date.now() + d * 86400000);
  await db.doc('tipo_evento/churrasco').set({ id_tipo_evento: 'churrasco', nome: 'Churrasco', ativo: true });
  await db.doc(`evento/${EVENTO}`).set({
    id_evento: EVENTO, id_tipo_evento: 'churrasco', id_usuario: 'org', nome_evento: 'Churrasco de fim de ano',
    local_evento: 'Chácara QA', data: daqui(30), data_cadastro: agora, total_convidados: 25, custo_estimado: 5000,
    total_adultos: 20, total_criancas: 5, total_bebes: 0, status: 'planejamento', ativo: true,
  });
  await db.doc('convidado/conv-seed').set({
    id_convidado: 'conv-seed', id_evento: EVENTO, nome: 'Convidado QA', contato: '', status: 'pendente',
    tipo_convidado: 'adulto', convite_token: TOKEN, data_cadastro: agora, data_atualizacao: agora,
  });
  for (let i = 0; i < 12; i++) {
    await db.doc(`convidado/conv-lista-${i}`).set({
      id_convidado: `conv-lista-${i}`, id_evento: EVENTO, nome: `Pessoa QA ${i}`, contato: '',
      status: 'confirmado', tipo_convidado: i < 9 ? 'adulto' : 'crianca', data_cadastro: agora, data_atualizacao: agora,
    });
  }
  await db.doc('tarefa/tarefa-seed').set({
    id_tarefa: 'tarefa-seed', id_evento: EVENTO, id_responsavel: 'org', titulo: 'Reservar chácara', status: 'a_fazer', data_cadastro: agora,
  });
  await db.doc('orcamento/orc-offline').set({
    id_orcamento: 'orc-offline', id_evento: EVENTO, id_usuario: 'org', nome: 'Bebidas', categoria: 'Bebidas',
    custo_previsto: 1500, custo_estimado: 1500, custo_total: 0, valor_pago: 0, data_cadastro: agora,
  });
  const presente = (id, nome, extra = {}) => db.doc(`evento/${EVENTO}/presentes/${id}`).set({
    nome, categoria: 'geral', tipo: 'fisico', status: 'disponivel', valor_arrecadado: 0, created_at: agora, ...extra,
  });
  await presente('p-seed', 'Vaquinha da churrasqueira', { tipo: 'coletivo', meta_valor: 600 });
  await presente('p-reserva', 'Jogo de facas');
  await presente('p-conflito', 'Cooler 48 litros');
  await db.doc('fornecedor/forn').set({
    id_fornecedor: 'forn', id_usuario: 'forn', razao_social: 'Buffet QA', nome_fantasia: 'Buffet QA', ativo: true,
    email: 'forn@offline.test', telefone: '44999990000', data_cadastro: agora,
  });
  await db.doc('categoria_servico/cat-buffet').set({ nome: 'Buffet' });
  await db.doc('subcategoria_servico/sub-churrasco').set({ nome: 'Churrasco', id_categoria: 'cat-buffet' });
  await db.doc('servico_produto/serv-churrasco').set({ nome: 'Churrasco completo', descricao: 'Por pessoa', tipo_medida: 'P', id_subcategoria: 'sub-churrasco', ativo: true });
  await db.doc('fornecedor_servico/forn_serv-churrasco').set({
    id_fornecedor: 'forn', id_produto_servico: 'serv-churrasco', id_subcategoria: 'sub-churrasco', preco: 89.9, ativo: true, data_cadastro: agora,
  });
  const catalogo = JSON.parse(fs.readFileSync(path.join(RAIZ, 'config/calculadora_catalogo_v1.json'), 'utf8'));
  for (const linha of catalogo) await db.doc(`calculadora_evento_itens/${linha.id}`).set(linha);
  // Referência aprovada do catálogo contextual (mesmo formato da fixture de teste).
  await db.doc('calculadora_itens_base/teste_porcoes').set({
    ativo: true,
    referencia_contextual: {
      schema: 1, motor_minimo: 1, id: 'teste_porcoes', versao: 1, tipo: 'porcao',
      nome: 'Alimento sintético', aliases: ['Alimento sintético'], alimento_receita: 'Receita sintética',
      servicos: ['lanche'], formatos: ['buffet'], periodos: ['qualquer'], publicos: ['todos'],
      obtencoes: ['servir', 'pronto', 'preparar'], papel: 'outro', unidade: 'quilo',
      estado_consumo: 'pronto', estado_compra: 'pronto',
      contexto: 'Fixture sintética de teste, sem recomendação real.', limitacoes: 'Somente cenário sintético.',
      fonte: 'https://example.test/referencia', verificado_em: null, revisao_editorial: 'Fixture sintética.',
      minimo: 0.1, maximo: 0.1, padrao: 0.1, aprovado_por: 'admin-qa', aprovado_em: '2026-10-19T12:00:00Z',
    },
  });
}

function servirFunctions() {
  const painel = onCall({ cors: true }, req => {
    if (req.auth?.uid !== 'forn') throw new (require('firebase-functions/v2/https').HttpsError)('permission-denied', 'Somente o fornecedor.');
    return { gerado_em: new Date().toISOString(), resumo: { pedidos_hoje: 3, a_receber: 1250.5 }, agenda: [{ id: 'ag-1', titulo: 'Churrasco de fim de ano' }] };
  });
  const app = express();
  app.use(express.json({ limit: '2mb' }));
  for (const [nome, fn] of Object.entries({ abrirConvitePorToken, consultarPainelFornecedorFn: painel })) {
    app.post(`/${PROJETO}/southamerica-east1/${nome}`, (req, res) => fn(req, res));
  }
  return app.listen(5001, '127.0.0.1');
}

// `flutter run` em vez de `flutter test`: o `flutter test` desinstala o app ao
// terminar, e a fase seguinte precisa reabrir o mesmo app com os dados dele.
function rodarFase(fase, eventos) {
  const defines = [`OFFLINE_QA=true`, `OFFLINE_QA_FASE=${fase}`, `OFFLINE_QA_MODO=${MODO}`];
  const comando = `${FLUTTER} run -t integration_test/offline_mobile_first_aparelho_test.dart -d ${DEVICE} ${defines.map(d => `--dart-define=${d}`).join(' ')} --debug --no-enable-impeller --no-dds`;
  return new Promise((ok, falha) => {
    const filho = spawn('cmd.exe', ['/c', comando], { cwd: RAIZ, stdio: ['pipe', 'pipe', 'pipe'] });
    let resto = '';
    let terminou = false;
    const limite = setTimeout(() => encerrar(Error(`Fase ${fase} excedeu 30 minutos.`)), 30 * 60 * 1000);
    function encerrar(erro) {
      if (terminou) return;
      terminou = true;
      clearTimeout(limite);
      try { execFileSync('taskkill', ['/PID', String(filho.pid), '/T', '/F'], { stdio: 'ignore' }); } catch { /* já saiu */ }
      try { adb('shell', 'am', 'force-stop', PACOTE); } catch { /* aparelho saiu */ }
      erro ? falha(erro) : ok();
    }
    const tratar = async linha => {
      const host = /QA_OFFLINE_HOST:(cortar|religar|reservar-conflito)/.exec(linha);
      if (host?.[1] === 'cortar') await rede.cortar();
      if (host?.[1] === 'religar') await rede.ligar();
      // Outra pessoa reserva o mesmo presente enquanto o aparelho está offline.
      if (host?.[1] === 'reservar-conflito') {
        await admin.firestore().doc(`evento/${EVENTO}/presentes/p-conflito`).update({
          reservado_por: 'Outra pessoa', id_convidado: 'conv-lista-0', data_reserva: admin.firestore.Timestamp.now(),
        });
        console.log('[QA] presente p-conflito reservado por outra pessoa no servidor');
      }
      const etapa = /QA_OFFLINE_ETAPA:(\{.*\})/.exec(linha);
      if (etapa) eventos.push({ fase, ...JSON.parse(etapa[1]) });
      if (/QA_OFFLINE_FIM:/.test(linha)) setTimeout(() => encerrar(), 1500);
      if (/QA_OFFLINE_ERRO:/.test(linha)) encerrar(Error(linha));
    };
    filho.stdout.on('data', bloco => {
      process.stdout.write(bloco);
      const linhas = (resto + bloco.toString()).split(/\r?\n/);
      resto = linhas.pop();
      for (const l of linhas) tratar(l).catch(e => console.error('[QA]', e));
    });
    filho.stderr.on('data', b => process.stderr.write(b));
    filho.on('error', e => encerrar(e));
    filho.on('exit', codigo => {
      if (resto) tratar(resto);
      setTimeout(() => encerrar(terminou ? undefined : Error(`Fase ${fase} saiu (${codigo}) antes do fim do teste.`)), 2000);
    });
  });
}

async function verificarServidor(db) {
  const v = [];
  const marcar = (etapa, ok, detalhe = '') => { v.push({ fase: 'servidor', jornada: 'admin_sdk', cenario: 'verificacao', etapa, ok, ...(detalhe ? { erro: detalhe } : {}) }); };
  const doc = async c => (await db.doc(c).get());
  marcar('Evento criado offline existe', (await doc('evento/evt-criado-offline')).exists);
  marcar('Edição offline do evento chegou', (await doc(`evento/${EVENTO}`)).data()?.nome_evento === 'Festa editada offline');
  marcar('Tarefa offline existe', (await doc('tarefa/tarefa-offline')).exists);
  marcar('Convidado offline existe', (await doc('convidado/conv-offline')).exists);
  const totalGastos = (await db.collection('orcamento/orc-offline/orcamento_gasto').get()).size;
  marcar('Gasto offline registrado uma única vez', totalGastos === 1, `encontrados: ${totalGastos}`);
  marcar('Presente offline existe', (await doc(`evento/${EVENTO}/presentes/p-offline`)).exists);
  const contribs = await db.collection(`evento/${EVENTO}/presentes/p-seed/contributions`).get();
  marcar('Contribuição PIX sem duplicar', contribs.size === 1, `encontradas: ${contribs.size}`);
  const arrecadado = (await doc(`evento/${EVENTO}/presentes/p-seed`)).data()?.valor_arrecadado;
  marcar('Valor arrecadado coerente', arrecadado === 50, `valor: ${arrecadado}`);
  const reserva = (await doc(`evento/${EVENTO}/presentes/p-reserva`)).data();
  marcar('Reserva do convidado chegou', reserva?.reservado_por === 'Convidado QA');
  const conflito = (await doc(`evento/${EVENTO}/presentes/p-conflito`)).data();
  marcar('Conflito: a primeira reserva foi preservada', conflito?.reservado_por === 'Outra pessoa' && conflito?.id_convidado === 'conv-lista-0',
    `reservado_por: ${conflito?.reservado_por}`);
  return v;
}

function salvarEvidencia(eventos, inicio) {
  const pasta = path.join(RAIZ, 'docs/evidencias_validacao/offline-mobile-first');
  fs.mkdirSync(pasta, { recursive: true });
  const modelo = (() => { try { return adb('shell', 'getprop', 'ro.product.model').trim(); } catch { return DEVICE; } })();
  const android = (() => { try { return adb('shell', 'getprop', 'ro.build.version.release').trim(); } catch { return '?'; } })();
  const resumo = {
    modo: MODO, aparelho: modelo, android, inicio, fim: new Date().toISOString(),
    total: eventos.length, aprovadas: eventos.filter(e => e.ok).length, reprovadas: eventos.filter(e => !e.ok).length, etapas: eventos,
  };
  const arquivo = path.join(pasta, `resultado_${MODO}.json`);
  fs.writeFileSync(arquivo, JSON.stringify(resumo, null, 2));
  console.log(`[QA] ${resumo.aprovadas}/${resumo.total} etapas aprovadas -> ${path.relative(RAIZ, arquivo)}`);
  for (const e of eventos.filter(x => !x.ok)) console.log(`[QA] FALHOU ${e.jornada}/${e.cenario}: ${e.etapa} -> ${e.erro ?? ''}`);
  return resumo;
}

async function main() {
  const inicio = new Date().toISOString();
  const db = admin.firestore();
  try { execFileSync(ADB, ['connect', DEVICE], { stdio: 'pipe' }); } catch { /* já conectado */ }
  adb('get-state');
  adb('reverse', '--remove-all');
  for (const [aparelho, host] of [[8080, 18080], [9099, 19099], [5001, 15001]]) adb('reverse', `tcp:${aparelho}`, `tcp:${host}`);
  try { adb('shell', 'pm', 'clear', PACOTE); } catch { /* ainda não instalado */ }
  await semear(db);
  await rede.ligar();
  const servidor = servirFunctions();
  const eventos = [];
  let erro = null;
  try {
    await rodarFase('offline', eventos);
    if (rede.ligada) await rede.cortar();
    await rodarFase('reabrir', eventos);
    await rede.ligar();
    eventos.push(...await verificarServidor(db));
  } catch (e) {
    erro = e;
  } finally {
    await rede.cortar().catch(() => {});
    salvarEvidencia(eventos, inicio);
    await new Promise(ok => servidor.close(ok));
    try { adb('reverse', '--remove-all'); } catch { /* aparelho saiu */ }
    await admin.app().delete();
  }
  if (erro) throw erro;
  if (process.env.OFFLINE_QA_ESTRITO === 'true' && eventos.some(e => !e.ok)) throw Error('Há etapas reprovadas.');
}

main().catch(e => { console.error(e); process.exitCode = 1; });
