import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado, exigirTipo } from "../../shared/auth";
import {
  alocarRecebimentoAContratos,
  confirmarRepasseManual,
  consultarExtratoIntermediacao,
  prepararOuAutorizarRepasse,
  registrarAjustePosRepasse,
  registrarRecebimentoPlataforma,
  COL_LIBERACAO,
} from "../../services/financeiro/intermediacaoPersistenciaService";
import {
  calcularDireitosContrato,
  montarPosicaoContrato,
  PoliticaLiberacaoRepasse,
} from "../../services/financeiro/intermediacaoFinanceiraService";
import { FieldValue } from "firebase-admin/firestore";

const REGION = "southamerica-east1";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function inteiro(v: unknown, nome: string): number {
  if (typeof v !== "number" || !Number.isInteger(v)) {
    throw new HttpsError("invalid-argument", `Informe ${nome} inteiro.`);
  }
  return v;
}

async function exigirAdmin(uid: string | undefined) {
  const perfil = await exigirUsuarioAutenticado(uid);
  exigirTipo(perfil, ["A"]);
  return perfil;
}

/** Registra recebimento do cliente pela plataforma (manual/conferência). */
export const registrarRecebimentoPlataformaFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    return registrarRecebimentoPlataforma(admin.firestore(), {
      idEvento: texto(data.idEvento ?? data.id_evento),
      idPagador: texto(data.idPagador ?? data.id_pagador) || null,
      valorCentavos: inteiro(
        data.valorCentavos ?? data.valor_centavos,
        "valorCentavos",
      ),
      nivelConfirmacao: (texto(data.nivelConfirmacao ?? data.nivel_confirmacao) ||
        "conferencia") as "declaracao" | "conferencia" | "fonte_externa",
      referencia: texto(data.referencia) || null,
      origem: texto(data.origem) || "registro_manual",
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
      autorId: perfil.uid,
    });
  },
);

/** Alocação manual explícita — sem rateio silencioso. */
export const alocarRecebimentoContratosFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const raw = data.alocacoes;
    if (!Array.isArray(raw) || raw.length === 0) {
      throw new HttpsError("invalid-argument", "Informe alocações explícitas.");
    }
    const alocacoes = raw.map((item) => {
      const m = item as Record<string, unknown>;
      return {
        idContrato: texto(m.idContrato ?? m.id_contrato),
        idOrcamento: texto(m.idOrcamento ?? m.id_orcamento),
        idFornecedor: texto(m.idFornecedor ?? m.id_fornecedor) || null,
        valorCentavos: inteiro(
          m.valorCentavos ?? m.valor_centavos,
          "valorCentavos",
        ),
      };
    });
    return alocarRecebimentoAContratos(admin.firestore(), {
      idRecebimento: texto(data.idRecebimento ?? data.id_recebimento),
      alocacoes,
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
      autorId: perfil.uid,
    });
  },
);

/** Prepara repasse; sem política ativa permanece elegivel_pendente. */
export const prepararRepasseFornecedorFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    return prepararOuAutorizarRepasse(admin.firestore(), {
      idContrato: texto(data.idContrato ?? data.id_contrato),
      idOrcamento: texto(data.idOrcamento ?? data.id_orcamento),
      idFornecedor: texto(data.idFornecedor ?? data.id_fornecedor),
      valorCentavos: inteiro(
        data.valorCentavos ?? data.valor_centavos,
        "valorCentavos",
      ),
      percentualBps: inteiro(
        data.percentualBps ?? data.percentual_bps,
        "percentualBps",
      ),
      modoComissao:
        texto(data.modoComissao ?? data.modo_comissao) === "adicionada_cliente"
          ? "adicionada_cliente"
          : "descontada_fornecedor",
      valorContratadoCentavos: inteiro(
        data.valorContratadoCentavos ?? data.valor_contratado_centavos,
        "valorContratadoCentavos",
      ),
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
      autorId: perfil.uid,
      forcarAutorizacaoSeElegivel: data.autorizarSeElegivel === true,
    });
  },
);

/** Confirmação manual de repasse (conferência) — não é transferência bancária. */
export const confirmarRepasseManualFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    return confirmarRepasseManual(admin.firestore(), {
      idRepasse: texto(data.idRepasse ?? data.id_repasse),
      autorId: perfil.uid,
      evidencias: texto(data.evidencias) || null,
    });
  },
);

export const registrarAjustePosRepasseFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    return registrarAjustePosRepasse(admin.firestore(), {
      idEvento: texto(data.idEvento ?? data.id_evento),
      idRepasse: texto(data.idRepasse ?? data.id_repasse),
      valorChargebackCentavos: inteiro(
        data.valorChargebackCentavos ?? data.valor_chargeback_centavos,
        "valorChargebackCentavos",
      ),
      autorId: perfil.uid,
      motivo: texto(data.motivo) || "Chargeback/reembolso após repasse",
    });
  },
);

export const consultarExtratoIntermediacaoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    if (!idEvento) {
      throw new HttpsError("invalid-argument", "Informe idEvento.");
    }
    return consultarExtratoIntermediacao(admin.firestore(), idEvento);
  },
);

/**
 * Política de liberação — inativa por padrão.
 * Sem ativação, nenhum repasse é elegível automaticamente.
 */
export const salvarPoliticaLiberacaoRepasseFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const id = texto(data.idPolitica ?? data.id_politica);
    const ativa = data.ativa === true;
    const permite = data.permiteRepasseParcial === true;
    const teto =
      typeof data.tetoParcialCentavos === "number"
        ? inteiro(data.tetoParcialCentavos, "tetoParcialCentavos")
        : typeof data.teto_parcial_centavos === "number"
          ? inteiro(data.teto_parcial_centavos, "teto_parcial_centavos")
          : null;

    const db = admin.firestore();
    const ref = id
      ? db.collection(COL_LIBERACAO).doc(id)
      : db.collection(COL_LIBERACAO).doc();

    if (ativa) {
      const outras = await db
        .collection(COL_LIBERACAO)
        .where("ativa", "==", true)
        .limit(10)
        .get();
      const batch = db.batch();
      for (const doc of outras.docs) {
        if (doc.id !== ref.id) batch.update(doc.ref, { ativa: false });
      }
      await batch.commit();
    }

    const payload = {
      schema: 1,
      id_politica: ref.id,
      versao: Number(data.versao ?? 1),
      ativa,
      // Default: inativa e sem liberação automática.
      permite_repasse_parcial: permite,
      teto_parcial_centavos: teto,
      atualizado_em: FieldValue.serverTimestamp(),
      atualizado_por: perfil.uid,
    };
    await ref.set(payload, { merge: true });
    return { ok: true, id: ref.id, ...payload };
  },
);

/** Simulação local de posição (não persiste). */
export const simularPosicaoIntermediacaoFn = onCall(
  { region: REGION, timeoutSeconds: 30, cors: true },
  async (request) => {
    await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const valorContrato = inteiro(
      data.valorContratadoCentavos ?? data.valor_contratado_centavos,
      "valorContratadoCentavos",
    );
    const bps = inteiro(data.percentualBps ?? data.percentual_bps ?? 500, "bps");
    const modo =
      texto(data.modoComissao) === "adicionada_cliente"
        ? "adicionada_cliente"
        : "descontada_fornecedor";
    const direitos = calcularDireitosContrato({
      valorContratadoCentavos: valorContrato,
      percentualBps: bps,
      modoComissao: modo,
    });
    const politicaRaw = data.politica as Record<string, unknown> | undefined;
    let politica: PoliticaLiberacaoRepasse | null = null;
    if (politicaRaw && politicaRaw.ativa === true) {
      politica = {
        id: "sim",
        versao: 1,
        ativa: true,
        permiteRepasseParcial: politicaRaw.permiteRepasseParcial === true,
        tetoParcialCentavos:
          typeof politicaRaw.tetoParcialCentavos === "number"
            ? politicaRaw.tetoParcialCentavos
            : null,
      };
    }
    const pos = montarPosicaoContrato({
      idContrato: texto(data.idContrato) || "sim",
      valorContratadoCentavos: valorContrato,
      percentualBps: bps,
      modoComissao: modo,
      alocadoCentavos: Number(data.alocadoCentavos ?? 0),
      repassadoConfirmadoCentavos: Number(data.repassadoConfirmadoCentavos ?? 0),
      autorizadoOuProcessandoCentavos: Number(
        data.autorizadoOuProcessandoCentavos ?? 0,
      ),
      recebimentosPedidoCentavos: Number(data.recebimentosPedidoCentavos ?? 0),
      alocadoPedidoCentavos: Number(data.alocadoPedidoCentavos ?? 0),
      politica,
    });
    return {
      ok: true,
      simulacao: true,
      direitos,
      posicao: pos,
      aviso: "Simulação — não altera recebimento, alocação nem repasse.",
    };
  },
);
