import { Firestore } from "firebase-admin/firestore";

export async function carregarMapaDocs(
  db: Firestore,
  colecao: string,
  ids: Set<string>,
): Promise<Map<string, Record<string, unknown>>> {
  const mapa = new Map<string, Record<string, unknown>>();
  const lista = [...ids].filter(Boolean);
  for (let i = 0; i < lista.length; i += 100) {
    const refs = lista.slice(i, i + 100).map(id => db.collection(colecao).doc(id));
    const docs = await db.getAll(...refs);
    for (const doc of docs) {
      if (doc.exists) mapa.set(doc.id, doc.data() ?? {});
    }
  }
  return mapa;
}
