import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { resolverExecucaoAposMediacao } from "../../services/financeiro/resolucaoMediacaoService";

export const resolverExecucaoMediacao = onCall(
  { region: "southamerica-east1", timeoutSeconds: 60, cors: true },
  async request => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);
    const d = request.data ?? {};
    if (typeof d.idCaso !== "string" || !d.idCaso.trim()) throw new HttpsError("invalid-argument", "Informe a mediação.");
    return resolverExecucaoAposMediacao(admin.firestore(), {
      idCaso: d.idCaso.trim(), autorId: perfil.uid,
      estadoExecucao: typeof d.estadoExecucao === "string" ? d.estadoExecucao : "",
      motivo: typeof d.motivo === "string" ? d.motivo : "",
      retirarBloqueio: d.retirarBloqueio === true,
    });
  },
);
