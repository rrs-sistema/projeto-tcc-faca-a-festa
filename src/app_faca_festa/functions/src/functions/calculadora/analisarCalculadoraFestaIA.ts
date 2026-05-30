import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { onCall } from "firebase-functions/v2/https";

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
    const rawData = asRecord(request.data);
    const payload = normalizarPayloadCalculadora(rawData);

    const sugestoesBase = await buscarSugestoesBaseCalculadora({
      tipoEvento: asString(payload.tipo_evento ?? payload.tipoEvento),
      perfilFesta: asString(payload.perfil_festa ?? payload.perfilFesta),
      limit: 12,
    });

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

      await salvarAnaliseNaSimulacao(payload, analise);

      return montarRespostaFunction(analise);
    } catch (error) {
      logger.warn("Falha ao executar IA generativa. Usando fallback local.", {
        erro: error instanceof Error ? error.message : String(error),
        idCalculo: payload.id_calculo ?? payload.idCalculo ?? payload.id,
      });

      const analiseFallback = aplicarRastreabilidadeAnalise(
        buildFallbackLocal(payload),
        {
          sugestoesBase,
          modeloIAUtilizado: "fallback_local",
          fonte: "fallback_local",
        },
      );

      await salvarAnaliseNaSimulacao(payload, analiseFallback);

      return montarRespostaFunction(analiseFallback);
    }
  },
);

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
  const custoTotalEstimado = asNumber(
    rawAnalise.custo_total_estimado ??
    payload.custo_total_estimado ??
    payload.custoTotalEstimado ??
    payload.custo_estimado ??
    payload.custoEstimado,
  );

  const orcamentoDisponivel = nullableNumber(
    rawAnalise.orcamento_disponivel ?? payload.orcamento_disponivel ?? payload.orcamentoDisponivel,
  );

  const diferencaOrcamento = asNumber(
    rawAnalise.diferenca_orcamento,
    orcamentoDisponivel === null ? 0 : custoTotalEstimado - orcamentoDisponivel,
  );

  return {
    ...rawAnalise,
    titulo: asString(rawAnalise.titulo, "Análise inteligente da festa"),
    resumo: asString(rawAnalise.resumo, "Análise gerada com base na simulação da calculadora."),
    indice_economia: asNumber(rawAnalise.indice_economia, 50),
    indice_risco_faltar_itens: asNumber(rawAnalise.indice_risco_faltar_itens, 30),
    indice_conforto: asNumber(rawAnalise.indice_conforto, 70),
    custo_total_estimado: custoTotalEstimado,
    orcamento_disponivel: orcamentoDisponivel,
    diferenca_orcamento: diferencaOrcamento,
    data_analise: asString(rawAnalise.data_analise, new Date().toISOString()),
    sugestoes: Array.isArray(rawAnalise.sugestoes) ? rawAnalise.sugestoes : [],
    diagnostico_financeiro: asString(rawAnalise.diagnostico_financeiro),
    diagnostico_consumo: asString(rawAnalise.diagnostico_consumo),
    recomendacao_final: asString(rawAnalise.recomendacao_final),
    pontos_de_atencao: Array.isArray(rawAnalise.pontos_de_atencao) ? rawAnalise.pontos_de_atencao : [],
    proximas_acoes: Array.isArray(rawAnalise.proximas_acoes) ? rawAnalise.proximas_acoes : [],
  };
}

function buildFallbackLocal(payload: CalculadoraIARequest): Record<string, unknown> {
  const custoTotalEstimado = asNumber(
    payload.custo_total_estimado ?? payload.custoTotalEstimado ?? payload.custo_estimado ?? payload.custoEstimado,
  );
  const orcamentoDisponivel = nullableNumber(payload.orcamento_disponivel ?? payload.orcamentoDisponivel);
  const diferencaOrcamento = orcamentoDisponivel === null ? 0 : custoTotalEstimado - orcamentoDisponivel;
  const acimaDoOrcamento = orcamentoDisponivel !== null && diferencaOrcamento > 0;

  return {
    titulo: "Análise inteligente da festa",
    resumo: acimaDoOrcamento
      ? "A estimativa ficou acima do orçamento informado. Vale revisar itens de maior custo e priorizar o essencial."
      : "A simulação está coerente para o planejamento inicial. Revise quantidades e fornecedores antes de fechar os gastos.",
    indice_economia: acimaDoOrcamento ? 35 : 75,
    indice_risco_faltar_itens: 30,
    indice_conforto: acimaDoOrcamento ? 60 : 80,
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
    diagnostico_financeiro: acimaDoOrcamento
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

async function salvarAnaliseNaSimulacao(
  payload: CalculadoraIARequest,
  analise: AnaliseCalculadoraIAResponse,
): Promise<void> {
  const idCalculo = asString(payload.id_calculo ?? payload.idCalculo ?? payload.id);

  if (!idCalculo) {
    logger.info("Análise IA não persistida: id_calculo ausente no payload.");
    return;
  }

  await admin
    .firestore()
    .collection(COLLECTION_CALCULADORA_FESTA)
    .doc(idCalculo)
    .set(
      {
        analise_ia: analise,
        analise_ia_atualizada_em: admin.firestore.FieldValue.serverTimestamp(),
        data_atualizacao: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
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

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", ".").replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function nullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  return asNumber(value);
}
