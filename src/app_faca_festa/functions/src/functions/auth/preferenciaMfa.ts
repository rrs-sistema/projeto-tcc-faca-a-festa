import { HttpsError, onCall } from "firebase-functions/v2/https";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigeMfaNoLogin, sessaoMfaVerificada } from "../../shared/politicaMfa";
import {
  DadosMfa, exigirAutorizacaoMfa, lerPerfilMfa, obterSessaoMfa,
  OPCOES_MFA, referenciaPerfilMfa, temMetodo,
} from "./mfaSessao";
import { admin } from "../../shared/firebaseAdmin";
import { registrarAuditTrailSeguro } from "../auditoria/auditTrailService";

export const consultarSessaoMfa = onCall(
  { region: "southamerica-east1", cors: true },
  async (request) => {
    await exigirUsuarioAutenticado(request.auth?.uid);
    return { verificada: await sessaoMfaVerificada(request.auth) };
  },
);

export const definirMfaOpcional = onCall<DadosMfa & { ativar?: unknown }>(
  OPCOES_MFA, async (request) => {
    const sessao = await obterSessaoMfa(request);
    exigirAutorizacaoMfa(sessao, request.data?.autorizacao);
    if (typeof request.data?.ativar !== "boolean") {
      throw new HttpsError("invalid-argument", "Informe a preferência de proteção.");
    }
    const ativar = request.data.ativar;
    await admin.firestore().runTransaction(async (tx) => {
      const perfil = await lerPerfilMfa(tx, sessao.uid);
      if (exigeMfaNoLogin({ tipo: perfil.tipo }) || !["O", "C"].includes(perfil.tipo)) {
        throw new HttpsError("permission-denied", "A proteção é obrigatória para este perfil.");
      }
      if (ativar && !temMetodo(perfil, "email") && !temMetodo(perfil, "totp")) {
        throw new HttpsError("failed-precondition", "Cadastre um método de verificação.");
      }
      tx.update(referenciaPerfilMfa(sessao.uid), { mfa_login_opcional: ativar });
    });
    await registrarAuditTrailSeguro({
      acao: "MFA_PREFERENCIA_ALTERADA", operacao: "updated", entidadeTipo: "acesso",
      entidadeId: sessao.uid, actorUid: sessao.uid, actorAuthType: "unknown",
      documentPath: "usuarios/" + sessao.uid,
      after: { status: ativar ? "protecao_ativada" : "protecao_desativada" },
    });
    return { ok: true };
  },
);
