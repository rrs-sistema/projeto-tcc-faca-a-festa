import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { randomUUID } from "crypto";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import {
  exigirConfigurarPoliticaComissao,
  exigirLeituraExtratoComissao,
  exigirLiquidarComissao,
} from "../../services/financeiro/autorizacaoComissao";
import { dinheiro } from "../../services/financeiro/dinheiro";
import {
  PoliticaComissao,
  ObrigacaoComissao,
  ajustePorReducaoElegivel,
  aplicarAjuste,
  gerarObrigacao,
  liquidarManual,
  saldoCentavos,
  simular,
  validarPercentualBps,
} from "../../services/financeiro/comissaoPlataformaService";

const REGION = "southamerica-east1";
const COL_POLITICAS = "plataforma_comissao_politicas";
const COL_OBRIGACOES = "plataforma_comissao_obrigacoes";
const COL_LIQUIDACOES = "plataforma_comissao_liquidacoes";
const COL_AJUSTES = "plataforma_comissao_ajustes";
const COL_AUDITORIA = "plataforma_comissao_auditoria";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function inteiro(v: unknown, nome: string): number {
  if (typeof v !== "number" || !Number.isInteger(v)) {
    throw new HttpsError("invalid-argument", `Informe ${nome} inteiro.`);
  }
  return v;
}

function wrapErr(e: unknown): never {
  const err = e as { code?: string; message?: string };
  if (err?.code === "failed-precondition") {
    throw new HttpsError("failed-precondition", err.message || "Falha.");
  }
  if (err?.code === "invalid-argument") {
    throw new HttpsError("invalid-argument", err.message || "Argumento inválido.");
  }
  if (e instanceof HttpsError) throw e;
  throw new HttpsError("internal", err?.message || "Erro na comissão.");
}

async function auditar(
  autorId: string,
  acao: string,
  detalhes: Record<string, unknown>,
): Promise<void> {
  await admin.firestore().collection(COL_AUDITORIA).add({
    schema: 1,
    acao,
    autor_id: autorId,
    detalhes,
    criado_em: FieldValue.serverTimestamp(),
  });
}

function mapPolitica(id: string, data: FirebaseFirestore.DocumentData): PoliticaComissao {
  const bps = data.percentual_bps;
  return {
    id,
    versao: Number(data.versao ?? 1),
    percentualBps: typeof bps === "number" ? bps : null,
    baseElegivel: data.base_elegivel || "servicos_contratados_plataforma",
    pagador: data.pagador || "fornecedor",
    gatilho: data.gatilho_geracao || "contratacao_confirmada",
    reversao: data.reversao || "proporcional",
    ativa: data.ativa === true,
    completa: data.completa !== false && typeof bps === "number",
    diasVencimentoAposGeracao: Number(data.dias_vencimento_apos_geracao ?? 30),
  };
}

function mapObrigacao(
  id: string,
  data: FirebaseFirestore.DocumentData,
): ObrigacaoComissao {
  return {
    id,
    idEvento: String(data.id_evento ?? ""),
    idContrato: String(data.id_contrato ?? ""),
    baseElegivelCentavos: Number(data.base_elegivel?.centavos ?? 0),
    valorOriginalCentavos: Number(data.valor_original?.centavos ?? 0),
    valorAjustesCentavos: Number(data.valor_ajustes_centavos ?? 0),
    valorLiquidadoCentavos: Number(data.valor_liquidado?.centavos ?? 0),
    status: data.status || "gerada",
    politicaAplicada: (data.politica_aplicada as Record<string, unknown>) || {},
    idPagador: data.id_pagador ? String(data.id_pagador) : null,
    idFornecedor: data.id_fornecedor ? String(data.id_fornecedor) : null,
  };
}

function persistObrigacao(o: ObrigacaoComissao): Record<string, unknown> {
  return {
    schema: 1,
    id_obrigacao: o.id,
    id_evento: o.idEvento,
    id_contrato: o.idContrato,
    id_pagador: o.idPagador,
    id_fornecedor: o.idFornecedor,
    base_elegivel: dinheiro(o.baseElegivelCentavos),
    valor_original: dinheiro(o.valorOriginalCentavos),
    valor_ajustes_centavos: o.valorAjustesCentavos,
    valor_liquidado: dinheiro(Math.max(0, o.valorLiquidadoCentavos)),
    saldo_centavos: saldoCentavos(o),
    status: o.status,
    politica_aplicada: o.politicaAplicada,
    perspectiva: "plataforma_comissao",
    atualizado_em: FieldValue.serverTimestamp(),
  };
}

/** Novas políticas inativas por padrão. */
export const salvarPoliticaComissao = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirConfigurarPoliticaComissao(perfil);
    const data = (request.data ?? {}) as Record<string, unknown>;

    const percentualBps =
      data.percentualBps === null || data.percentual_bps === null
        ? null
        : inteiro(data.percentualBps ?? data.percentual_bps, "percentual_bps");
    if (percentualBps !== null) validarPercentualBps(percentualBps);

    const id = texto(data.idPolitica ?? data.id_politica) || randomUUID();
    const ref = admin.firestore().collection(COL_POLITICAS).doc(id);
    const existente = await ref.get();
    const versao = existente.exists
      ? Number(existente.data()?.versao ?? 1) + 1
      : 1;

    // Ativa só se explicitamente pedida; padrão inativa.
    const ativa = data.ativa === true;
    const completa = percentualBps !== null && data.completa !== false;

    await ref.set(
      {
        schema: 1,
        id_politica: id,
        versao,
        percentual_bps: percentualBps,
        base_elegivel:
          texto(data.baseElegivel ?? data.base_elegivel) ||
          "servicos_contratados_plataforma",
        pagador: texto(data.pagador) || "fornecedor",
        gatilho_geracao:
          texto(data.gatilhoGeracao ?? data.gatilho_geracao) ||
          "contratacao_confirmada",
        reversao: texto(data.reversao) || "proporcional",
        ativa,
        completa,
        vigencia_inicio: texto(data.vigenciaInicio ?? data.vigencia_inicio) || null,
        vigencia_fim: texto(data.vigenciaFim ?? data.vigencia_fim) || null,
        dias_vencimento_apos_geracao: inteiro(
          data.diasVencimentoAposGeracao ??
            data.dias_vencimento_apos_geracao ??
            30,
          "dias vencimento",
        ),
        observacoes_comerciais:
          texto(data.observacoesComerciais ?? data.observacoes_comerciais) ||
          "Decisões comerciais (pagador/exigibilidade) ainda pendentes de aprovação.",
        autor_id: perfil.uid,
        perspectiva: "plataforma",
        atualizado_em: FieldValue.serverTimestamp(),
        criado_em: existente.exists
          ? existente.data()?.criado_em ?? FieldValue.serverTimestamp()
          : FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await auditar(perfil.uid, "salvar_politica", {
      id_politica: id,
      versao,
      percentual_bps: percentualBps,
      ativa,
    });

    return { ok: true, idPolitica: id, versao, ativa };
  },
);

export const ativarPoliticaComissao = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirConfigurarPoliticaComissao(perfil);
    const id = texto(
      (request.data as Record<string, unknown>)?.idPolitica ??
        (request.data as Record<string, unknown>)?.id_politica,
    );
    if (!id) throw new HttpsError("invalid-argument", "Informe a política.");
    const ref = admin.firestore().collection(COL_POLITICAS).doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError("not-found", "Política não encontrada.");
    const p = mapPolitica(snap.id, snap.data()!);
    if (!p.completa || p.percentualBps === null) {
      throw new HttpsError(
        "failed-precondition",
        "Política incompleta não pode ser ativada.",
      );
    }
    // Desativa outras ativas (uma política ativa por vez — versão imutável nas obrigações).
    const ativas = await admin
      .firestore()
      .collection(COL_POLITICAS)
      .where("ativa", "==", true)
      .get();
    const batch = admin.firestore().batch();
    for (const d of ativas.docs) {
      if (d.id !== id) batch.update(d.ref, { ativa: false });
    }
    batch.update(ref, {
      ativa: true,
      atualizado_em: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await auditar(perfil.uid, "ativar_politica", { id_politica: id });
    return { ok: true, idPolitica: id };
  },
);

/** Simulação sintética — não altera financeiro. */
export const simularComissaoPlataforma = onCall(
  { region: REGION, timeoutSeconds: 30, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirConfigurarPoliticaComissao(perfil);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idPolitica = texto(data.idPolitica ?? data.id_politica);
    let politica: PoliticaComissao | null = null;
    if (idPolitica) {
      const snap = await admin.firestore().collection(COL_POLITICAS).doc(idPolitica).get();
      if (snap.exists) politica = mapPolitica(snap.id, snap.data()!);
    } else if (typeof data.percentualBps === "number" || typeof data.percentual_bps === "number") {
      const bps = inteiro(data.percentualBps ?? data.percentual_bps, "bps");
      politica = {
        id: "simulacao",
        versao: 0,
        percentualBps: bps,
        baseElegivel: "servicos_contratados_plataforma",
        pagador: "fornecedor",
        gatilho: "contratacao_confirmada",
        reversao: "proporcional",
        ativa: data.ativa === true,
        completa: true,
        diasVencimentoAposGeracao: 30,
      };
    }
    const base = inteiro(
      data.baseBrutaCentavos ?? data.base_bruta_centavos ?? 0,
      "base",
    );
    const resultado = simular({
      politica,
      baseBrutaCentavos: base,
      descontosCentavos: Number(data.descontosCentavos ?? data.descontos_centavos ?? 0),
      exclusoesCentavos: Number(data.exclusoesCentavos ?? data.exclusoes_centavos ?? 0),
    });
    return { ok: true, simulacao: true, ...resultado };
  },
);

export const gerarObrigacaoComissao = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    // Geração no gatilho: admin ou sistema via Admin SDK; callable exige A ou F dono se pagador.
    if (perfil.tipo !== "A" && perfil.tipo !== "F") {
      throw new HttpsError("permission-denied", "Sem permissão para gerar comissão.");
    }
    const data = (request.data ?? {}) as Record<string, unknown>;
    return gerarObrigacaoInterno(perfil.uid, data);
  },
);

async function gerarObrigacaoInterno(
  autorId: string,
  data: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const idEvento = texto(data.idEvento ?? data.id_evento);
  const idContrato = texto(data.idContrato ?? data.id_contrato);
  if (!idEvento || !idContrato) {
    throw new HttpsError("invalid-argument", "Informe evento e contrato.");
  }
  const base = inteiro(
    data.baseBrutaCentavos ?? data.base_bruta_centavos,
    "base contratada",
  );
  const chave =
    texto(data.chaveIdempotencia ?? data.chave_idempotencia) ||
    `comissao-${idContrato}`;

  const db = admin.firestore();
  const obrRef = db.collection(COL_OBRIGACOES).doc(chave);

  try {
    return await db.runTransaction(async (tx) => {
      const existente = await tx.get(obrRef);
      if (existente.exists) {
        const o = mapObrigacao(existente.id, existente.data()!);
        return {
          ok: true,
          idObrigacao: o.id,
          valorCentavos: o.valorOriginalCentavos,
          idempotente: true,
        };
      }

      const polSnap = await tx.get(
        db.collection(COL_POLITICAS).where("ativa", "==", true).limit(1),
      );
      if (polSnap.empty) {
        throw new HttpsError(
          "failed-precondition",
          "Política ausente/inativa — não gera dívida.",
        );
      }
      const politica = mapPolitica(polSnap.docs[0].id, polSnap.docs[0].data());
      const obr = gerarObrigacao({
        politica,
        idObrigacao: chave,
        idEvento,
        idContrato,
        baseBrutaCentavos: base,
        descontosCentavos: Number(data.descontosCentavos ?? data.descontos_centavos ?? 0),
        exclusoesCentavos: Number(data.exclusoesCentavos ?? data.exclusoes_centavos ?? 0),
        idPagador: texto(data.idPagador ?? data.id_pagador) || undefined,
        idFornecedor: texto(data.idFornecedor ?? data.id_fornecedor) || undefined,
      });

      const venc = new Date();
      venc.setDate(venc.getDate() + politica.diasVencimentoAposGeracao);

      tx.set(obrRef, {
        ...persistObrigacao(obr),
        status: "a_vencer",
        vencimento_em: venc.toISOString(),
        autor_id: autorId,
        registro_manual: false,
        criado_em: FieldValue.serverTimestamp(),
      });
      return {
        ok: true,
        idObrigacao: chave,
        valorCentavos: obr.valorOriginalCentavos,
        idempotente: false,
      };
    });
  } catch (e) {
    wrapErr(e);
  }
}

export const liquidarComissaoManual = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirLiquidarComissao(perfil);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idObrigacao = texto(data.idObrigacao ?? data.id_obrigacao);
    const valor = inteiro(data.valorCentavos ?? data.valor_centavos, "valor");
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) || randomUUID();

    const db = admin.firestore();
    try {
      const resultado = await db.runTransaction(async (tx) => {
        const liqRef = db.collection(COL_LIQUIDACOES).doc(chave);
        if ((await tx.get(liqRef)).exists) {
          return { ok: true, idempotente: true as const };
        }
        const obrRef = db.collection(COL_OBRIGACOES).doc(idObrigacao);
        const obrSnap = await tx.get(obrRef);
        if (!obrSnap.exists) {
          throw new HttpsError("not-found", "Obrigação não encontrada.");
        }
        const atual = mapObrigacao(obrSnap.id, obrSnap.data()!);
        const nova = liquidarManual(atual, valor);
        tx.update(
          obrRef,
          persistObrigacao(nova) as FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>,
        );
        tx.set(liqRef, {
          schema: 1,
          id_liquidacao: chave,
          id_obrigacao: idObrigacao,
          valor: dinheiro(valor),
          tipo: "manual",
          registro_manual: true,
          confirmacao_bancaria: false,
          autor_id: perfil.uid,
          motivo: texto(data.motivo) || null,
          perspectiva: "plataforma_comissao",
          criado_em: FieldValue.serverTimestamp(),
        });
        return {
          ok: true,
          saldoCentavos: saldoCentavos(nova),
          status: nova.status,
          registroManual: true,
          confirmacaoBancaria: false,
          idempotente: false as const,
        };
      });
      await auditar(perfil.uid, "liquidar_manual", {
        id_obrigacao: idObrigacao,
        valor,
      });
      return resultado;
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const registrarAjusteComissao = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirLiquidarComissao(perfil);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idObrigacao = texto(data.idObrigacao ?? data.id_obrigacao);
    const reducao = inteiro(
      data.reducaoBaseCentavos ?? data.reducao_base_centavos,
      "redução",
    );
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) || randomUUID();

    const db = admin.firestore();
    try {
      return await db.runTransaction(async (tx) => {
        const ajRef = db.collection(COL_AJUSTES).doc(chave);
        if ((await tx.get(ajRef)).exists) {
          return { ok: true, idempotente: true };
        }
        const obrRef = db.collection(COL_OBRIGACOES).doc(idObrigacao);
        const obrSnap = await tx.get(obrRef);
        if (!obrSnap.exists) {
          throw new HttpsError("not-found", "Obrigação não encontrada.");
        }
        const atual = mapObrigacao(obrSnap.id, obrSnap.data()!);
        const bps = Number(atual.politicaAplicada.percentual_bps ?? 0);
        const rev = (atual.politicaAplicada.reversao as "proporcional" | "nenhuma" | "manual") ||
          "proporcional";
        const ajuste = ajustePorReducaoElegivel(bps, reducao, rev);
        const nova = aplicarAjuste(atual, ajuste.ajusteCentavos);
        tx.update(obrRef, persistObrigacao(nova) as FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>);
        tx.set(ajRef, {
          schema: 1,
          id_ajuste: chave,
          id_obrigacao: idObrigacao,
          tipo: ajuste.tipo,
          reducao_base: dinheiro(reducao),
          ajuste_centavos: ajuste.ajusteCentavos,
          credito_reembolso_explicito: ajuste.creditoReembolsoExplicito,
          autor_id: perfil.uid,
          motivo: texto(data.motivo) || "redução elegível",
          criado_em: FieldValue.serverTimestamp(),
        });
        return {
          ok: true,
          ajusteCentavos: ajuste.ajusteCentavos,
          creditoReembolsoExplicito: ajuste.creditoReembolsoExplicito,
          saldoCentavos: saldoCentavos(nova),
        };
      });
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const consultarExtratoComissao = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const filtroPagador = texto(data.idPagador ?? data.id_pagador) || null;
    const acesso = exigirLeituraExtratoComissao(perfil, filtroPagador);

    let query: FirebaseFirestore.Query = admin.firestore().collection(COL_OBRIGACOES);
    if (acesso.modo === "pagador") {
      query = query.where("id_pagador", "==", acesso.idPagador);
    }
    const idEvento = texto(data.idEvento ?? data.id_evento);
    if (idEvento) query = query.where("id_evento", "==", idEvento);

    const snap = await query.limit(100).get();
    const politicas =
      acesso.modo === "admin"
        ? (await admin.firestore().collection(COL_POLITICAS).limit(20).get()).docs.map(
            (d) => ({ id: d.id, ...d.data() }),
          )
        : [];

    return {
      ok: true,
      modo: acesso.modo,
      obrigacoes: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
      politicas,
    };
  },
);

/** Helper interno para fecharCotacao — no-op se sem política ativa. */
export async function tentarGerarComissaoAposContratacao(params: {
  idEvento: string;
  idContrato: string;
  baseBrutaCentavos: number;
  idFornecedor?: string;
  idPagador?: string;
  autorId: string;
}): Promise<void> {
  try {
    await gerarObrigacaoInterno(params.autorId, {
      idEvento: params.idEvento,
      idContrato: params.idContrato,
      baseBrutaCentavos: params.baseBrutaCentavos,
      idFornecedor: params.idFornecedor,
      idPagador: params.idPagador ?? params.idFornecedor,
    });
  } catch {
    // Política ausente/inativa: não gera dívida nem quebra fechamento.
  }
}
