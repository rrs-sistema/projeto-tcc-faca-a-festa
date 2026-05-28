import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';
import { admin } from "../src/shared/firebaseAdmin";
import OpenAI from 'openai';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

type SugestaoBaseIA = {
  id: string;
  titulo: string;
  descricao: string;
  modulo: string;
  tema: string;
  tipo_evento: string[];
  perfis_festa: string[];
  categoria: string;
  prioridade: string;
  gatilhos: Record<string, unknown>;
  tags: string[];
  ordem: number;
};

type AnaliseCalculadoraIAResponse = {
  titulo: string;
  resumo: string;
  diagnostico_financeiro: string;
  diagnostico_consumo: string;
  recomendacao_final: string;
  indice_conforto: number;
  indice_risco_faltar_itens: number;
  indice_economia: number;
  custo_total_estimado: number;
  diferenca_orcamento: number;
  sugestoes: Array<{
    id: string;
    titulo: string;
    descricao: string;
    tipo: string;
    prioridade: string;
    impacto_estimado: string;
    item_relacionado: string;
  }>;
  pontos_de_atencao: string[];
  proximas_acoes: string[];
  fonte: string;
  versao_schema: string;
  data_analise: string;
};

const db = admin.firestore();
export const analisarCalculadoraFestaIA = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 60,
    memory: '512MiB',
    secrets: ['OPENAI_API_KEY'],
  },
  async (request): Promise<AnaliseCalculadoraIAResponse> => {
    const payload = normalizarPayloadCalculadora(request.data ?? {});

    if (!payload) {
      throw new HttpsError('invalid-argument', 'Payload da calculadora inválido.');
    }

    const sugestoesBase = await buscarSugestoesBaseCalculadora({
      tipoEvento: payload.tipoEvento,
      perfilFesta: payload.perfilFesta,
      limit: 12,
    });

    try {
      if (!process.env.OPENAI_API_KEY) {
        throw new Error('OPENAI_API_KEY não configurada no ambiente da Cloud Function.');
      }

      const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

      const completion = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL ?? 'gpt-4.1-mini',
        temperature: 0.35,
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content: buildSystemPromptCalculadoraIA(),
          },
          {
            role: 'user',
            content: JSON.stringify({
              payload_calculadora: payload,
              sugestoes_base_do_sistema: sugestoesBase,
              instrucoes: [
                'Use os dados da calculadora como fonte principal.',
                'Use as sugestões base como referência curada do sistema Faça a Festa.',
                'Não recalcule quantidades matemáticas.',
                'Não invente custos que não estejam no payload.',
                'Retorne somente JSON válido compatível com o schema solicitado.',
              ],
            }),
          },
        ],
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia retornada pela IA generativa.');
      }

      const parsed = JSON.parse(content) as Partial<AnaliseCalculadoraIAResponse>;
      return normalizarRespostaIA(parsed, payload, 'ia_generativa');
    } catch (error) {
      logger.error('Erro ao executar análise inteligente da calculadora:', error);
      return gerarFallbackLocal(payload, sugestoesBase);
    }
  },
);

function buildSystemPromptCalculadoraIA(): string {
  return `
Você é uma assistente especialista em planejamento de festas do aplicativo Faça a Festa.

Regras obrigatórias:
- Você deve analisar o payload da calculadora e apoiar a tomada de decisão do organizador.
- Você NÃO deve recalcular quantidades matemáticas, porções ou totais. A calculadora já fez isso.
- Você NÃO deve inventar custos, preços, totais ou diferenças fora dos dados enviados.
- Você deve usar as sugestões base do sistema como referência curada.
- Você pode adaptar as sugestões base ao contexto real do evento.
- Priorize recomendações compatíveis com tipo de evento, perfil de festa, orçamento, adultos, crianças, bebês, duração e risco informado.
- Seja objetiva, prática e útil para o usuário final.
- Mantenha linguagem clara, profissional e amigável.
- Responda exclusivamente em JSON válido. Não use markdown.

Schema obrigatório:
{
  "titulo": "string",
  "resumo": "string",
  "diagnostico_financeiro": "string",
  "diagnostico_consumo": "string",
  "recomendacao_final": "string",
  "indice_conforto": 0,
  "indice_risco_faltar_itens": 0,
  "indice_economia": 0,
  "custo_total_estimado": 0,
  "diferenca_orcamento": 0,
  "sugestoes": [
    {
      "id": "string",
      "titulo": "string",
      "descricao": "string",
      "tipo": "alerta|economia|consumo|financeiro|organizacao|fornecedor|cardapio|decoracao|geral",
      "prioridade": "baixa|media|alta|critica",
      "impacto_estimado": "string",
      "item_relacionado": "string"
    }
  ],
  "pontos_de_atencao": ["string"],
  "proximas_acoes": ["string"],
  "fonte": "ia_generativa",
  "versao_schema": "1.1.0",
  "data_analise": "ISO-8601"
}

Limites:
- Gere no máximo 6 sugestões.
- Gere no máximo 5 pontos de atenção.
- Gere no máximo 5 próximas ações.
`.trim();
}

async function buscarSugestoesBaseCalculadora(params: {
  tipoEvento?: string;
  perfilFesta?: string;
  limit?: number;
}): Promise<SugestaoBaseIA[]> {
  const tipoEvento = normalizeToken(params.tipoEvento ?? '');
  const perfilFesta = normalizeToken(params.perfilFesta ?? '');
  const limit = params.limit ?? 12;

  const snapshot = await db
    .collection('ia_sugestoes_base')
    .where('ativo', '==', true)
    .where('modulo', '==', 'calculadora')
    .orderBy('ordem', 'asc')
    .limit(60)
    .get();

  const sugestoes = snapshot.docs.map((doc) => normalizarSugestaoBase(doc.id, doc.data()));

  const filtradas = sugestoes.filter((sugestao) => {
    return aceitaValor(sugestao.tipo_evento, tipoEvento) && aceitaValor(sugestao.perfis_festa, perfilFesta);
  });

  const listaFinal = filtradas.length > 0
    ? filtradas
    : sugestoes.filter((sugestao) => sugestao.tipo_evento.includes('todos') || sugestao.perfis_festa.includes('todos'));

  return ordenarSugestoes(listaFinal.length > 0 ? listaFinal : sugestoes).slice(0, limit);
}

function normalizarSugestaoBase(id: string, data: FirebaseFirestore.DocumentData): SugestaoBaseIA {
  return {
    id: asString(data.id, id),
    titulo: asString(data.titulo),
    descricao: asString(data.descricao),
    modulo: normalizeToken(asString(data.modulo)),
    tema: normalizeToken(asString(data.tema)),
    tipo_evento: asStringArray(data.tipo_evento ?? data.tipoEvento),
    perfis_festa: asStringArray(data.perfis_festa ?? data.perfisFesta),
    categoria: normalizeToken(asString(data.categoria, 'geral')),
    prioridade: normalizeToken(asString(data.prioridade, 'media')),
    gatilhos: asRecord(data.gatilhos),
    tags: asStringArray(data.tags),
    ordem: asNumber(data.ordem),
  };
}

function normalizarPayloadCalculadora(data: unknown): PayloadCalculadoraNormalizado | null {
  const record = asRecord(data);

  if (Object.keys(record).length === 0) {
    return null;
  }

  const tipoEvento = normalizeToken(
    asString(record.tipoEvento ?? record.tipo_evento ?? record.eventoTipo),
  );

  const perfilFesta = normalizeToken(
    asString(record.perfilFesta ?? record.perfil_festa ?? record.perfil),
  );

  const custoTotalEstimado = asNumber(
    record.custoTotalEstimado ??
    record.custo_total_estimado ??
    record.totalEstimado,
  );

  const orcamentoDisponivel = asNumber(
    record.orcamentoDisponivel ??
    record.orcamento_disponivel ??
    record.orcamento,
  );

  const diferencaOrcamento =
    record.diferencaOrcamento !== undefined ||
      record.diferenca_orcamento !== undefined
      ? asNumber(record.diferencaOrcamento ?? record.diferenca_orcamento)
      : orcamentoDisponivel - custoTotalEstimado;

  return {
    ...record,
    tipoEvento,
    perfilFesta,
    adultos: asNumber(record.adultos),
    criancas: asNumber(record.criancas ?? record.crianças),
    bebes: asNumber(record.bebes ?? record.bebês),
    convidadosEquivalentes: asNumber(
      record.convidadosEquivalentes ?? record.convidados_equivalentes,
    ),
    duracaoHoras: asNumber(
      record.duracaoHoras ?? record.duracao_horas ?? record.duracao,
    ),
    indiceConforto: clampIndex(
      asNumber(record.indiceConforto ?? record.indice_conforto),
      70,
    ),
    indiceRiscoFaltarItens: clampIndex(
      asNumber(
        record.indiceRiscoFaltarItens ?? record.indice_risco_faltar_itens,
      ),
      30,
    ),
    indiceEconomia: clampIndex(
      asNumber(record.indiceEconomia ?? record.indice_economia),
      50,
    ),
    custoTotalEstimado,
    orcamentoDisponivel,
    diferencaOrcamento,
    itensCalculados:
      record.itensCalculados ??
      record.itens_calculados ??
      record.itens ??
      [],
  };
}

type PayloadCalculadoraNormalizado = Record<string, unknown> & {
  tipoEvento: string;
  perfilFesta: string;
  adultos: number;
  criancas: number;
  bebes: number;
  convidadosEquivalentes: number;
  duracaoHoras: number;
  indiceConforto: number;
  indiceRiscoFaltarItens: number;
  indiceEconomia: number;
  custoTotalEstimado: number;
  orcamentoDisponivel: number;
  diferencaOrcamento: number;
  itensCalculados: unknown;
};

function normalizarRespostaIA(
  response: Partial<AnaliseCalculadoraIAResponse>,
  payload: Record<string, unknown>,
  fonte: string,
): AnaliseCalculadoraIAResponse {
  return {
    titulo: asString(response.titulo, 'Análise inteligente da sua festa'),
    resumo: asString(response.resumo, 'A análise foi gerada com base nos dados atuais da calculadora.'),
    diagnostico_financeiro: asString(response.diagnostico_financeiro, 'Revise o orçamento disponível e os itens de maior impacto financeiro.'),
    diagnostico_consumo: asString(response.diagnostico_consumo, 'Revise o equilíbrio entre convidados, duração e itens selecionados.'),
    recomendacao_final: asString(response.recomendacao_final, 'Priorize os itens essenciais e revise pontos de maior risco antes de contratar fornecedores.'),
    indice_conforto: clampIndex(asNumber(response.indice_conforto), asNumber(payload.indiceConforto)),
    indice_risco_faltar_itens: clampIndex(asNumber(response.indice_risco_faltar_itens), asNumber(payload.indiceRiscoFaltarItens)),
    indice_economia: clampIndex(asNumber(response.indice_economia), asNumber(payload.indiceEconomia)),
    custo_total_estimado: asNumber(response.custo_total_estimado, asNumber(payload.custoTotalEstimado)),
    diferenca_orcamento: asNumber(response.diferenca_orcamento, asNumber(payload.diferencaOrcamento)),
    sugestoes: normalizarSugestoesIA(response.sugestoes),
    pontos_de_atencao: asStringArray(response.pontos_de_atencao).slice(0, 5),
    proximas_acoes: asStringArray(response.proximas_acoes).slice(0, 5),
    fonte,
    versao_schema: asString(response.versao_schema, '1.1.0'),
    data_analise: new Date().toISOString(),
  };
}

function gerarFallbackLocal(
  payload: PayloadCalculadoraNormalizado,
  sugestoesBase: SugestaoBaseIA[],
): AnaliseCalculadoraIAResponse {
  const risco = clampIndex(asNumber(payload.indiceRiscoFaltarItens), 30);
  const economia = clampIndex(asNumber(payload.indiceEconomia), 50);
  const conforto = clampIndex(asNumber(payload.indiceConforto), 70);
  const custo = asNumber(payload.custoTotalEstimado);
  const diferenca = asNumber(payload.diferencaOrcamento);
  const duracaoHoras = asNumber(payload.duracaoHoras);

  const sugestoes: AnaliseCalculadoraIAResponse['sugestoes'] = sugestoesBase
    .slice(0, 5)
    .map((item) => ({
      id: item.id,
      titulo: item.titulo,
      descricao: item.descricao,
      tipo: item.categoria || 'geral',
      prioridade: item.prioridade || 'media',
      impacto_estimado: 'Apoia a organização e reduz riscos no planejamento.',
      item_relacionado: item.tema || 'geral',
    }));

  if (sugestoes.length === 0) {
    sugestoes.push({
      id: 'fallback_revisar_itens_essenciais',
      titulo: 'Revise os itens essenciais',
      descricao:
        'Confira alimentos, bebidas, bolo e itens de maior impacto antes de fechar fornecedores.',
      tipo: 'organizacao',
      prioridade: risco >= 70 ? 'alta' : 'media',
      impacto_estimado:
        'Ajuda a reduzir risco de falta e gastos desnecessários.',
      item_relacionado: 'planejamento',
    });
  }

  const pontosDeAtencao: string[] = [];

  if (diferenca < 0) {
    pontosDeAtencao.push(
      'Custo estimado acima do orçamento disponível.',
    );
  }

  if (risco >= 70) {
    pontosDeAtencao.push(
      'Risco alto de faltar itens.',
    );
  }

  if (duracaoHoras >= 4) {
    pontosDeAtencao.push(
      'Duração longa pode elevar consumo de bebidas e reposições.',
    );
  }

  if (economia <= 35) {
    pontosDeAtencao.push(
      'Há baixa margem de economia para ajustes no orçamento.',
    );
  }

  if (conforto <= 50) {
    pontosDeAtencao.push(
      'O índice de conforto está baixo; revise a quantidade de itens principais.',
    );
  }

  if (pontosDeAtencao.length === 0) {
    pontosDeAtencao.push(
      'Nenhum ponto crítico identificado, mas revise os itens principais antes de fechar a festa.',
    );
  }

  const proximasAcoes: string[] = [
    'Revisar os itens essenciais da festa.',
    'Comparar orçamento disponível com custo estimado.',
    'Solicitar orçamentos dos fornecedores prioritários.',
    'Salvar a simulação para acompanhar ajustes posteriores.',
  ];

  return {
    titulo: 'Análise inteligente da sua festa',
    resumo:
      'Geramos uma análise local com base nos dados da calculadora e nas sugestões base disponíveis.',
    diagnostico_financeiro:
      diferenca < 0
        ? 'O custo estimado está acima do orçamento informado. Priorize itens essenciais e revise itens opcionais.'
        : 'O orçamento informado comporta a estimativa atual, mas ainda é importante acompanhar os itens pendentes.',
    diagnostico_consumo:
      risco >= 70
        ? 'Há risco elevado de faltar itens. Revise os itens de maior consumo e considere margem de segurança.'
        : 'O consumo estimado parece controlado, mas deve ser revisado conforme a duração e o perfil dos convidados.',
    recomendacao_final:
      'Use esta análise como apoio à decisão e mantenha o cálculo principal sob responsabilidade da calculadora.',
    indice_conforto: conforto,
    indice_risco_faltar_itens: risco,
    indice_economia: economia,
    custo_total_estimado: custo,
    diferenca_orcamento: diferenca,
    sugestoes,
    pontos_de_atencao: pontosDeAtencao.slice(0, 5),
    proximas_acoes: proximasAcoes,
    fonte: 'fallback_local',
    versao_schema: '1.1.0',
    data_analise: new Date().toISOString(),
  };
}

function normalizarSugestoesIA(value: unknown): AnaliseCalculadoraIAResponse['sugestoes'] {
  if (!Array.isArray(value)) return [];

  return value.slice(0, 6).map((item, index) => {
    const data = asRecord(item);
    return {
      id: asString(data.id, `sugestao_${index + 1}`),
      titulo: asString(data.titulo, 'Sugestão para sua festa'),
      descricao: asString(data.descricao, 'Revise este ponto no planejamento do evento.'),
      tipo: normalizeToken(asString(data.tipo, 'geral')),
      prioridade: normalizeToken(asString(data.prioridade, 'media')),
      impacto_estimado: asString(data.impacto_estimado, 'Melhora a organização do evento.'),
      item_relacionado: normalizeToken(asString(data.item_relacionado, 'geral')),
    };
  });
}

function ordenarSugestoes(sugestoes: SugestaoBaseIA[]): SugestaoBaseIA[] {
  return [...sugestoes].sort((a, b) => {
    const prioridadeCompare = pesoPrioridade(b.prioridade) - pesoPrioridade(a.prioridade);
    if (prioridadeCompare !== 0) return prioridadeCompare;
    return a.ordem - b.ordem;
  });
}

function aceitaValor(lista: string[], valor: string): boolean {
  if (!valor) return true;
  if (lista.length === 0) return true;
  return lista.includes(valor) || lista.includes('todos');
}

function pesoPrioridade(prioridade: string): number {
  switch (normalizeToken(prioridade)) {
    case 'critica':
      return 4;
    case 'alta':
      return 3;
    case 'media':
      return 2;
    case 'baixa':
      return 1;
    default:
      return 0;
  }
}

function asString(value: unknown, fallback = ''): string {
  if (value === undefined || value === null) return fallback;
  return String(value).trim();
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const normalized = value.replace(',', '.').replace(/[^0-9.-]/g, '');
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function asStringArray(value: unknown): string[] {
  if (Array.isArray(value)) {
    return [...new Set(value.map((item) => normalizeToken(String(item))).filter(Boolean))];
  }
  if (typeof value === 'string') {
    return [...new Set(value.split(',').map((item) => normalizeToken(item)).filter(Boolean))];
  }
  return [];
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function normalizeToken(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, '_').replace(/-/g, '_');
}

function clampIndex(value: number, fallback = 0): number {
  const base = Number.isFinite(value) ? value : fallback;
  return Math.max(0, Math.min(100, Math.round(base)));
}
