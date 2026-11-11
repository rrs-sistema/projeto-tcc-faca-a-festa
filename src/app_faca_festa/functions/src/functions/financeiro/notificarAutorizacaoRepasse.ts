import { FieldValue, Firestore } from "firebase-admin/firestore";
import type { Messaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin } from "../../shared/firebaseAdmin";
import { COL_AUDITORIA } from "../../services/financeiro/intermediacaoPersistenciaService";
import { COL_AUTORIZACOES } from "../../services/financeiro/liberacaoRepasseService";
import { registrarAuditTrail } from "../auditoria/auditTrailService";

const autorizou = "organizador_autorizou_repasse";
const revogou = "organizador_revogou_autorizacao";
const errosPermanentes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
  "messaging/mismatched-credential",
  "messaging/invalid-argument",
]);

export async function enviarPushAutorizacaoRepasse(
  db: Firestore,
  messaging: Pick<Messaging, "sendEachForMulticast">,
  idAuditoria: string,
): Promise<void> {
  const ref = db.collection(COL_AUDITORIA).doc(idAuditoria);
  const registro = await db.runTransaction(async tx => {
    const dados = (await tx.get(ref)).data();
    if (dados?.acao !== autorizou || !["pendente", "enviando"].includes(dados.push?.estado)) return;
    if (dados.push.estado === "enviando" && dados.push.lease_ate > Date.now()) {
      throw new Error("O envio do aviso de repasse já está em processamento.");
    }
    tx.update(ref, { "push.estado": "enviando", "push.lease_ate": Date.now() + 120_000 });
    return dados;
  });
  if (!registro) return;

  const finalizar = (estado: string) => ref.update({
    "push.estado": estado,
    "push.lease_ate": FieldValue.delete(),
    "push.concluido_em": FieldValue.serverTimestamp(),
  });

  try {
    const idFornecedor = registro.id_fornecedor;
    if (typeof idFornecedor !== "string" || !idFornecedor || idFornecedor.includes("/")) {
      await finalizar("sem_destinatario");
      return;
    }
    const usuarioRef = db.collection("usuarios").doc(idFornecedor);
    const autorizacaoRef = db.collection(COL_AUTORIZACOES).doc(registro.id_orcamento);
    const [usuario, autorizacao, orcamento] = await Promise.all([
      usuarioRef.get(), autorizacaoRef.get(), db.collection("orcamento").doc(registro.id_orcamento).get(),
    ]);
    if (autorizacao.data()?.ativa !== true || autorizacao.data()?.id_auditoria_push !== idAuditoria ||
        orcamento.data()?.id_fornecedor !== idFornecedor) {
      await finalizar("superado");
      return;
    }
    if (usuario.data()?.tipo !== "F" || usuario.data()?.ativo === false) {
      await finalizar("sem_destinatario");
      return;
    }

    const dispositivos = await usuarioRef.collection("dispositivos_push").get();
    const processados = new Set<string>(registro.push.processados ?? []);
    const validos = dispositivos.docs.filter(d =>
      !processados.has(d.id) && typeof d.data().token === "string" && d.data().token.length > 0);
    let enviados = Number(registro.push.enviados ?? 0);
    let falhas = Number(registro.push.falhas ?? 0);
    let reenviar = false;
    for (let i = 0; i < validos.length; i += 500) {
      const lote = validos.slice(i, i + 500);
      const resposta = await messaging.sendEachForMulticast({
        tokens: lote.map(d => d.data().token),
        notification: {
          title: "Autorização de pagamento antecipado",
          body: "O organizador registrou a autorização. A plataforma ainda vai conferir as condições para o pagamento.",
        },
        data: {
          screen: "autorizacao_repasse",
          id_destinatario: idFornecedor,
          id_orcamento: registro.id_orcamento,
        },
        android: { notification: { channelId: "high_importance_channel", tag: idAuditoria } },
        apns: { headers: { "apns-collapse-id": idAuditoria }, payload: { aps: { sound: "default" } } },
        webpush: { notification: { tag: idAuditoria } },
      });
      const concluidos: string[] = [];
      resposta.responses.forEach((r, index) => {
        if (r.success || errosPermanentes.has(r.error?.code ?? "")) {
          concluidos.push(lote[index].id);
          if (r.success) enviados++;
          else falhas++;
        } else {
          reenviar = true;
        }
      });
      if (concluidos.length > 0) {
        await ref.update({
          "push.processados": FieldValue.arrayUnion(...concluidos),
          "push.enviados": enviados,
          "push.falhas": falhas,
        });
      }
    }
    if (reenviar) throw new Error("O envio do aviso de repasse teve falhas temporárias.");
    await finalizar(enviados > 0 ? (falhas > 0 ? "parcial" : "enviado") : (falhas > 0 ? "falhou" : "sem_dispositivos"));
  } catch (error) {
    await ref.update({ "push.estado": "pendente", "push.lease_ate": FieldValue.delete() });
    // O provedor pode incluir dados de entrega no erro original.
    throw new Error("Falha temporária ao processar o aviso de repasse.");
  }
}

export const notificarAutorizacaoRepasse = onDocumentCreated({
  document: `${COL_AUDITORIA}/{idAuditoria}`,
  region: "us-central1",
  timeoutSeconds: 60,
  retry: true,
}, async event => {
  const registro = event.data?.data();
  if (registro?.acao !== autorizou && registro?.acao !== revogou) return;
  await registrarAuditTrail({
    acao: registro.acao === autorizou ? "REPASSE_ANTECIPADO_AUTORIZADO" : "REPASSE_ANTECIPADO_REVOGADO",
    operacao: "created",
    entidadeTipo: registro.acao === autorizou ? "Autorização de repasse antecipado" : "Revogação de repasse antecipado",
    entidadeId: registro.id_orcamento,
    actorUid: registro.autor_id,
    idFornecedor: registro.id_fornecedor,
    idEvento: registro.id_evento,
    idOrcamento: registro.id_orcamento,
    after: { ativa: registro.ativa, ativa_anterior: registro.ativa_anterior, id_contrato: registro.id_contrato },
    documentPath: event.data?.ref.path,
    sourceEventId: event.id,
  });
  if (registro.push?.estado === "pendente") {
    await enviarPushAutorizacaoRepasse(admin.firestore(), admin.messaging(), event.params.idAuditoria);
  }
});
