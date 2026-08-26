import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { definirAcao } from "./catalogoAuditoria";

const REGION = "southamerica-east1";
const MAX_RESUMO = 400;
const MAX_CAMPO = 80;
const MAX_ID = 120;
const MAX_MUDANCAS = 20;
const MAX_DETALHE = 8000;

type MudancaEntrada = {
  campo?: unknown;
  de?: unknown;
  para?: unknown;
};

function texto(value: unknown): string {
  return String(value ?? "").trim();
}

function limitar(value: string, max: number): string {
  if (value.length <= max) return value;
  return `${value.slice(0, max)}…`;
}

function valorSeguro(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "string") return limitar(value.trim(), 180);
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  try {
    return limitar(JSON.stringify(value), 180);
  } catch {
    return "";
  }
}

function normalizarMudancas(raw: unknown): Array<{ campo: string; de: string; para: string }> {
  if (!Array.isArray(raw)) return [];
  const mudancas: Array<{ campo: string; de: string; para: string }> = [];
  for (const item of raw.slice(0, MAX_MUDANCAS)) {
    const entrada = (item ?? {}) as MudancaEntrada;
    const campo = limitar(texto(entrada.campo), 80);
    if (!campo) continue;
    mudancas.push({
      campo,
      de: valorSeguro(entrada.de),
      para: valorSeguro(entrada.para),
    });
  }
  return mudancas;
}

function sanitizarDetalhe(raw: unknown): Record<string, unknown> | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  try {
    const encoded = JSON.stringify(raw);
    if (encoded.length > MAX_DETALHE) {
      return { resumo: "Detalhe truncado no servidor." };
    }
    return JSON.parse(encoded) as Record<string, unknown>;
  } catch {
    return { resumo: "Detalhe inválido." };
  }
}

/**
 * Registro privilegiado e imutável de auditoria da plataforma.
 * O cliente nunca grava em `auditoria_eventos`; só esta callable
 * (e outras functions internas) podem criar documentos.
 */
export const registrarAuditoria = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A", "F", "O"]);
    const data = (request.data ?? {}) as Record<string, unknown>;

    const acao = limitar(texto(data.acao) || "EVENTO_GENERICO", MAX_CAMPO);
    const definicao = definirAcao(acao);

    if (definicao.somenteAdmin) {
      exigirTipo(perfil, ["A"]);
    }

    const resumo = limitar(texto(data.resumo) || "Alteração registrada.", MAX_RESUMO);
    const idFornecedorInformado = limitar(texto(data.idFornecedor), MAX_ID);

    if (perfil.tipo === "F") {
      if (!definicao.visivelFornecedor) {
        throw new HttpsError(
          "permission-denied",
          "Você não pode registrar este tipo de evento.",
        );
      }
      if (idFornecedorInformado && idFornecedorInformado !== perfil.uid) {
        throw new HttpsError(
          "permission-denied",
          "A auditoria do fornecedor só pode ser da própria conta.",
        );
      }
    }

    const usuarioSnap = await admin
      .firestore()
      .collection("usuarios")
      .doc(perfil.uid)
      .get();
    const usuario = usuarioSnap.data() ?? {};

    const idFornecedor =
      perfil.tipo === "F" ? perfil.uid : idFornecedorInformado || null;

    const payload: Record<string, unknown> = {
      acao,
      area: definicao.area,
      nivel: definicao.nivel,
      resumo,
      entidade_tipo: limitar(texto(data.entidadeTipo), MAX_CAMPO) || null,
      entidade_id: limitar(texto(data.entidadeId), MAX_ID) || null,
      entidade_nome: limitar(texto(data.entidadeNome), 180) || null,
      id_fornecedor: idFornecedor,
      id_evento: limitar(texto(data.idEvento), MAX_ID) || null,
      id_servico: limitar(texto(data.idServico), MAX_ID) || null,
      id_cotacao: limitar(texto(data.idCotacao), MAX_ID) || null,
      id_orcamento: limitar(texto(data.idOrcamento), MAX_ID) || null,
      ator_uid: perfil.uid,
      ator_nome:
        limitar(texto(usuario.nome), 120) ||
        limitar(texto(request.auth?.token?.name), 120) ||
        null,
      ator_email:
        limitar(texto(request.auth?.token?.email), 180) ||
        limitar(texto(usuario.email), 180) ||
        null,
      ator_tipo: perfil.tipo,
      mudancas: normalizarMudancas(data.mudancas),
      detalhe: sanitizarDetalhe(data.detalhe),
      visivel_fornecedor: Boolean(definicao.visivelFornecedor && idFornecedor),
      plataforma: limitar(texto(data.plataforma), 40) || null,
      rota: limitar(texto(data.rota), 180) || null,
      origem: "callable",
      versao_schema: 1,
      criado_em: FieldValue.serverTimestamp(),
      criado_em_local: texto(data.criadoEmLocal) || new Date().toISOString(),
    };

    for (const key of Object.keys(payload)) {
      if (payload[key] === null || payload[key] === "") {
        delete payload[key];
      }
    }

    if (Array.isArray(payload.mudancas) && payload.mudancas.length === 0) {
      delete payload.mudancas;
    }

    const ref = admin.firestore().collection("auditoria_eventos").doc();
    await ref.set(payload);

    logger.info("auditoria.registrada", {
      id: ref.id,
      acao,
      area: definicao.area,
      atorTipo: perfil.tipo,
      idFornecedor: payload.id_fornecedor ?? null,
    });

    return { ok: true, id: ref.id };
  },
);
