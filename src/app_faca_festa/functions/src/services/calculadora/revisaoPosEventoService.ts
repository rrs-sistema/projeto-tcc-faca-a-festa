import { Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

export async function salvarRevisaoPosEvento(db: Firestore, uid: string | undefined, raw: any) {
  if (!uid) throw new HttpsError("unauthenticated", "Entre na sua conta.");
  const { evento, acao } = raw ?? {};
  if (typeof evento !== "string" || !evento || evento.includes("/") ||
      typeof acao?.id_cardapio !== "string" || !acao.id_cardapio || acao.id_cardapio.includes("/") ||
      typeof acao.itens !== "object" || acao.itens == null || Array.isArray(acao.itens)) {
    throw new HttpsError("invalid-argument", "Revisão inválida.");
  }
  return db.runTransaction(async tx => {
    const ev = await tx.get(db.doc(`evento/${evento}`));
    if (ev.data()?.id_usuario !== uid) throw new HttpsError("permission-denied", "Somente o organizador pode revisar.");
    const data = ev.data()!, fim = data.data_fim ?? data.data;
    if (!(fim instanceof Timestamp) || fim.toMillis() > Date.now() || ["cancelado", "adiado"].includes(data.status)) {
      throw new HttpsError("failed-precondition", "Registre os resultados após a realização da festa.");
    }
    const ref = db.doc(`calculadora_operacao/${evento}`), op = await tx.get(ref);
    if (op.data()?.versao != null && op.data()?.versao !== 1) throw new HttpsError("failed-precondition", "Atualize o leitor antes de alterar esta operação.");
    if ((op.data()?.revisao ?? 0) !== acao.revisao) throw new HttpsError("failed-precondition", "O planejamento mudou. Reabra a revisão.");
    const menu = await tx.get(db.doc(`cardapios/${acao.id_cardapio}`));
    if (menu.data()?.id_evento !== evento || menu.data()?.ativo === false) throw new HttpsError("failed-precondition", "A refeição mudou.");
    const items = await tx.get(menu.ref.collection("itens").limit(61));
    const ids = new Set(items.docs.map(d => d.id)), avaliados = Object.keys(acao.itens);
    const validos = ["adequado", "sobrou", "faltou", "nao_servido", "nao_sei"];
    if (items.size > 60 || avaliados.some(k => !ids.has(k) || !validos.includes(acao.itens[k])) ||
        (acao.concluir === true && (!ids.size || avaliados.length !== ids.size))) {
      throw new HttpsError("failed-precondition", "Confira os resultados de cada item do cardápio atual.");
    }
    const review = { versao: 1, status: acao.concluir === true ? "concluida" : "em_revisao",
      itens: acao.itens, natureza: "qualitativa", registrado_em: new Date().toISOString() };
    const resultado = { ...op.data(), id_evento: evento, id_usuario: uid, versao: 1,
      revisao: (op.data()?.revisao ?? 0) + 1,
      revisao_pos_evento: { ...(op.data()?.revisao_pos_evento ?? {}), [acao.id_cardapio]: review } };
    tx.set(ref, resultado);
    return resultado;
  });
}
