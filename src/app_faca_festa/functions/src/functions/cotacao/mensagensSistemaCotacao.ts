import { FieldValue, Firestore, Transaction } from "firebase-admin/firestore";

/**
 * Mensagens de sistema no chat mediado (Admin SDK — bypass rules).
 * Visíveis para organizador e fornecedor da conversa.
 */
export async function gravarMensagemSistema(
  db: Firestore,
  idCotacao: string,
  idFornecedor: string,
  mensagem: string,
): Promise<void> {
  const texto = String(mensagem ?? "").trim().slice(0, 2000);
  if (!texto || !idCotacao || !idFornecedor) return;

  await db
    .collection("cotacao")
    .doc(idCotacao)
    .collection("fornecedores")
    .doc(idFornecedor)
    .collection("mensagens")
    .add({
      id_usuario: "sistema",
      nome_usuario: "Faça a Festa",
      mensagem: texto,
      enviado_em: FieldValue.serverTimestamp(),
      lido: false,
      sistema: true,
    });
}

export async function gravarMensagemSistemaParaFornecedores(
  db: Firestore,
  idCotacao: string,
  idsFornecedor: string[],
  mensagem: string,
): Promise<void> {
  await Promise.all(
    idsFornecedor.map((id) => gravarMensagemSistema(db, idCotacao, id, mensagem)),
  );
}

/** Mesmo chat e schema; gravação atômica/idempotente junto da ação humana. */
export function gravarMensagemSistemaNaTransacao(tx:Transaction,fornecedorRef:FirebaseFirestore.DocumentReference,chave:string,mensagem:string):void {
 const texto=String(mensagem||"").trim().slice(0,2000);if(!texto)return;
 tx.set(fornecedorRef.collection("mensagens").doc(`jornada_${chave}`),{id_usuario:"sistema",nome_usuario:"Faça a Festa",mensagem:texto,enviado_em:FieldValue.serverTimestamp(),lido:false,sistema:true});
}
