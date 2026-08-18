import { onRequest } from "firebase-functions/v1/https";

export const testarNotificacaoFornecedor = onRequest(async (_req, res) => {
  res.status(403).send("Endpoint de teste desativado.");
});
