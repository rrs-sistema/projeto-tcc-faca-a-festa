import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { admin } from "../../shared/firebaseAdmin";
import { registrarAuditTrailSeguro } from "../auditoria/auditTrailService";
import { cifrarTexto, decifrarTexto, gerarSecretTotp, montarOtpauthUrl, verificarTotp } from "../../shared/totp";
import {
  chaveMfa, codigoSeisDigitos, confirmarVerificacaoMfa, DadosMfa,
  exigirAutorizacaoMfa, exigirCadastroPermitido, exigirMetodoAtivo,
  lerPerfilMfa, obterSessaoMfa, OPCOES_MFA, referenciaPerfilMfa, temMetodo,
} from "./mfaSessao";

const ISSUER = "Faça a Festa";
const MAX_TENTATIVAS = 5;
const JANELA_TENTATIVAS_MS = 5 * 60 * 1000;
const VALIDADE_CADASTRO_MS = 10 * 60 * 1000;

export const iniciarTotpMfa = onCall<DadosMfa>(OPCOES_MFA, async (request) => {
  const sessao = await obterSessaoMfa(request);
  const { uid } = sessao;
  const chave = chaveMfa();
  const record = await admin.auth().getUser(uid);
  const email = (record.email ?? "").trim().toLowerCase();
  const { secret, criado } = await admin.firestore().runTransaction(async (tx) => {
    const perfil = await lerPerfilMfa(tx, uid);
    const ativo = temMetodo(perfil, "totp");
    if (ativo) {
      exigirAutorizacaoMfa(sessao, request.data?.autorizacao);
    } else {
      exigirCadastroPermitido(perfil, "totp", sessao, request.data?.autorizacao);
    }
    const referencia = ativo ? referenciaSubstituicao(uid) : referenciaTotp(uid);
    const atual = (await tx.get(referencia)).data();
    if (cadastroPendente(atual, sessao.autenticadaEm)) {
      return { secret: decifrarTexto(atual.secretCifrado, chave), criado: false };
    }
    const secret = gerarSecretTotp();
    tx.set(referencia, {
      uid,
      secretCifrado: cifrarTexto(secret, chave),
      pendente: true,
      ativo: false,
      tentativas: 0,
      cadastroAuthTime: sessao.autenticadaEm,
      cadastroExpiraEm: Timestamp.fromMillis(Date.now() + VALIDADE_CADASTRO_MS),
      atualizadoEm: FieldValue.serverTimestamp(),
    });
    return { secret, criado: true };
  });

  if (criado) await auditarTotp(uid, "MFA_TOTP_INICIADO", "configuracao_iniciada");
  return { ok: true, secret, otpauthUrl: montarOtpauthUrl({ secret, email, issuer: ISSUER }), issuer: ISSUER };
});

export const confirmarTotpMfa = onCall<DadosMfa>(OPCOES_MFA, (request) =>
  conferirTotp(request, true),
);

export const verificarTotpMfa = onCall<DadosMfa>(OPCOES_MFA, (request) =>
  conferirTotp(request, false),
);

async function conferirTotp(
  request: Parameters<typeof obterSessaoMfa>[0],
  cadastro: boolean,
) {
  const sessao = await obterSessaoMfa(request);
  const { uid } = sessao;
  const codigo = codigoSeisDigitos(request.data?.codigo);
  const perfilRef = referenciaPerfilMfa(uid);
  const referencia = referenciaTotp(uid);
  const valido = await admin.firestore().runTransaction(async (tx) => {
    const perfil = await lerPerfilMfa(tx, uid);
    const substituindo = cadastro && temMetodo(perfil, "totp");
    if (substituindo) {
      exigirAutorizacaoMfa(sessao, request.data?.autorizacao);
    } else if (cadastro) {
      exigirCadastroPermitido(perfil, "totp", sessao, request.data?.autorizacao);
    } else {
      exigirMetodoAtivo(perfil, "totp");
    }
    const origem = substituindo ? referenciaSubstituicao(uid) : referencia;
    const dados = (await tx.get(origem)).data();
    if (!dados?.secretCifrado ||
        (cadastro ? !cadastroPendente(dados, sessao.autenticadaEm) : !dados.ativo)) {
      throw new HttpsError("failed-precondition", "Configure o autenticador.");
    }
    const agora = Date.now();
    const limite = dados.tentativasAte as Timestamp | undefined;
    const tentativas = limite && limite.toMillis() > agora ? Number(dados.tentativas ?? 0) : 0;
    if (tentativas >= MAX_TENTATIVAS) {
      throw new HttpsError("resource-exhausted", "Muitas tentativas. Aguarde cinco minutos.");
    }
    if (!verificarTotp(decifrarTexto(dados.secretCifrado, chaveMfa()), codigo)) {
      tx.update(origem, {
        tentativas: tentativas + 1,
        tentativasAte: tentativas > 0 ? limite : Timestamp.fromMillis(agora + JANELA_TENTATIVAS_MS),
      });
      return false;
    }
    const agoraServidor = FieldValue.serverTimestamp();
    if (cadastro) {
      tx.set(referencia, {
        uid, secretCifrado: dados.secretCifrado, tentativas: 0, pendente: false,
        ativo: true, confirmadoEm: agoraServidor, atualizadoEm: agoraServidor,
      });
      if (substituindo) tx.delete(origem);
      tx.update(perfilRef, { mfa_totp_ativo: true, mfa_metodo: "totp" });
    } else {
      tx.update(referencia, {
        tentativas: 0, tentativasAte: FieldValue.delete(), verificadoEm: agoraServidor,
      });
    }
    return true;
  });
  if (!valido) throw new HttpsError("permission-denied", "Código incorreto.");
  await auditarTotp(uid, cadastro ? "MFA_TOTP_CONFIRMADO" : "MFA_TOTP_VERIFICADO",
    cadastro ? "configurado" : "verificado");
  return confirmarVerificacaoMfa(sessao);
}

function referenciaTotp(uid: string) {
  return admin.firestore().collection("mfa_totp").doc(uid);
}

function cadastroPendente(
  dados: FirebaseFirestore.DocumentData | undefined,
  autenticadaEm: number,
): dados is FirebaseFirestore.DocumentData {
  if (dados?.pendente !== true || typeof dados.secretCifrado !== "string") return false;
  const expiraEm = dados.cadastroExpiraEm as Timestamp | undefined;
  if (expiraEm) {
    return dados.cadastroAuthTime === autenticadaEm && expiraEm.toMillis() > Date.now();
  }
  // Cadastros iniciais que já estavam em andamento antes da atualização.
  const atualizadoEm = dados.atualizadoEm as Timestamp | undefined;
  return atualizadoEm != null && atualizadoEm.toMillis() + VALIDADE_CADASTRO_MS > Date.now();
}

function referenciaSubstituicao(uid: string) {
  return referenciaTotp(uid).collection("cadastros").doc("pendente");
}

function auditarTotp(uid: string, acao: string, status: string) {
  return registrarAuditTrailSeguro({
    acao,
    operacao: acao === "MFA_TOTP_INICIADO" ? "created" : "updated",
    entidadeTipo: "acesso",
    entidadeId: uid,
    actorUid: uid,
    actorAuthType: "unknown",
    documentPath: "mfa_totp/" + uid,
    after: { fluxo: "mfa_totp", status },
  });
}
