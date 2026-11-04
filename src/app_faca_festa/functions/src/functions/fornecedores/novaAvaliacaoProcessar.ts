import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin } from "../../shared/firebaseAdmin";
import { usuarioPermiteAviso } from "../lgpd/preferenciasNotificacao";

function obterNumero(valor: unknown, fallback = 0): number {
    if (typeof valor === "number" && Number.isFinite(valor)) {
        return valor;
    }

    if (typeof valor === "string") {
        const normalizado = valor.replace(",", ".").trim();
        const numero = Number(normalizado);

        if (Number.isFinite(numero)) {
            return numero;
        }
    }

    return fallback;
}

/**
 * Compatibilidade com Dart-like extension não existe em TS.
 * Mantido separado para evitar repetição de trim.
 */
function textoNaoVazio(valor: unknown, fallback = ""): string {
    if (typeof valor !== "string") {
        return valor === null || valor === undefined ? fallback : String(valor);
    }

    const texto = valor.trim();
    return texto.length > 0 ? texto : fallback;
}

function extrairNota(data: FirebaseFirestore.DocumentData): number {
    return obterNumero(
        data.nota ??
        data.rating ??
        data.avaliacao ??
        data.estrelas ??
        data.qtd_estrelas ??
        0,
    );
}

async function enviarNotificacaoNovaAvaliacao(params: {
    idFornecedor: string;
    avaliacao: FirebaseFirestore.DocumentData;
}): Promise<void> {
    const { idFornecedor, avaliacao } = params;

    const db = admin.firestore();
    const fornecedorSnap = await db.collection("fornecedor").doc(idFornecedor).get();
    const fornecedorData = fornecedorSnap.data();

    if (!fornecedorData) {
        console.log("❌ Documento do fornecedor não encontrado.");
        return;
    }

    const fcmToken = fornecedorData.fcm_token ?? fornecedorData.fcmToken;

    if (!fcmToken || typeof fcmToken !== "string") {
        console.log("❌ Token inválido. Notificação não enviada.");
        return;
    }

    const permite = await usuarioPermiteAviso(db, idFornecedor, "avaliacoes");
    if (!permite) {
        console.log("Aviso de avaliação desligado pelo titular.");
        return;
    }

    const nomeCliente = textoNaoVazio(
        avaliacao.nome_cliente ?? avaliacao.nomeCliente,
        "Cliente",
    );

    const nota = extrairNota(avaliacao);

    const nomeEvento = textoNaoVazio(
        avaliacao.nome_evento ??
        avaliacao.nomeEvento ??
        avaliacao.evento ??
        "",
        "",
    );

    try {
        const response = await admin.messaging().send({
            token: fcmToken,
            notification: {
                title: "Nova avaliação recebida!",
                body: `${nomeCliente} deixou uma avaliação de ${nota} estrelas${nomeEvento ? ` no evento "${nomeEvento}"` : ""
                    }`,
            },
            data: {
                screen: "avaliacoes_fornecedor",
                id_fornecedor: idFornecedor,
                fornecedorId: idFornecedor,
            },
        });

        console.log("✅ Notificação enviada com sucesso:", response);
    } catch (err) {
        console.log("❌ Erro ao enviar notificação:", err);
    }
}



// Agregados são atualizados na mesma transação que a avaliação/moderação.
// Este trigger só invalida caches derivados; entrega repetida não altera reputação.
export const novaAvaliacaoProcessar = onDocumentWritten({
  document: "fornecedor/{idFornecedor}/avaliacoes/{idAvaliacao}", region: "us-central1",
}, async event => {
  const db = admin.firestore();
  for (const campo of ["fornecedorId", "idFornecedor", "id_fornecedor"]) {
    const docs = await db.collection("fornecedor_recomendacoes").where(campo,"==",event.params.idFornecedor).get();
    for (let i=0;i<docs.size;i+=400) {
      const batch=db.batch(); docs.docs.slice(i,i+400).forEach(d=>batch.delete(d.ref)); await batch.commit();
    }
  }
  const depois=event.data?.after.data();
  if (!event.data?.before.exists && depois?.schema === 2 && depois.verificada === true) {
    await enviarNotificacaoNovaAvaliacao({idFornecedor:event.params.idFornecedor,avaliacao:depois});
  }
});
