import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin } from "../../shared/firebaseAdmin";

type AvaliacaoResumo = {
    total: number;
    soma: number;
    media: number;
};

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

function obterSelos(media: number, total: number): string[] {
    const selos: string[] = [];

    if (media >= 4.8 && total >= 8) {
        selos.push("Fornecedor 5 Estrelas");
    }

    if (media >= 4.5 && total >= 5) {
        selos.push("Premium");
    }

    if (media >= 4.0 && total >= 3) {
        selos.push("Muito Recomendado");
    }

    return selos;
}

async function calcularResumoAvaliacoes(
    idFornecedor: string,
): Promise<AvaliacaoResumo> {
    const db = admin.firestore();

    const snapAvaliacoes = await db
        .collection("fornecedor")
        .doc(idFornecedor)
        .collection("avaliacoes")
        .get();

    let soma = 0;
    let total = 0;

    for (const doc of snapAvaliacoes.docs) {
        const data = doc.data();
        const nota = extrairNota(data);

        if (!Number.isFinite(nota) || nota < 0 || nota > 5) {
            continue;
        }

        soma += nota;
        total += 1;
    }

    const media = total > 0 ? Number((soma / total).toFixed(2)) : 0;

    return {
        total,
        soma,
        media,
    };
}

async function atualizarResumoFornecedor(
    idFornecedor: string,
    resumo: AvaliacaoResumo,
): Promise<void> {
    const db = admin.firestore();
    const selos = obterSelos(resumo.media, resumo.total);

    await db
        .collection("fornecedor")
        .doc(idFornecedor)
        .set(
            {
                // Novo padrão usado pelo Flutter/IA
                mediaAvaliacoes: resumo.media,
                totalAvaliacoes: resumo.total,

                // Compatibilidade com dados antigos
                media_avaliacoes: resumo.media,
                total_avaliacoes: resumo.total,

                selos,
                avaliacoesAtualizadasEm: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
        );

    console.log("✅ Resumo do fornecedor atualizado:", {
        idFornecedor,
        media: resumo.media,
        total: resumo.total,
        selos,
    });
}

async function limparRecomendacoesDoFornecedor(
    idFornecedor: string,
): Promise<number> {
    const db = admin.firestore();
    const refs = new Map<string, FirebaseFirestore.DocumentReference>();

    const consultas = await Promise.all([
        db
            .collection("fornecedor_recomendacoes")
            .where("fornecedorId", "==", idFornecedor)
            .limit(500)
            .get(),
        db
            .collection("fornecedor_recomendacoes")
            .where("idFornecedor", "==", idFornecedor)
            .limit(500)
            .get(),
        db
            .collection("fornecedor_recomendacoes")
            .where("id_fornecedor", "==", idFornecedor)
            .limit(500)
            .get(),
    ]);

    for (const snap of consultas) {
        for (const doc of snap.docs) {
            refs.set(doc.ref.path, doc.ref);
        }
    }

    const refsParaExcluir = Array.from(refs.values());

    if (refsParaExcluir.length === 0) {
        return 0;
    }

    for (let i = 0; i < refsParaExcluir.length; i += 450) {
        const batch = db.batch();
        const lote = refsParaExcluir.slice(i, i + 450);

        for (const ref of lote) {
            batch.delete(ref);
        }

        await batch.commit();
    }

    console.log("🧹 Recomendações antigas removidas:", {
        idFornecedor,
        totalRemovido: refsParaExcluir.length,
    });

    return refsParaExcluir.length;
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

export const novaAvaliacaoProcessar = onDocumentWritten(
    {
        document: "fornecedor/{idFornecedor}/avaliacoes/{idAvaliacao}",
        region: "us-central1",
        timeoutSeconds: 60,
        memory: "256MiB",
    },
    async (event) => {
        const idFornecedor = event.params.idFornecedor;
        const idAvaliacao = event.params.idAvaliacao;

        const beforeExists = event.data?.before.exists ?? false;
        const afterExists = event.data?.after.exists ?? false;
        const avaliacaoDepois = event.data?.after.data();

        const operacao = !beforeExists && afterExists
            ? "created"
            : beforeExists && afterExists
                ? "updated"
                : beforeExists && !afterExists
                    ? "deleted"
                    : "unknown";

        console.log("🔥 [START] novaAvaliacaoProcessar disparou", {
            idFornecedor,
            idAvaliacao,
            operacao,
        });

        const resumo = await calcularResumoAvaliacoes(idFornecedor);

        console.log("📊 Resumo calculado:", {
            idFornecedor,
            total: resumo.total,
            soma: resumo.soma,
            media: resumo.media,
        });

        await atualizarResumoFornecedor(idFornecedor, resumo);

        const totalCacheRemovido = await limparRecomendacoesDoFornecedor(idFornecedor);

        console.log("🧠 Cache de recomendação invalidado:", {
            idFornecedor,
            totalCacheRemovido,
        });

        if (operacao === "created" && avaliacaoDepois) {
            await enviarNotificacaoNovaAvaliacao({
                idFornecedor,
                avaliacao: avaliacaoDepois,
            });
        } else {
            console.log(
                "ℹ️ Notificação não enviada porque a operação não é criação de avaliação.",
            );
        }

        console.log("🔥 [END] Processamento concluído.");
    },
);
