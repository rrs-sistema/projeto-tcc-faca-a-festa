import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { Messaging } from "firebase-admin/messaging";
import { admin } from "../../shared/firebaseAdmin";
import { permiteAviso } from "../lgpd/preferenciasNotificacao";

/** Destinatário sempre derivado da cotação, nunca de campos enviados pelo cliente. */
export async function enviarPushMensagemChat(
  db: FirebaseFirestore.Firestore,
  messaging: Pick<Messaging, "sendEachForMulticast">,
  ids: { idCotacao: string; idFornecedor: string; idMensagem: string },
): Promise<void> {
  const cotacaoRef = db.collection("cotacao").doc(ids.idCotacao);
  const fornecedorRef = cotacaoRef.collection("fornecedores").doc(ids.idFornecedor);
  const [cotacao, fornecedor, mensagem] = await Promise.all([
    cotacaoRef.get(), fornecedorRef.get(),
    fornecedorRef.collection("mensagens").doc(ids.idMensagem).get(),
  ]);
  const m = mensagem.data();
  const solicitante = cotacao.data()?.id_usuario_solicitante;
  if (!cotacao.exists || !fornecedor.exists || !m || m.sistema === true ||
      m.id_usuario === "sistema" || m.lido === true ||
      typeof solicitante !== "string" || !solicitante ||
      typeof m.mensagem !== "string" || !m.mensagem.trim()) return;
  if (m.id_usuario !== solicitante && m.id_usuario !== ids.idFornecedor) return;
  const destinatario = m.id_usuario === solicitante ? ids.idFornecedor : solicitante;
  if (destinatario === m.id_usuario) return;
  const usuarioRef = db.collection("usuarios").doc(destinatario);
  const usuario = await usuarioRef.get();
  if (!usuario.exists || usuario.data()?.ativo === false || !permiteAviso(usuario.data(), "chat")) return;
  const dispositivos = await usuarioRef.collection("dispositivos_push").get();
  const validos = dispositivos.docs.filter(d => typeof d.data().token === "string" && d.data().token.length > 0);
  for (let i = 0; i < validos.length; i += 500) {
    const lote = validos.slice(i, i + 500);
    const resposta = await messaging.sendEachForMulticast({
      tokens: lote.map(d => d.data().token),
      notification: {
        title: "Nova mensagem no chat",
        body: `${String(m.nome_usuario || "Participante").slice(0, 80)}: ${m.mensagem.trim().slice(0, 160)}`,
      },
      data: {
        screen: "chat_cotacao", id_cotacao: ids.idCotacao,
        id_fornecedor: ids.idFornecedor, id_mensagem: ids.idMensagem,
        id_destinatario: destinatario,
      },
      android: { priority: "high", notification: { channelId: "high_importance_channel", tag: ids.idMensagem } },
      apns: { payload: { aps: { sound: "default" } } },
      webpush: { notification: { tag: ids.idMensagem } },
    });
    await Promise.all(resposta.responses.map(async (r, index) => {
      if (r.error?.code === "messaging/registration-token-not-registered" ||
          r.error?.code === "messaging/invalid-registration-token") {
        await lote[index].ref.delete();
      } else if (!r.success) {
        // Sem tokens ou conteúdo pessoal nos logs.
        console.error("Falha ao entregar push do chat", { idMensagem: ids.idMensagem, codigo: r.error?.code });
      }
    }));
  }
}

export const notificarMensagemChat = onDocumentCreated({
  document: "cotacao/{idCotacao}/fornecedores/{idFornecedor}/mensagens/{idMensagem}",
  region: "us-central1",
}, async event => {
  await enviarPushMensagemChat(admin.firestore(), admin.messaging(), event.params);
});
