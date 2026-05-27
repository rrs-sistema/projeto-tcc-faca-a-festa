import OpenAI from "openai";
import { defineSecret } from "firebase-functions/params";

import {
  CalculadoraIARequest,
  AnaliseCalculadoraIAResponse,
} from "./types";

import {
  analiseCalculadoraIASchema,
  ANALISE_CALCULADORA_IA_SCHEMA_VERSION,
} from "./schema";

import { buildInstructions, buildInput } from "./prompt";
import { normalizeAIResponse } from "./validators";

export const openaiApiKey = defineSecret("OPENAI_API_KEY");

const OPENAI_MODEL = "gpt-4.1-mini";

export async function runOpenAIAnalysis(
  request: CalculadoraIARequest,
): Promise<AnaliseCalculadoraIAResponse> {
  const client = new OpenAI({
    apiKey: openaiApiKey.value(),
  });

  const response = await client.responses.create({
    model: OPENAI_MODEL,
    instructions: buildInstructions(),
    input: buildInput(request),
    text: {
      format: {
        type: "json_schema",
        name: "analise_calculadora_festa",
        strict: true,
        schema: analiseCalculadoraIASchema,
      },
    } as any,
  });

  const outputText = response.output_text;

  if (!outputText || outputText.trim() === '') {
    throw new Error("A IA não retornou conteúdo textual para análise.");
  }

  const parsed = JSON.parse(outputText) as Partial<AnaliseCalculadoraIAResponse>;

  parsed.fonte = "ia_generativa";
  parsed.versao_schema = ANALISE_CALCULADORA_IA_SCHEMA_VERSION;

  return normalizeAIResponse(parsed, request, "ia_generativa");
}