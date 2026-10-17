import { limitarAnaliseCalculadora } from "../../services/calculadora/limiteAnaliseCalculadoraService";
import { financeiroCalculadora } from "../../services/calculadora/financeiroCalculadoraService";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { admin } from "../../shared/firebaseAdmin";
import { buildInput, buildInstructions } from "../../ia/calculadora/prompt";
import { buscarSugestoesBaseCalculadora } from "../../services/calculadora/sugestoesBaseIAService";
import { aplicarRastreabilidadeAnalise } from "../../services/calculadora/rastreabilidadeCalculadoraIAService";
import { AnaliseCalculadoraIAResponse, CalculadoraIARequest } from "../../types/calculadoraIA.types";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const DEFAULT_REGION = "southamerica-east1";
const COLLECTION_CALCULADORA_FESTA = "calculadora_festa";

/**
 * Function de análise inteligente da calculadora.
 *
 * Observação arquitetural:
 * - A IA gera o conteúdo analítico.
 * - A Cloud Function injeta a rastreabilidade técnica/editorial.
 * - O app Flutter continua lendo o mesmo objeto `analise_ia`.
 */
export const analisarCalculadoraFestaIA = onCall(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
    cors: true,
    secrets: [OPENAI_API_KEY],
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Faça login para analisar a calculadora.",
      );
    }

    const rawData = asRecord(request.data);
    const payload = normalizarPayloadCalculadora(rawData);
    payload.id_usuario = uid;
    payload.idUsuario = uid;
    await validarAcessoCalculadora(payload, uid);
    if (JSON.stringify(payload).length > 450000) throw new HttpsError("invalid-argument", "O planejamento excede o tamanho de análise permitido.");
    await limitarAnaliseCalculadora(uid);
    let sugestoesBase: Awaited<ReturnType<typeof buscarSugestoesBaseCalculadora>> = [];
    try {
      const perfil = asRecord(payload.perfil_festa ?? payload.perfilFesta);
      sugestoesBase = await buscarSugestoesBaseCalculadora({
        tipoEvento: asString(payload.tipo_evento ?? payload.tipoEvento),
        perfilFesta: asString(payload.perfil_festa_tipo ?? perfil.tipo ?? perfil.nome ?? payload.perfil_festa),
        limit: 12,
      });
    } catch (error) {
      logger.warn("Base editorial indisponível; análise continua com os dados da simulação.", {
        erro: error instanceof Error ? error.message : String(error),
      });
    }

    const modeloIAUtilizado = resolverModeloIA();

    try {
      const rawAnaliseIA = await gerarAnaliseGenerativa({
        payload,
        sugestoesBase,
        modeloIAUtilizado,
      });

      const analise = aplicarRastreabilidadeAnalise(
        completarAnaliseComDadosCalculadora(rawAnaliseIA, payload),
        {
          sugestoesBase,
          modeloIAUtilizado,
          fonte: "ia_generativa",
        },
      );


      return montarRespostaFunction(analise);
    } catch (error) {
      logger.warn("Falha ao executar IA generativa. Usando fallback local.", {
        erro: error instanceof Error ? error.message : String(error),
        idCalculo: payload.id_calculo ?? payload.idCalculo ?? payload.id,
      });

      const analiseFallback = aplicarRastreabilidadeAnalise(
        completarAnaliseComDadosCalculadora(buildFallbackLocal(payload), payload),
        {
          sugestoesBase,
          modeloIAUtilizado: "fallback_local",
          fonte: "fallback_local",
        },
      );


      return montarRespostaFunction(analiseFallback);
    }
  },
);

async function validarAcessoCalculadora(payload: CalculadoraIARequest, uid: string): Promise<void> {
  const db = admin.firestore();
  const eventoId = asString(payload.id_evento ?? payload.idEvento);
  const calculoId = asString(payload.id_calculo ?? payload.idCalculo ?? payload.id);
  const usuario = await db.collection("usuarios").doc(uid).get();
  const isAdmin = usuario.data()?.tipo === "A" && usuario.data()?.ativo !== false;
  if (eventoId && eventoId !== "estimativa_temporaria") {
    const evento = await db.collection("evento").doc(eventoId).get();
    if (!isAdmin && (!evento.exists || evento.data()?.id_usuario !== uid)) {
      throw new HttpsError("permission-denied", "Esta festa não pertence ao usuário autenticado.");
    }
  }
  if (calculoId) {
    const calculo = await db.collection(COLLECTION_CALCULADORA_FESTA).doc(calculoId).get();
    if (calculo.exists && !isAdmin) {
      const dados = calculo.data() ?? {};
      if (dados.id_usuario !== uid && dados.idUsuario !== uid &&
          !(dados.id_evento === eventoId && eventoId && eventoId !== "estimativa_temporaria" && !dados.id_usuario && !dados.idUsuario)) {
        throw new HttpsError("permission-denied", "Sem permissão para analisar esta simulação.");
      }
      if (dados.id_evento && dados.id_evento !== eventoId) {
        throw new HttpsError("permission-denied", "A simulação pertence a outra festa.");
      }
    }
  }
}

async function gerarAnaliseGenerativa(params: {
  payload: CalculadoraIARequest;
  sugestoesBase: Awaited<ReturnType<typeof buscarSugestoesBaseCalculadora>>;
  modeloIAUtilizado: string;
}): Promise<Record<string, unknown>> {
  const apiKey = OPENAI_API_KEY.value() || process.env.OPENAI_API_KEY;

  if (!apiKey) {
    throw new Error("OPENAI_API_KEY não configurada.");
  }

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    signal: AbortSignal.timeout(45000),
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: params.modeloIAUtilizado,
      temperature: 0.25,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: buildInstructions(),
        },
        {
          role: "user",
          content: buildInput(params.payload, params.sugestoesBase),
        },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Provider IA retornou HTTP ${response.status}: ${body}`);
  }

  const data = asRecord(await response.json());
  const choices = Array.isArray(data.choices) ? data.choices : [];
  const firstChoice = asRecord(choices[0]);
  const message = asRecord(firstChoice.message);
  const content = asString(message.content);

  if (!content) {
    throw new Error("Resposta da IA sem conteúdo JSON.");
  }

  return parseJsonObject(content);
}

function normalizarPayloadCalculadora(rawData: Record<string, unknown>): CalculadoraIARequest {
  const payload = asRecord(
    rawData.calculo ??
    rawData.simulacao ??
    rawData.payload ??
    rawData.data ??
    rawData,
  );

  return payload as CalculadoraIARequest;
}

function completarAnaliseComDadosCalculadora(
  rawAnalise: Record<string, unknown>,
  payload: CalculadoraIARequest,
): Record<string, unknown> {
  const financeiro = financeiroCalculadora(payload);
  const planejamento = asRecord(payload.planejamento);
  const pendencias = [...new Set([
    ...(Array.isArray(planejamento.pendencias_alimentares) ? planejamento.pendencias_alimentares : []),
    ...(Array.isArray(planejamento.analise_refeicao) ? planejamento.analise_refeicao : []),
  ].filter((p): p is string => typeof p === "string" && p.trim().length > 0)
    .map(p => p.slice(0, 600)))].slice(0, 30);
  const custoTotalEstimado = financeiro.custo;
  const orcamentoDisponivel = financeiro.orcamento;
  const diferencaOrcamento = financeiro.diferenca;

  return {
    ...rawAnalise,
    titulo: asString(rawAnalise.titulo, "Análise inteligente da festa"),
    resumo: pendencias.length > 0
      ? "Há pendências na composição ou no atendimento dos grupos alimentares. Confira as porções e o preparo antes de considerar a refeição revisada."
      : asString(rawAnalise.resumo, "Análise gerada com base na simulação da calculadora."),
    indice_economia: 0,
    indices_calibrados: false,
    indice_risco_faltar_itens: 0,
    indice_conforto: 0,
    custo_total_estimado: custoTotalEstimado,
    orcamento_disponivel: orcamentoDisponivel,
    diferenca_orcamento: diferencaOrcamento,
    data_analise: asString(rawAnalise.data_analise, new Date().toISOString()),
    sugestoes: Array.isArray(rawAnalise.sugestoes) ? rawAnalise.sugestoes : [],
    diagnostico_financeiro: financeiro.incompleto ? "Estimativa parcial: faltam regras, preços ou a consulta aos gastos existentes. Não é possível concluir se a festa cabe no limite." : asString(rawAnalise.diagnostico_financeiro),
    diagnostico_consumo: pendencias.length > 0 ? pendencias.join(" ") : asString(rawAnalise.diagnostico_consumo),
    recomendacao_final: pendencias.length > 0 ? "Revise as pendências de alimentação e confirme ingredientes e preparo com o responsável por servir." : asString(rawAnalise.recomendacao_final),
    pontos_de_atencao: [...pendencias, ...(Array.isArray(rawAnalise.pontos_de_atencao) ? rawAnalise.pontos_de_atencao : [])],
    proximas_acoes: Array.isArray(rawAnalise.proximas_acoes) ? rawAnalise.proximas_acoes : [],
  };
}

function buildFallbackLocal(payload: CalculadoraIARequest): Record<string, unknown> {
  const financeiro = financeiroCalculadora(payload);
  const custoTotalEstimado = financeiro.custo;
  const orcamentoDisponivel = financeiro.orcamento;
  const diferencaOrcamento = financeiro.diferenca;
  const acimaDoOrcamento = orcamentoDisponivel !== null && diferencaOrcamento > 0;

  return {
    titulo: "Análise inteligente da festa",
    resumo: financeiro.incompleto
      ? "Estimativa parcial: configure os consumos e preços pendentes e confira os gastos existentes antes de avaliar o orçamento."
      : acimaDoOrcamento
      ? "A estimativa ficou acima do orçamento informado. Vale revisar itens de maior custo e priorizar o essencial."
      : "A simulação está coerente para o planejamento inicial. Revise quantidades e fornecedores antes de fechar os gastos.",
    indice_economia: 0,
    indices_calibrados: false,
    indice_risco_faltar_itens: 0,
    indice_conforto: 0,
    custo_total_estimado: custoTotalEstimado,
    orcamento_disponivel: orcamentoDisponivel,
    diferenca_orcamento: diferencaOrcamento,
    data_analise: new Date().toISOString(),
    sugestoes: [
      {
        id: "revisar_itens_maior_custo",
        titulo: "Revise os itens de maior custo",
        descricao: "Confira os itens mais caros da simulação antes de transformar a estimativa em orçamento.",
        tipo: acimaDoOrcamento ? "economia" : "planejamento",
        prioridade: acimaDoOrcamento ? "alta" : "media",
        item_relacionado: null,
        impacto_estimado: Math.max(0, diferencaOrcamento),
      },
      {
        id: "validar_quantidades_com_fornecedores",
        titulo: "Valide as quantidades com fornecedores",
        descricao: "Use a simulação como base, mas confirme disponibilidade, porções e condições comerciais antes da contratação.",
        tipo: "planejamento",
        prioridade: "media",
        item_relacionado: null,
        impacto_estimado: 0,
      },
    ],
    diagnostico_financeiro: financeiro.incompleto
      ? "Não há dados completos para avaliar o limite total da festa."
      : orcamentoDisponivel === null
        ? "Informe o limite total da festa para avaliar a projeção financeira."
        : acimaDoOrcamento
      ? "O custo estimado está acima do orçamento informado. Priorize cortes em itens opcionais ou negocie valores com fornecedores."
      : "O custo estimado está dentro de um cenário controlado para planejamento inicial.",
    diagnostico_consumo: "As quantidades calculadas devem ser revisadas considerando duração, perfil dos convidados e estilo da festa.",
    recomendacao_final: "Antes de avançar, salve a simulação, revise os itens essenciais e compare pelo menos duas opções de fornecedores.",
    pontos_de_atencao: [
      "Conferir itens com maior custo estimado.",
      "Validar quantidades para adultos, crianças e bebês.",
      "Confirmar orçamento antes de contratar fornecedores.",
    ],
    proximas_acoes: [
      "Revisar itens selecionados na calculadora.",
      "Comparar fornecedores por categoria.",
      "Transformar itens aprovados em orçamento do evento.",
    ],
  };
}

function montarRespostaFunction(analise: AnaliseCalculadoraIAResponse): Record<string, unknown> {
  return {
    ok: true,
    analise,
    analise_ia: analise,
    analysis: analise,
    ...analise,
  };
}

function resolverModeloIA(): string {
  return process.env.MODELO_IA_CALCULADORA || process.env.OPENAI_MODEL || "gpt-4o-mini";
}

function parseJsonObject(content: string): Record<string, unknown> {
  try {
    const parsed = JSON.parse(content);
    return asRecord(parsed);
  } catch (_) {
    const match = content.match(/\{[\s\S]*\}/);
    if (!match) throw new Error("Conteúdo retornado pela IA não é JSON válido.");
    return asRecord(JSON.parse(match[0]));
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function asString(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  const text = String(value).trim();
  return text.length > 0 && text !== "null" ? text : fallback;
}
