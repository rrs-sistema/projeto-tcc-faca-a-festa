import { createHash } from "crypto";

import { FieldValue } from "firebase-admin/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { admin } from "../../shared/firebaseAdmin";
import { calcularHashIntegridadeAuditoria } from "./auditIntegrity";
import { definirAcao } from "./catalogoAuditoria";

const REGION = "southamerica-east1";
const MAX_EMAIL = 180;
const MAX_CAMPO = 80;
const MAX_ROTA = 180;
const MAX_TENTATIVAS_POR_MINUTO = 8;

function texto(value: unknown): string {
  return String(value ?? "").trim();
}

function limitar(value: string, max: number): string {
  if (value.length <= max) return value;
  return value.slice(0, max);
}

function hash(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function mascararEmail(email: string): string {
  const [usuario, dominio] = email.toLowerCase().split("@");
  if (!usuario || !dominio) return "";
  const inicio = usuario.slice(0, 2);
  return `${inicio}${"*".repeat(Math.max(usuario.length - 2, 2))}@${dominio}`;
}

function ipDaRequisicao(request: CallableRequest): string {
  const forwarded = texto(request.rawRequest.headers["x-forwarded-for"]);
  if (forwarded) return forwarded.split(",")[0].trim();
  return texto(request.rawRequest.ip);
}

async function exigirRateLimit(chave: string): Promise<void> {
  const agora = new Date();
  const minuto = Math.floor(agora.getTime() / 60000);
  const ref = admin.firestore().collection("auditoria_rate_limits").doc(chave);

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const bucketAtual = data.bucket === minuto;
    const tentativas = bucketAtual ? Number(data.tentativas ?? 0) : 0;

    if (tentativas >= MAX_TENTATIVAS_POR_MINUTO) {
      throw new HttpsError(
        "resource-exhausted",
        "Muitas tentativas de login em pouco tempo.",
      );
    }

    tx.set(
      ref,
      {
        bucket: minuto,
        tentativas: tentativas + 1,
        atualizado_em: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

export const registrarFalhaLogin = onCall(
  {
    region: REGION,
    timeoutSeconds: 15,
    cors: true,
  },
  async (request) => {
    const data = (request.data ?? {}) as Record<string, unknown>;
    const email = limitar(texto(data.email).toLowerCase(), MAX_EMAIL);
    const metodo = limitar(texto(data.metodo) || "senha", MAX_CAMPO);
    const codigo = limitar(texto(data.codigo) || "unknown", MAX_CAMPO);
    const plataforma = limitar(texto(data.plataforma), MAX_CAMPO);
    const rota = limitar(texto(data.rota), MAX_ROTA);
    const ip = ipDaRequisicao(request);
    const emailHash = email ? hash(email) : null;
    const ipHash = ip ? hash(ip) : null;
    const rateKey = hash(`${emailHash ?? "sem-email"}:${ipHash ?? "sem-ip"}`);

    await exigirRateLimit(rateKey);

    const definicao = definirAcao("LOGIN_FALHOU");
    const ref = admin.firestore().collection("auditoria_eventos").doc();
    const payload: Record<string, unknown> = {
      acao: "LOGIN_FALHOU",
      area: definicao.area,
      nivel: definicao.nivel,
      resumo: "Tentativa de login recusada.",
      entidade_tipo: "sessao",
      entidade_nome: email ? mascararEmail(email) : undefined,
      ator_tipo: "S",
      detalhe: {
        metodo,
        codigo,
        email_hash: emailHash,
        email_mascarado: email ? mascararEmail(email) : null,
        ip_hash: ipHash,
      },
      visivel_fornecedor: false,
      plataforma: plataforma || undefined,
      rota: rota || undefined,
      origem: "callable_public",
      versao_schema: 1,
      algoritmo_hash: "sha256",
      criado_em: FieldValue.serverTimestamp(),
      criado_em_local: texto(data.criadoEmLocal) || new Date().toISOString(),
    };

    for (const key of Object.keys(payload)) {
      if (payload[key] === undefined || payload[key] === "") {
        delete payload[key];
      }
    }

    payload.hash_integridade = calcularHashIntegridadeAuditoria(payload);

    await ref.set(payload);

    logger.warn("auditoria.login_failed", {
      id: ref.id,
      metodo,
      codigo,
      emailHash,
      ipHash,
    });

    return { ok: true, id: ref.id };
  },
);
