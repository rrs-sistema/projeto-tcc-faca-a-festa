import { onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { executarPlano, normalizarFonte } from "../../services/calculadora/executarPlanoService";
import { salvarRevisaoPosEvento } from "../../services/calculadora/revisaoPosEventoService";
export const aplicarPlanoCalculadora = onCall({
    region: "southamerica-east1", timeoutSeconds: 120, memory: "512MiB", cors: true,
}, async (request) => {
    const db = admin.firestore();
    const aplicado = await executarPlano(db, request.auth?.uid, request.data);
    const recibo = await db.doc(`calculadora_operacao/${request.data.evento}/aplicacoes/${request.data.pedido}`).get();
    return { aplicado, recibo: normalizarFonte(recibo.data()) };
});
export const revisarRefeicaoCalculadora = onCall({
    region: "southamerica-east1", timeoutSeconds: 60, cors: true,
}, request => salvarRevisaoPosEvento(admin.firestore(), request.auth?.uid, request.data));
