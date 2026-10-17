import { HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";

/** Limite compartilhado entre instâncias, antes de consumir a API externa. */
export async function limitarAnaliseCalculadora(uid: string): Promise<void> {
  const db = admin.firestore();
  const ref = db.collection("calculadora_ia_limites").doc(uid);
  const agora = Date.now();
  await db.runTransaction(async (tx) => {
    const anterior = (await tx.get(ref)).data() ?? {};
    const inicio = typeof anterior.inicio === "number" ? anterior.inicio : agora;
    const renovar = agora - inicio >= 300000;
    const chamadas = renovar ? 0 : Number(anterior.chamadas ?? 0);
    const ultima = Number(anterior.ultima ?? 0);
    if (agora - ultima < 1000 || chamadas >= 60) {
      throw new HttpsError("resource-exhausted", "Aguarde um momento antes de pedir outra análise. Os cálculos continuam disponíveis.");
    }
    tx.set(ref, { inicio: renovar ? agora : inicio, chamadas: chamadas + 1, ultima: agora });
  });
}
