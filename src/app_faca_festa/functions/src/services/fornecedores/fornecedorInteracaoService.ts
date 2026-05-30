import { admin } from "../../shared/firebaseAdmin";
import { RegistrarInteracaoFornecedorPayload } from "../../types/fornecedorRecomendacao.types";
import { calcularPesoInteracaoFornecedor } from "../../ia/fornecedores/recomendacao/pesos";

const COLLECTION_INTERACOES = "fornecedor_interacoes";
const ACOES_VALIDAS = new Set([
  "visualizou",
  "favoritou",
  "reservou",
  "pediu_orcamento",
  "contratou",
  "avaliou_bem",
  "dispensou",
  "ignorou",
]);

export async function registrarInteracaoFornecedorService(params: {
  uid: string;
  payload: RegistrarInteracaoFornecedorPayload;
}): Promise<{ success: true; peso: number }> {
  const { uid, payload } = params;

  const acao = String(payload.acao ?? "").trim();

  if (!ACOES_VALIDAS.has(acao)) {
    throw new Error(`Ação inválida para interação de fornecedor: ${acao}`);
  }

  const peso = calcularPesoInteracaoFornecedor(acao);
  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

  await admin.firestore().collection(COLLECTION_INTERACOES).add({
    usuarioId: uid,
    eventoId: payload.idEvento,
    fornecedorId: payload.idFornecedor,
    acao,
    peso,
    tipoEventoId: payload.tipoEventoId ?? null,
    tipoEventoNome: payload.tipoEventoNome ?? null,
    tipoEventoSlug: payload.tipoEventoSlug ?? null,
    cidade: payload.cidade ?? null,
    createdAt: serverTimestamp,

    // Compatibilidade com consultas/códigos antigos.
    id_usuario: uid,
    id_evento: payload.idEvento,
    id_fornecedor: payload.idFornecedor,
    tipo_evento_id: payload.tipoEventoId ?? null,
    tipo_evento_nome: payload.tipoEventoNome ?? null,
    tipo_evento_slug: payload.tipoEventoSlug ?? null,
    created_at: serverTimestamp,
  });

  return { success: true, peso };
}
