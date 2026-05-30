import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

type TipoEventoFornecedor = {
    tipoEventoIds: string[];
    tipoEventoSlugs: string[];
    tipoEventoNomes: string[];
};

type ResultadoAtualizacao = {
    fornecedorId: string;
    nomeEsperado: string;
    documentId?: string;
    encontrado: boolean;
    atualizado: boolean;
    jaPossuiaTipos: boolean;
    tipoEventoNomes: string[];
    mensagem: string;
};

const fornecedoresTiposEvento: Record<string, TipoEventoFornecedor & { nome: string }> = {
    "4vB9Cu4gybhaAJWEZ28jiiJcS5S2": {
        nome: "Almi Mãos de Tesoura",
        tipoEventoIds: [
            "302191a2-dbf3-4ac6-ba53-08273b384cab",
            "WlLdfdmu4Chvw2p8daUm",
            "7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda",
        ],
        tipoEventoSlugs: [
            "casamento",
            "formatura",
            "aniversario",
        ],
        tipoEventoNomes: [
            "Casamento",
            "Formatura",
            "Aniversário",
        ],
    },

    "7JGfA120ZqXMJx0tJgh3zSz2Ewq1": {
        nome: "Fornecedor Transp LTDA",
        tipoEventoIds: [
            "302191a2-dbf3-4ac6-ba53-08273b384cab",
            "WlLdfdmu4Chvw2p8daUm",
            "lXf0M5vMNvyRn52yQ2fY",
        ],
        tipoEventoSlugs: [
            "casamento",
            "formatura",
            "evento_corporativo",
        ],
        tipoEventoNomes: [
            "Casamento",
            "Formatura",
            "Evento Corporativo",
        ],
    },
};

function possuiTiposEvento(data: FirebaseFirestore.DocumentData): boolean {
    const camel = data.tipoEventoIds;
    const snake = data.tipo_evento_ids;

    return (Array.isArray(camel) && camel.length > 0) ||
        (Array.isArray(snake) && snake.length > 0);
}

async function buscarFornecedorPorId(
    fornecedorId: string,
): Promise<FirebaseFirestore.QueryDocumentSnapshot | FirebaseFirestore.DocumentSnapshot | null> {
    const db = getFirestore();

    const docDireto = await db.collection("fornecedor").doc(fornecedorId).get();

    if (docDireto.exists) {
        return docDireto;
    }

    const camposPossiveis = [
        "idFornecedor",
        "id_fornecedor",
        "fornecedorId",
        "uid",
        "idUsuario",
        "id_usuario",
    ];

    for (const campo of camposPossiveis) {
        const query = await db
            .collection("fornecedor")
            .where(campo, "==", fornecedorId)
            .limit(1)
            .get();

        if (!query.empty) {
            return query.docs[0];
        }
    }

    return null;
}

async function limparCacheRecomendacoes(): Promise<number> {
    const db = getFirestore();

    const snapshot = await db
        .collection("fornecedor_recomendacoes")
        .limit(500)
        .get();

    if (snapshot.empty) {
        return 0;
    }

    const batch = db.batch();

    for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
    }

    await batch.commit();

    return snapshot.size;
}

export const atualizarFornecedoresTiposEventoManual = onCall(
    {
        region: "southamerica-east1",
        timeoutSeconds: 120,
        memory: "512MiB",
    },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError(
                "unauthenticated",
                "Usuário não autenticado.",
            );
        }

        const dryRun = Boolean(request.data?.dryRun ?? true);
        const aplicar = Boolean(request.data?.aplicar ?? false);
        const sobrescrever = Boolean(request.data?.sobrescrever ?? true);
        const limparCache = Boolean(request.data?.limparCache ?? false);

        if (!dryRun && !aplicar) {
            throw new HttpsError(
                "failed-precondition",
                "Para atualizar de verdade, envie aplicar=true.",
            );
        }

        const db = getFirestore();
        const resultados: ResultadoAtualizacao[] = [];

        let totalEncontrados = 0;
        let totalAtualizados = 0;
        let totalIgnorados = 0;
        let totalNaoEncontrados = 0;

        const batch = db.batch();

        for (const [fornecedorId, dados] of Object.entries(fornecedoresTiposEvento)) {
            const fornecedorDoc = await buscarFornecedorPorId(fornecedorId);

            if (!fornecedorDoc || !fornecedorDoc.exists) {
                totalNaoEncontrados += 1;

                resultados.push({
                    fornecedorId,
                    nomeEsperado: dados.nome,
                    encontrado: false,
                    atualizado: false,
                    jaPossuiaTipos: false,
                    tipoEventoNomes: dados.tipoEventoNomes,
                    mensagem: "Fornecedor não encontrado na coleção fornecedor.",
                });

                continue;
            }

            totalEncontrados += 1;

            const fornecedorData = fornecedorDoc.data() ?? {};
            const jaPossuiaTipos = possuiTiposEvento(fornecedorData);

            if (jaPossuiaTipos && !sobrescrever) {
                totalIgnorados += 1;

                resultados.push({
                    fornecedorId,
                    nomeEsperado: dados.nome,
                    documentId: fornecedorDoc.id,
                    encontrado: true,
                    atualizado: false,
                    jaPossuiaTipos: true,
                    tipoEventoNomes: dados.tipoEventoNomes,
                    mensagem: "Fornecedor já possuía tipos de evento e sobrescrever=false.",
                });

                continue;
            }

            if (!dryRun) {
                batch.set(
                    fornecedorDoc.ref,
                    {
                        tipoEventoIds: dados.tipoEventoIds,
                        tipoEventoSlugs: dados.tipoEventoSlugs,
                        tipoEventoNomes: dados.tipoEventoNomes,

                        tipo_evento_ids: dados.tipoEventoIds,
                        tipo_evento_slugs: dados.tipoEventoSlugs,
                        tipo_evento_nomes: dados.tipoEventoNomes,

                        classificacaoTipoEventoOrigem: "manual_pontual_tcc",
                        classificacaoTipoEventoAtualizadoEm: FieldValue.serverTimestamp(),
                        updatedAt: FieldValue.serverTimestamp(),
                    },
                    { merge: true },
                );
            }

            totalAtualizados += 1;

            resultados.push({
                fornecedorId,
                nomeEsperado: dados.nome,
                documentId: fornecedorDoc.id,
                encontrado: true,
                atualizado: !dryRun,
                jaPossuiaTipos,
                tipoEventoNomes: dados.tipoEventoNomes,
                mensagem: dryRun
                    ? "Simulação: fornecedor seria atualizado."
                    : "Fornecedor atualizado com sucesso.",
            });
        }

        if (!dryRun && totalAtualizados > 0) {
            await batch.commit();
        }

        let totalCacheRemovido = 0;

        if (!dryRun && limparCache) {
            totalCacheRemovido = await limparCacheRecomendacoes();
        }

        return {
            dryRun,
            aplicar,
            sobrescrever,
            limparCache,
            totalMapeados: Object.keys(fornecedoresTiposEvento).length,
            totalEncontrados,
            totalAtualizados,
            totalIgnorados,
            totalNaoEncontrados,
            totalCacheRemovido,
            resultados,
        };
    },
);