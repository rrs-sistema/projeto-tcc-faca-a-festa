const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const ts = require('typescript');

// Exercita módulos puros sem regenerar os artefatos compilados do projeto.
function carregar(arquivo, stubs = {}) {
  const source = fs.readFileSync(path.resolve(__dirname, '../src', arquivo), 'utf8');
  const codigo = ts.transpileModule(source, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020,
  } }).outputText;
  const modulo = { exports: {} };
  new Function('module', 'exports', 'require', codigo)(modulo, modulo.exports, (nome) => stubs[nome] ?? require(nome));
  return modulo.exports;
}

const { financeiroCalculadora } = carregar('services/calculadora/financeiroCalculadoraService.ts');
const { buildInput, buildInstructions } = carregar('ia/calculadora/prompt.ts', {
  '../../services/calculadora/financeiroCalculadoraService': { financeiroCalculadora },
});
const payload = {
  custo_total_estimado: 176, orcamento_disponivel: 650,
  planejamento: { custo_projetado: 676, gastos_existentes: 600,
    custo_adicional_estimado: 76, estimativa_incompleta: false, orcamento_carregado: true,
    cardapio: 'Almoço', itens_cardapio: [{ nome: 'Bolo', quantidade_planejada: 3, confirmado: true }] },
};
assert.deepEqual(financeiroCalculadora(payload), { custo: 676, orcamento: 650, diferenca: 26, incompleto: false });
for (const planejamento of [
  { ...payload.planejamento, estimativa_incompleta: true },
  { ...payload.planejamento, orcamento_carregado: false },
]) {
  const parcial = financeiroCalculadora({ ...payload, planejamento });
  assert.equal(parcial.incompleto, true);
  assert.equal(parcial.orcamento, null);
}
assert.equal(financeiroCalculadora({ custo_total_estimado: 100 }).orcamento, null);
assert.equal(financeiroCalculadora({ custo_total_estimado: Infinity }).custo, 0);
const conciliado = {
  ...payload,
  planejamento: { ...payload.planejamento, custo_projetado: 999,
    compras_restantes: { versao_financeiro: 2, completo: true, consulta_completa: true,
      sobreposicao_orcamento: false, orcado: 20, compras_restantes_conhecidas: 0,
      quantidades_pendentes: 0, precos_pendentes: 0, compras_sem_registro_financeiro: 0 } },
  orcamento_disponivel: 50,
};
assert.deepEqual(financeiroCalculadora(conciliado), { custo: 20, incompleto: false, orcamento: 50, diferenca: -30 });
for (const pendencia of [{ completo: false }, { consulta_completa: false },
  { sobreposicao_orcamento: true }, { quantidades_pendentes: 1 },
  { precos_pendentes: 1 }, { compras_sem_registro_financeiro: 1 },
  { orcado: undefined }, { compras_restantes_conhecidas: NaN },
  { compras_restantes_conhecidas: -1 }, { precos_pendentes: '0' }]) {
  const parcial = financeiroCalculadora({ ...conciliado, planejamento: { ...conciliado.planejamento,
    compras_restantes: { ...conciliado.planejamento.compras_restantes, ...pendencia } } });
  assert.equal(parcial.incompleto, true);
  assert.equal(parcial.orcamento, null);
}
const input = JSON.parse(buildInput(payload));
assert.deepEqual(input.planejamento, payload.planejamento);
assert.equal(input.financeiro.custo_total_estimado, 676);
assert.equal(input.financeiro.custo_simulacao, 176);
assert.ok(buildInstructions().includes('Não invente consumo para itens sem regra'));
assert.ok(buildInstructions().includes('proposta_apenas_servir'));
assert.ok(buildInstructions().includes('proposta_respostas'));
console.log('Calculadora planejamento/IA: OK');

async function testarAcessoCallable() {
  class HttpsError extends Error {
    constructor(code, message) { super(message); this.code = code; }
  }
  let perfilBuscado;
  let falharBase = false;
  const fetchOriginal = global.fetch;
  global.fetch = async () => { throw new Error('Rede bloqueada no teste'); };
  const documentos = {
    'usuarios/owner': { tipo: 'O', ativo: true },
    'evento/festa': { id_usuario: 'owner' },
    'calculadora_festa/alheia': { id_usuario: 'other', id_evento: 'festa' },
  };
  const { analisarCalculadoraFestaIA } = carregar('functions/calculadora/analisarCalculadoraFestaIA.ts', {
    'firebase-functions/params': { defineSecret: () => ({ value: () => '' }) },
    'firebase-functions/logger': { warn: () => {}, info: () => {} },
    'firebase-functions/v2/https': { HttpsError, onCall: (_, handler) => handler },
    '../../shared/firebaseAdmin': { admin: { firestore: () => ({
      collection: (colecao) => ({ doc: (id) => ({ get: async () => {
        const data = documentos[`${colecao}/${id}`];
        return { exists: !!data, data: () => data };
      } }) }),
    }) } },
    '../../ia/calculadora/prompt': { buildInput, buildInstructions },
    '../../services/calculadora/limiteAnaliseCalculadoraService': { limitarAnaliseCalculadora: async () => {} },
    '../../services/calculadora/financeiroCalculadoraService': { financeiroCalculadora },
    '../../services/calculadora/sugestoesBaseIAService': { buscarSugestoesBaseCalculadora: async (params) => {
      perfilBuscado = params.perfilFesta;
      if (falharBase) throw new Error('Base indisponível');
      return [];
    } },
    '../../services/calculadora/rastreabilidadeCalculadoraIAService': { aplicarRastreabilidadeAnalise: (analise, meta) => ({ ...analise, fonte: meta.fonte }) },
  });
  await assert.rejects(analisarCalculadoraFestaIA({ data: {} }), (error) => error.code === 'unauthenticated');
  await assert.rejects(analisarCalculadoraFestaIA({ auth: { uid: 'other' }, data: { id_evento: 'festa', id_usuario: 'owner' } }),
    (error) => error.code === 'permission-denied');
  await assert.rejects(analisarCalculadoraFestaIA({ auth: { uid: 'owner' }, data: { id_evento: 'festa', id_calculo: 'alheia' } }),
    (error) => error.code === 'permission-denied');
  const resposta = await analisarCalculadoraFestaIA({ auth: { uid: 'owner' }, data: {
    ...payload, id_evento: 'festa', id_calculo: 'nova', perfil_festa: { tipo: 'padrao', nome: 'Padrão' },
  } });
  assert.equal(perfilBuscado, 'padrao');
  assert.equal(resposta.analise.fonte, 'fallback_local');
  assert.equal(resposta.analise.custo_total_estimado, 676);
  assert.equal(resposta.analise.diferenca_orcamento, 26);
  assert.equal(resposta.analise.indice_risco_faltar_itens, 0);
  assert.equal(resposta.analise.indice_conforto, 0);
  const alimentar = await analisarCalculadoraFestaIA({ auth: { uid: 'owner' }, data: {
    ...payload, id_evento: 'festa', planejamento: { ...payload.planejamento,
      pendencias_alimentares: ['Jantar: grupo sem prato principal destinado.'] },
  } });
  assert.ok(alimentar.analise.diagnostico_consumo.includes('grupo sem prato principal'));
  assert.ok(alimentar.analise.resumo.includes('pendências'));
  assert.ok(alimentar.analise.pontos_de_atencao.includes('Jantar: grupo sem prato principal destinado.'));
  falharBase = true;
  const semBase = await analisarCalculadoraFestaIA({ auth: { uid: 'owner' }, data: { ...payload, id_evento: 'festa' } });
  assert.equal(semBase.analise.fonte, 'fallback_local');
  global.fetch = fetchOriginal;
  console.log('Calculadora callable: autorização, perfil e fallback OK');
}
async function testarLimite() {
  class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
  let estado = {};
  const { limitarAnaliseCalculadora } = carregar('services/calculadora/limiteAnaliseCalculadoraService.ts', {
    'firebase-functions/v2/https': { HttpsError },
    '../../shared/firebaseAdmin': { admin: { firestore: () => ({
      collection: (name) => { assert.equal(name, 'calculadora_ia_limites'); return { doc: (uid) => ({ uid }) }; },
      runTransaction: async (fn) => fn({ get: async () => ({ data: () => estado }), set: (_, data) => { estado = data; } }),
    }) } },
  });
  await limitarAnaliseCalculadora('owner');
  assert.equal(estado.chamadas, 1);
  await assert.rejects(limitarAnaliseCalculadora('owner'), e => e.code === 'resource-exhausted');
  estado = { inicio: Date.now(), chamadas: 60, ultima: Date.now() - 2000 };
  await assert.rejects(limitarAnaliseCalculadora('owner'), e => e.code === 'resource-exhausted');
  estado = { inicio: Date.now() - 301000, chamadas: 60, ultima: Date.now() - 2000 };
  await limitarAnaliseCalculadora('owner');
  assert.equal(estado.chamadas, 1);
  console.log('Calculadora: limite compartilhado e renovação OK');
}


const { validarPoliticaPublico } = carregar('services/calculadora/publicoPlanejamentoService.ts');
for (const cfg of [{}, {base:'confirmados',base_confirmada:true,lista_completude:'em_preenchimento'},
  {base:'manual',base_confirmada:true,publico:{adultos:0,criancas:0,bebes:0}}]) validarPoliticaPublico(cfg);
for (const cfg of [{lista_completude:'automatica'}, {base:'capacidade'}, {base_confirmada:true},
  {base:'manual',base_confirmada:true}, {publico:{adultos:-1,criancas:0,bebes:0}}]) assert.throws(() => validarPoliticaPublico(cfg));
const zeroConfirmado=financeiroCalculadora({orcamento_disponivel:0,custo_total_estimado:500});
assert.equal(zeroConfirmado.orcamento,0);assert.equal(zeroConfirmado.diferenca,500);
console.log('Calculadora: política privada de público e zero confirmado OK');

for (const cfg of [{duracao:6,perfil:'premium',margem:.1,verba_alimentacao:1450},{margem:0,verba_alimentacao:0},{margem:null,verba_alimentacao:null}]) validarPoliticaPublico(cfg);
for (const cfg of [{duracao:0},{duracao:25},{duracao:1.5},{perfil:'luxo'},{margem:-.1},{margem:.31},{verba_alimentacao:-1},{verba_alimentacao:'1450'}]) assert.throws(() => validarPoliticaPublico(cfg));
console.log('Calculadora: configuração uniforme, nulos, zero e limites OK');

const {validarAgenda,validarOcorrencia}=carregar('services/calculadora/agendaServicoService.ts');
const ocorrencia={id:'oc_1',id_cardapio:'oc_1',id_evento:'festa',id_modelo:'modelo',titulo:'Almoço',formato:'nao_definido',data_local:null,hora_local:null,fuso:null,duracao_minutos:null};
validarAgenda([ocorrencia],'festa');validarOcorrencia({...ocorrencia,data_local:'2026-10-20',hora_local:'12:00',fuso:'America/Sao_Paulo',duracao_minutos:60},'2026-10-20','2026-10-21');
for(const extra of [{data_local:'2026-02-30'},{hora_local:'25:00'},{duracao_minutos:0},{fuso:'Inválido/Inventado'},{id_modelo:'oc_1'},{data_local:'2026-03-08',hora_local:'02:30',fuso:'America/New_York'}]) assert.throws(()=>validarOcorrencia({...ocorrencia,...extra}));
assert.throws(()=>validarAgenda([ocorrencia,ocorrencia]));assert.throws(()=>validarAgenda([ocorrencia],'outra'));
console.log('Calculadora: agenda civil, fuso, intervalo e identidade OK');
const {validarReferenciaContextual}=carregar('services/calculadora/catalogoContextualService.ts');
const referencia={schema:1,motor_minimo:1,id:'referencia_qa',versao:1,tipo:'porcao',nome:'Sintético',aliases:['Sintético'],alimento_receita:'Sintético',servicos:['lanche'],formatos:['buffet'],periodos:['qualquer'],publicos:['todos'],obtencoes:['servir'],papel:'outro',unidade:'quilo',estado_consumo:'pronto',estado_compra:'pronto',contexto:'Somente teste',limitacoes:'Não usar como referência real',fonte:'https://example.test/qa',verificado_em:null,revisao_editorial:'Fixture',minimo:.1,maximo:.2,padrao:.15};
validarReferenciaContextual(referencia);
assert.throws(()=>validarReferenciaContextual({...referencia,id:123}));
assert.throws(()=>validarReferenciaContextual({...referencia,fonte:'codigo:'}));
for(const extra of [{schema:2},{motor_minimo:2},{versao:0},{padrao:1},{minimo:0},{fonte:'inventada'},{publicos:['desconhecido']},{hora_inicio:'09:00'},{duracao_minima:41,duracao_maxima:30},{campo_desconhecido:true}]) assert.throws(()=>validarReferenciaContextual({...referencia,...extra}));
validarReferenciaContextual({...referencia,hora_inicio:'09:00',hora_fim:'10:00',duracao_minima:30,duracao_maxima:40});
console.log('Calculadora: catálogo contextual, estados, faixas e schema OK');

Promise.all([testarAcessoCallable(), testarLimite()]).catch((error) => { console.error(error); process.exit(1); });
