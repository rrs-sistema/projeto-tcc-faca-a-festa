import { admin } from "./shared/firebaseAdmin";
import { CalculadoraIARequest, AnaliseCalculadoraIAResponse } from "./types";

const COLLECTION_CALCULADORA = "calculadora_festa";
const SUBCOLLECTION_ANALISES = "analises_ia";

export async function saveAnalysisIfPossible(
  request: CalculadoraIARequest,
  analysis: AnaliseCalculadoraIAResponse,
): Promise<void> {
  if (!request.id_calculo) return;

  const db = admin.firestore();
  const calcRef = db.collection(COLLECTION_CALCULADORA).doc(request.id_calculo);

  await calcRef.set({
    analise_ia_generativa: analysis,
    data_ultima_analise_ia: admin.firestore.FieldValue.serverTimestamp(),
    fonte_ultima_analise_ia: analysis.fonte,
    versao_schema_ia: analysis.versao_schema,
  }, { merge: true });

  if ((process.env.AI_SAVE_HISTORY ?? "true") !== "false") {
    await calcRef.collection(SUBCOLLECTION_ANALISES).add({
      ...analysis,
      id_calculo: request.id_calculo,
      id_evento: request.id_evento ?? null,
      id_usuario: request.id_usuario ?? null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}
