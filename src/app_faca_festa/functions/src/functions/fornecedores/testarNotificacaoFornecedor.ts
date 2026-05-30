import { onRequest } from "firebase-functions/v1/https";
import { admin } from "../../shared/firebaseAdmin";

// 🔥 Teste manual de envio de notificação
export const testarNotificacaoFornecedor = onRequest(async (req, res) => {
  try {
    const token = req.query.token as string | undefined;

    if (!token) {
      res.status(400).send("❌ Informe o token na URL: ?token=SEU_TOKEN_AQUI");
      return;
    }

    console.log("📌 Token recebido:", token);

    const response = await admin.messaging().send({
      token,
      notification: {
        title: "🔔 Teste de Notificação",
        body: "Notificação enviada manualmente via função HTTP!",
      },
      data: {
        screen: "avaliacoes_fornecedor",
        teste: "true",
      },
    });

    console.log("✅ Notificação enviada com sucesso:", response);

    res.status(200).send("✅ Notificação enviada! Response: " + response);
  } catch (error) {
    console.error("❌ Erro no envio da notificação:", error);
    res.status(500).send("Erro ao enviar notificação: " + error);
  }
});
