import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin } from "../shared/firebaseAdmin";

export const novaAvaliacaoProcessar = onDocumentCreated(
    "fornecedor/{idFornecedor}/avaliacoes/{idAvaliacao}",
    async (event) => {
        const data = event.data?.data();
        const idFornecedor = event.params.idFornecedor;

        console.log("🔥 [START] novaAvaliacaoProcessar disparou");
        console.log("📌 ID Fornecedor:", idFornecedor);
        console.log("📌 Dados da avaliação recebidos:", data);

        if (!data) {
            console.log("❌ Nenhum dado encontrado no documento.");
            return;
        }

        const nomeCliente = data.nome_cliente ?? "Cliente";
        const nota = Number(data.nota ?? 0);

        const evento =
            data.nome_evento ??
            data.evento ??
            data.nomeEvento ??
            "";

        console.log("📌 Nome Evento lido:", evento);

        const db = admin.firestore();

        console.log("\n=== 📊 CALCULANDO MÉDIA DO FORNECEDOR ===");

        const snapAvaliacoes = await db
            .collection("fornecedor")
            .doc(idFornecedor)
            .collection("avaliacoes")
            .get();

        const total = snapAvaliacoes.size;

        const somaNotas = snapAvaliacoes.docs.reduce(
            (acc: number, doc: { get: (arg0: string) => any; }) => acc + (Number(doc.get("nota")) || 0),
            0,
        );

        const media = total > 0 ? somaNotas / total : 0;

        console.log("📌 Total avaliações:", total);
        console.log("📌 Soma notas:", somaNotas);
        console.log("📌 Nova média:", media);

        await db.collection("fornecedor").doc(idFornecedor).update({
            media_avaliacoes: media,
            total_avaliacoes: total,
        });

        console.log("\n=== 🏅 CALCULANDO SELOS ===");

        const selos: string[] = [];

        if (media >= 4.8 && total >= 8) selos.push("Fornecedor 5 Estrelas");
        if (media >= 4.5 && total >= 5) selos.push("Premium");
        if (media >= 4.0 && total >= 3) selos.push("Muito Recomendado");

        console.log("📌 Selos definidos:", selos);

        await db.collection("fornecedor").doc(idFornecedor).set(
            {
                selos,
            },
            { merge: true },
        );

        console.log("📌 Selos aplicados com sucesso:", selos);

        console.log("\n=== 📄 CARREGANDO DADOS DO FORNECEDOR ===");

        const fornecedorSnap = await db.collection("fornecedor").doc(idFornecedor).get();
        const fornecedorData = fornecedorSnap.data();

        console.log("📌 Dados do fornecedor:", fornecedorData);

        if (!fornecedorData) {
            console.log("❌ Documento do fornecedor não encontrado.");
            return;
        }

        const fcmToken = fornecedorData.fcm_token;

        console.log("📌 FCM Token encontrado:", fcmToken);

        console.log("\n=== 📣 ENVIANDO NOTIFICAÇÃO ===");

        if (!fcmToken || typeof fcmToken !== "string") {
            console.log("❌ Token inválido. Notificação não enviada.");
            return;
        }

        try {
            const response = await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: "Nova avaliação recebida!",
                    body: `${nomeCliente} deixou uma avaliação de ${nota} estrelas${evento ? ` no evento "${evento}"` : ""
                        }`,
                },
                data: {
                    screen: "avaliacoes_fornecedor",
                    id_fornecedor: idFornecedor,
                },
            });

            console.log("✅ Notificação enviada com sucesso:", response);
        } catch (err) {
            console.log("❌ Erro ao enviar notificação:", err);
        }

        console.log("\n🔥 [END] Processamento concluído.");
    },
);
