import { createHmac, randomBytes } from "crypto";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { registrarAuditTrailSeguro } from "../auditoria/auditTrailService";
import {
  chaveMfa, confirmarVerificacaoMfa, DadosMfa, exigirAutorizacaoMfa,
  lerPerfilMfa, obterSessaoMfa, OPCOES_MFA,
} from "./mfaSessao";

const TOTAL_CODIGOS = 8;
const MAX_TENTATIVAS = 5;
const JANELA_TENTATIVAS_MS = 5 * 60 * 1000;

export const gerarCodigosRecuperacaoMfa = onCall<DadosMfa>(OPCOES_MFA, async (request) => {
  const sessao = await obterSessaoMfa(request);
  exigirAutorizacaoMfa(sessao, request.data?.autorizacao);
  const { uid } = sessao;
  const codigos = Array.from({ length: TOTAL_CODIGOS }, () => randomBytes(16).toString("hex"));
  await admin.firestore().runTransaction(async (tx) => {
    await lerPerfilMfa(tx, uid);
    tx.set(referencia(uid), {
      hashes: codigos.map((codigo) => hash(uid, codigo)),
      tentativas: 0,
      atualizadoEm: FieldValue.serverTimestamp(),
    });
  });
  await auditarRecuperacao(uid, "MFA_RECUPERACAO_CODIGOS_GERADOS", "lista_gerada");
  return { codigos: codigos.map((codigo) => codigo.match(/.{4}/g)!.join("-").toUpperCase()) };
});

export const verificarCodigoRecuperacaoMfa = onCall<DadosMfa>(OPCOES_MFA, async (request) => {
  const sessao = await obterSessaoMfa(request);
  const { uid } = sessao;
  const entrada = request.data?.codigo;
  const codigo = typeof entrada === "string" ? entrada.trim().replace(/-/g, "").toLowerCase() : "";
  if (!/^[a-f0-9]{32}$/.test(codigo)) {
    throw new HttpsError("invalid-argument", "Informe um código de recuperação completo.");
  }
  const ref = referencia(uid);
  const codigoHash = hash(uid, codigo);
  const valido = await admin.firestore().runTransaction(async (tx) => {
    await lerPerfilMfa(tx, uid);
    const dados = (await tx.get(ref)).data();
    const hashes: string[] = dados?.hashes ?? [];
    if (!dados || hashes.length === 0) return false;
    const agora = Date.now();
    const limite = dados.tentativasAte as Timestamp | undefined;
    const tentativas = limite && limite.toMillis() > agora ? Number(dados.tentativas ?? 0) : 0;
    if (tentativas >= MAX_TENTATIVAS) {
      throw new HttpsError("resource-exhausted", "Muitas tentativas. Aguarde cinco minutos.");
    }
    const restantes = hashes.filter((hashSalvo) => hashSalvo !== codigoHash);
    if (restantes.length === hashes.length) {
      tx.update(ref, {
        tentativas: tentativas + 1,
        tentativasAte: tentativas > 0 ? limite : Timestamp.fromMillis(agora + JANELA_TENTATIVAS_MS),
      });
      return false;
    }
    tx.update(ref, {
      hashes: restantes, tentativas: 0, tentativasAte: FieldValue.delete(),
      atualizadoEm: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!valido) throw new HttpsError("permission-denied", "Código de recuperação inválido ou já usado.");
  await auditarRecuperacao(uid, "MFA_RECUPERACAO_CODIGO_USADO", "acesso_recuperado");
  return confirmarVerificacaoMfa(sessao);
});

function referencia(uid: string) {
  return admin.firestore().collection("mfa_recuperacao").doc(uid);
}

function hash(uid: string, codigo: string): string {
  return createHmac("sha256", chaveMfa()).update(JSON.stringify(["mfa-recuperacao", uid, codigo])).digest("hex");
}

function auditarRecuperacao(uid: string, acao: string, status: string) {
  return registrarAuditTrailSeguro({
    acao,
    operacao: "updated",
    entidadeTipo: "acesso",
    entidadeId: uid,
    actorUid: uid,
    actorAuthType: "unknown",
    documentPath: "mfa_recuperacao/" + uid,
    after: { status },
  });
}
