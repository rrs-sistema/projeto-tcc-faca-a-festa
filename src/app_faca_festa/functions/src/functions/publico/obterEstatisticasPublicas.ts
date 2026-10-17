import { onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";

type Estatisticas = {
  totalEventos: number;
  totalAvaliacoes: number;
  mediaFornecedores: number | null;
};

let cache: { expiraEm: number; dados: Estatisticas } | undefined;

export function resumirAvaliacoes(
  fornecedores: FirebaseFirestore.DocumentData[],
): Pick<Estatisticas, "totalAvaliacoes" | "mediaFornecedores"> {
  let soma = 0;
  let totalAvaliacoes = 0;
  for (const data of fornecedores) {
    const media = Number(data.media_avaliacoes ?? data.mediaAvaliacoes);
    const total = Number(data.total_avaliacoes ?? data.totalAvaliacoes);
    if (!Number.isFinite(media) || media < 1 || media > 5 ||
        !Number.isSafeInteger(total) || total <= 0) continue;
    soma += media * total;
    totalAvaliacoes += total;
  }
  return {
    totalAvaliacoes,
    mediaFornecedores: totalAvaliacoes > 0 ? soma / totalAvaliacoes : null,
  };
}

// Retorna somente agregados; os documentos de eventos e fornecedores
// continuam sujeitos às permissões existentes.
export const obterEstatisticasPublicas = onCall(
  { region: "southamerica-east1" },
  async (): Promise<Estatisticas> => {
    if (cache && cache.expiraEm > Date.now()) return cache.dados;

    const db = admin.firestore();
    const [eventos, fornecedores] = await Promise.all([
      db.collection("evento").count().get(),
      db.collection("fornecedor")
        .select("media_avaliacoes", "mediaAvaliacoes", "total_avaliacoes", "totalAvaliacoes")
        .get(),
    ]);

    const dados: Estatisticas = {
      totalEventos: eventos.data().count,
      ...resumirAvaliacoes(fornecedores.docs.map((doc) => doc.data())),
    };
    cache = { expiraEm: Date.now() + 5 * 60 * 1000, dados };
    return dados;
  },
);
