import { FieldValue, Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { dinheiro } from "./dinheiro";
import { centavosDeOrcamento } from "./dashboardAdminService";
import {
  CriterioAlocacao,
  EstadoRepasse,
  NivelConfirmacaoRecebimento,
  PoliticaLiberacaoRepasse,
  avaliarElegibilidadeRepasse,
  calcularDireitosContrato,
  disponivelParaAlocar,
  transicionarRepasse,
  validarAlocacoesRecebimento,
} from "./intermediacaoFinanceiraService";

export const COL_RECEBIMENTOS = "plataforma_recebimentos";
export const COL_ALOCACOES = "plataforma_alocacoes";
export const COL_REPASSES = "plataforma_repasses";
export const COL_LIBERACAO = "plataforma_liberacao_repasses";
export const COL_AJUSTES = "plataforma_intermediacao_ajustes";
export const COL_AUDITORIA = "plataforma_intermediacao_auditoria";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

async function auditar(
  db: Firestore,
  autorId: string,
  acao: string,
  detalhes: Record<string, unknown>,
): Promise<void> {
  await db.collection(COL_AUDITORIA).add({
    schema: 1,
    acao,
    autor_id: autorId,
    detalhes,
    criado_em: FieldValue.serverTimestamp(),
  });
}

export async function registrarRecebimentoPlataforma(
  db: Firestore,
  entrada: {
    idEvento: string;
    idPagador?: string | null;
    valorCentavos: number;
    nivelConfirmacao?: NivelConfirmacaoRecebimento;
    referencia?: string | null;
    origem?: string;
    chaveIdempotencia: string;
    autorId: string;
  },
): Promise<{ id: string; idempotente: boolean }> {
  const chave = texto(entrada.chaveIdempotencia);
  if (!chave || chave.length > 128) {
    throw new HttpsError("invalid-argument", "Chave de idempotência inválida.");
  }
  const idEvento = texto(entrada.idEvento);
  if (!idEvento) {
    throw new HttpsError("invalid-argument", "Informe o evento/pedido.");
  }
  dinheiro(entrada.valorCentavos);

  const idemRef = db
    .collection(COL_RECEBIMENTOS)
    .doc(`idem_${chave}`);
  // Usamos doc dedicado de idempotência no mesmo path lógico via campo.
  const existente = await db
    .collection(COL_RECEBIMENTOS)
    .where("chave_idempotencia", "==", chave)
    .limit(1)
    .get();
  if (!existente.empty) {
    return { id: existente.docs[0].id, idempotente: true };
  }

  const ref = db.collection(COL_RECEBIMENTOS).doc();
  await ref.set({
    schema: 1,
    id_recebimento: ref.id,
    id_evento: idEvento,
    id_pagador: texto(entrada.idPagador) || null,
    valor: dinheiro(entrada.valorCentavos),
    valor_centavos: entrada.valorCentavos,
    nivel_confirmacao: entrada.nivelConfirmacao ?? "conferencia",
    referencia: texto(entrada.referencia) || null,
    origem: texto(entrada.origem) || "registro_manual",
    origem_legado_pago: false,
    alocado_centavos: 0,
    chave_idempotencia: chave,
    operador_id: entrada.autorId,
    criado_em: FieldValue.serverTimestamp(),
  });
  // evita lint unused
  void idemRef;
  await auditar(db, entrada.autorId, "registrar_recebimento", {
    id_recebimento: ref.id,
    id_evento: idEvento,
    valor_centavos: entrada.valorCentavos,
  });
  return { id: ref.id, idempotente: false };
}

export async function alocarRecebimentoAContratos(
  db: Firestore,
  entrada: {
    idRecebimento: string;
    alocacoes: Array<{
      idContrato: string;
      idOrcamento: string;
      idFornecedor?: string | null;
      valorCentavos: number;
    }>;
    chaveIdempotencia: string;
    autorId: string;
    criterio?: CriterioAlocacao;
  },
): Promise<{ ids: string[]; idempotente: boolean }> {
  const chave = texto(entrada.chaveIdempotencia);
  if (!chave) {
    throw new HttpsError("invalid-argument", "Chave de idempotência inválida.");
  }
  const prev = await db
    .collection(COL_ALOCACOES)
    .where("chave_idempotencia", "==", chave)
    .limit(20)
    .get();
  if (!prev.empty) {
    return { ids: prev.docs.map((d) => d.id), idempotente: true };
  }

  return db.runTransaction(async (tx) => {
    const recRef = db.collection(COL_RECEBIMENTOS).doc(entrada.idRecebimento);
    const recSnap = await tx.get(recRef);
    if (!recSnap.exists) {
      throw new HttpsError("not-found", "Recebimento não encontrado.");
    }
    const rec = recSnap.data() ?? {};
    const valor = Number(rec.valor_centavos ?? 0);
    const alocado = Number(rec.alocado_centavos ?? 0);
    const recebimento = {
      id: recSnap.id,
      idEvento: String(rec.id_evento ?? ""),
      idPagador: rec.id_pagador ? String(rec.id_pagador) : null,
      valorCentavos: valor,
      nivelConfirmacao: (rec.nivel_confirmacao ??
        "conferencia") as NivelConfirmacaoRecebimento,
      alocadoCentavos: alocado,
      referencia: rec.referencia ? String(rec.referencia) : null,
      origem: String(rec.origem ?? "registro_manual"),
      origemLegadoPago: rec.origem_legado_pago === true,
    };

    const validacao = validarAlocacoesRecebimento({
      recebimento,
      alocacoesNovas: entrada.alocacoes.map((a) => ({
        idContrato: a.idContrato,
        valorCentavos: a.valorCentavos,
      })),
    });
    if (!validacao.ok) {
      throw new HttpsError("failed-precondition", validacao.motivo);
    }

    // Verifica contratos no mesmo evento.
    for (const a of entrada.alocacoes) {
      const orcRef = db.collection("orcamento").doc(a.idOrcamento);
      const orcSnap = await tx.get(orcRef);
      if (!orcSnap.exists) {
        throw new HttpsError("not-found", `Orçamento ${a.idOrcamento} ausente.`);
      }
      const orc = orcSnap.data() ?? {};
      if (String(orc.id_evento ?? "") !== recebimento.idEvento) {
        throw new HttpsError(
          "failed-precondition",
          "Contrato de outro evento/pedido.",
        );
      }
    }

    const ids: string[] = [];
    let soma = alocado;
    for (const a of entrada.alocacoes) {
      const ref = db.collection(COL_ALOCACOES).doc();
      ids.push(ref.id);
      soma += a.valorCentavos;
      tx.set(ref, {
        schema: 1,
        id_alocacao: ref.id,
        id_recebimento: entrada.idRecebimento,
        id_contrato: texto(a.idContrato),
        id_orcamento: texto(a.idOrcamento),
        id_evento: recebimento.idEvento,
        id_fornecedor: texto(a.idFornecedor) || null,
        valor: dinheiro(a.valorCentavos),
        valor_centavos: a.valorCentavos,
        criterio: entrada.criterio ?? "manual_explicito",
        chave_idempotencia: chave,
        operador_id: entrada.autorId,
        criado_em: FieldValue.serverTimestamp(),
      });
    }
    if (soma > valor) {
      throw new HttpsError(
        "aborted",
        "Concorrência: alocação excederia o recebimento.",
      );
    }
    tx.update(recRef, {
      alocado_centavos: soma,
      atualizado_em: FieldValue.serverTimestamp(),
    });
    return { ids, idempotente: false };
  }).then(async (res) => {
    await auditar(db, entrada.autorId, "alocar_recebimento", {
      id_recebimento: entrada.idRecebimento,
      ids_alocacao: res.ids,
    });
    return res;
  });
}

async function carregarPoliticaAtiva(
  db: Firestore,
): Promise<PoliticaLiberacaoRepasse | null> {
  const snap = await db
    .collection(COL_LIBERACAO)
    .where("ativa", "==", true)
    .limit(1)
    .get();
  if (snap.empty) return null;
  const d = snap.docs[0].data();
  return {
    id: snap.docs[0].id,
    versao: Number(d.versao ?? 1),
    ativa: d.ativa === true,
    permiteRepasseParcial: d.permite_repasse_parcial === true,
    tetoParcialCentavos:
      typeof d.teto_parcial_centavos === "number"
        ? d.teto_parcial_centavos
        : null,
  };
}

export async function prepararOuAutorizarRepasse(
  db: Firestore,
  entrada: {
    idContrato: string;
    idOrcamento: string;
    idFornecedor: string;
    valorCentavos: number;
    percentualBps: number;
    modoComissao?: "descontada_fornecedor" | "adicionada_cliente";
    valorContratadoCentavos: number;
    chaveIdempotencia: string;
    autorId: string;
    forcarAutorizacaoSeElegivel?: boolean;
  },
): Promise<{
  id: string;
  estado: EstadoRepasse;
  elegivelCentavos: number;
  motivo: string | null;
  idempotente: boolean;
}> {
  const chave = texto(entrada.chaveIdempotencia);
  const prev = await db
    .collection(COL_REPASSES)
    .where("chave_idempotencia", "==", chave)
    .limit(1)
    .get();
  if (!prev.empty) {
    const d = prev.docs[0].data();
    return {
      id: prev.docs[0].id,
      estado: d.estado as EstadoRepasse,
      elegivelCentavos: Number(d.valor_centavos ?? 0),
      motivo: null,
      idempotente: true,
    };
  }

  const orcSnap = await db.collection("orcamento").doc(entrada.idOrcamento).get();
  if (!orcSnap.exists) {
    throw new HttpsError("not-found", "Orçamento não encontrado.");
  }
  const orc = orcSnap.data() ?? {};
  const idEvento = String(orc.id_evento ?? "");

  const alocSnap = await db
    .collection(COL_ALOCACOES)
    .where("id_orcamento", "==", entrada.idOrcamento)
    .limit(100)
    .get();
  let alocado = 0;
  const idsAloc: string[] = [];
  for (const doc of alocSnap.docs) {
    alocado += Number(doc.data().valor_centavos ?? 0);
    idsAloc.push(doc.id);
  }

  const repSnap = await db
    .collection(COL_REPASSES)
    .where("id_orcamento", "==", entrada.idOrcamento)
    .limit(100)
    .get();
  let jaRepassado = 0;
  let jaAuth = 0;
  for (const doc of repSnap.docs) {
    const st = String(doc.data().estado ?? "");
    const v = Number(doc.data().valor_centavos ?? 0);
    if (st === "confirmado") jaRepassado += v;
    if (st === "autorizado" || st === "em_processamento") jaAuth += v;
  }

  const politica = await carregarPoliticaAtiva(db);
  const direitos = calcularDireitosContrato({
    valorContratadoCentavos: entrada.valorContratadoCentavos,
    percentualBps: entrada.percentualBps,
    modoComissao: entrada.modoComissao ?? "descontada_fornecedor",
  });
  const eleg = avaliarElegibilidadeRepasse({
    direitoFornecedorPrevistoCentavos: direitos.direitoFornecedorPrevistoCentavos,
    alocadoAoContratoCentavos: alocado,
    jaRepassadoCentavos: jaRepassado,
    jaAutorizadoOuProcessandoCentavos: jaAuth,
    politica,
  });

  const pedido = entrada.valorCentavos;
  dinheiro(pedido);
  if (pedido > eleg.elegivelCentavos && eleg.elegivelCentavos > 0) {
    throw new HttpsError(
      "failed-precondition",
      `Valor solicitado (${pedido}) excede elegível (${eleg.elegivelCentavos}).`,
    );
  }

  let estado: EstadoRepasse = eleg.estadoSugerido;
  let motivo = eleg.motivo;
  const valorFinal =
    eleg.elegivelCentavos > 0 ? Math.min(pedido, eleg.elegivelCentavos) : pedido;

  if (
    entrada.forcarAutorizacaoSeElegivel &&
    eleg.elegivelCentavos > 0 &&
    estado === "autorizado"
  ) {
    // permanece autorizado
  } else if (eleg.elegivelCentavos <= 0) {
    estado = "elegivel_pendente";
  }

  const ref = db.collection(COL_REPASSES).doc();
  await ref.set({
    schema: 1,
    id_repasse: ref.id,
    id_contrato: texto(entrada.idContrato),
    id_orcamento: texto(entrada.idOrcamento),
    id_evento: idEvento,
    id_fornecedor: texto(entrada.idFornecedor),
    id_beneficiario: texto(entrada.idFornecedor),
    valor: dinheiro(valorFinal),
    valor_centavos: valorFinal,
    estado,
    ids_alocacao_origem: idsAloc,
    confirmacao_manual: false,
    motivo_bloqueio: motivo,
    politica_liberacao_id: politica?.id ?? null,
    chave_idempotencia: chave,
    operador_id: entrada.autorId,
    // Sem banco integrado.
    transferencia_bancaria: false,
    criado_em: FieldValue.serverTimestamp(),
  });
  await auditar(db, entrada.autorId, "preparar_repasse", {
    id_repasse: ref.id,
    estado,
    valor_centavos: valorFinal,
  });
  return {
    id: ref.id,
    estado,
    elegivelCentavos: eleg.elegivelCentavos,
    motivo,
    idempotente: false,
  };
}

export async function confirmarRepasseManual(
  db: Firestore,
  entrada: {
    idRepasse: string;
    autorId: string;
    evidencias?: string | null;
  },
): Promise<{ estado: EstadoRepasse }> {
  const ref = db.collection(COL_REPASSES).doc(entrada.idRepasse);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Repasse não encontrado.");
  }
  const atual = String(snap.data()?.estado ?? "previsto") as EstadoRepasse;
  const next = transicionarRepasse({
    estadoAtual: atual,
    acao: "confirmar_manual",
    confirmacaoManual: true,
  });
  await ref.update({
    estado: next.estado,
    confirmacao_manual: true,
    evidencias: texto(entrada.evidencias) || null,
    confirmado_em: FieldValue.serverTimestamp(),
    confirmado_por: entrada.autorId,
  });
  await auditar(db, entrada.autorId, "confirmar_repasse_manual", {
    id_repasse: entrada.idRepasse,
    estado_anterior: atual,
  });
  return { estado: next.estado };
}

export async function registrarAjustePosRepasse(
  db: Firestore,
  entrada: {
    idEvento: string;
    idRepasse: string;
    valorChargebackCentavos: number;
    autorId: string;
    motivo: string;
  },
): Promise<{ id: string }> {
  const rep = await db.collection(COL_REPASSES).doc(entrada.idRepasse).get();
  if (!rep.exists) {
    throw new HttpsError("not-found", "Repasse não encontrado.");
  }
  const st = String(rep.data()?.estado ?? "");
  if (st !== "confirmado") {
    throw new HttpsError(
      "failed-precondition",
      "Ajuste pós-repasse exige repasse confirmado.",
    );
  }
  const repassado = Number(rep.data()?.valor_centavos ?? 0);
  dinheiro(entrada.valorChargebackCentavos);
  const ref = db.collection(COL_AJUSTES).doc();
  await ref.set({
    schema: 1,
    id_ajuste: ref.id,
    tipo: "chargeback_pos_repasse",
    id_evento: texto(entrada.idEvento),
    id_repasse: entrada.idRepasse,
    valor_centavos: entrada.valorChargebackCentavos,
    recuperacao_pendente_centavos: Math.min(
      entrada.valorChargebackCentavos,
      repassado,
    ),
    repasse_historico_preservado_centavos: repassado,
    motivo: texto(entrada.motivo),
    operador_id: entrada.autorId,
    criado_em: FieldValue.serverTimestamp(),
  });
  // Não apaga o repasse histórico.
  await auditar(db, entrada.autorId, "ajuste_pos_repasse", {
    id_ajuste: ref.id,
    id_repasse: entrada.idRepasse,
  });
  return { id: ref.id };
}

export async function consultarExtratoIntermediacao(
  db: Firestore,
  idEvento: string,
): Promise<Record<string, unknown>> {
  const ev = texto(idEvento);
  const [rec, aloc, rep, pol, orcs] = await Promise.all([
    db.collection(COL_RECEBIMENTOS).where("id_evento", "==", ev).limit(100).get(),
    db.collection(COL_ALOCACOES).where("id_evento", "==", ev).limit(200).get(),
    db.collection(COL_REPASSES).where("id_evento", "==", ev).limit(100).get(),
    carregarPoliticaAtiva(db),
    db.collection("orcamento").where("id_evento", "==", ev).limit(50).get(),
  ]);

  const recebimentos = rec.docs.map((d) => ({ id: d.id, ...d.data() }));
  const alocacoes = aloc.docs.map((d) => ({ id: d.id, ...d.data() }));
  const repasses = rep.docs.map((d) => ({ id: d.id, ...d.data() }));

  const contratos = montarContratosDoEvento({
    orcamentos: orcs.docs.map((d) => ({ id: d.id, data: d.data() })),
    alocacoes: aloc.docs.map((d) => d.data()),
    repasses: rep.docs.map((d) => d.data()),
    politica: pol,
  });

  let recebido = 0;
  let alocado = 0;
  let repassado = 0;
  for (const r of recebimentos) {
    recebido += Number((r as { valor_centavos?: number }).valor_centavos ?? 0);
  }
  for (const a of alocacoes) {
    alocado += Number((a as { valor_centavos?: number }).valor_centavos ?? 0);
  }
  for (const r of repasses) {
    if ((r as { estado?: string }).estado === "confirmado") {
      repassado += Number((r as { valor_centavos?: number }).valor_centavos ?? 0);
    }
  }

  return {
    ok: true,
    id_evento: ev,
    recebimentos,
    alocacoes,
    repasses,
    contratos,
    politica_liberacao: pol,
    sintese: {
      recebido_plataforma_centavos: recebido,
      alocado_centavos: alocado,
      sem_alocacao_centavos: Math.max(0, recebido - alocado),
      repassado_confirmado_centavos: repassado,
      // Não rotular residual como receita APP.
      residual_nao_e_receita_app: true,
    },
    aviso:
      pol?.ativa === true
        ? null
        : "Política de liberação inativa — elegibilidade de repasse pendente.",
  };
}

/** Comissão padrão da plataforma (5%) — mesma usada no acompanhamento. */
export const PERCENTUAL_BPS_PADRAO = 500;

/**
 * Contratos fechados (ou já com alocação) do evento, com elegibilidade
 * de repasse avaliada pela política ativa — base do passo 4 da tela.
 */
export function montarContratosDoEvento(params: {
  orcamentos: Array<{ id: string; data: Record<string, unknown> }>;
  alocacoes: Array<Record<string, unknown>>;
  repasses: Array<Record<string, unknown>>;
  politica: PoliticaLiberacaoRepasse | null;
}): Array<Record<string, unknown>> {
  const alocPorOrc = new Map<string, number>();
  for (const a of params.alocacoes) {
    const id = texto(a.id_orcamento);
    alocPorOrc.set(id, (alocPorOrc.get(id) ?? 0) + Number(a.valor_centavos ?? 0));
  }
  const confPorOrc = new Map<string, number>();
  const authPorOrc = new Map<string, number>();
  for (const r of params.repasses) {
    const id = texto(r.id_orcamento);
    const v = Number(r.valor_centavos ?? 0);
    const st = String(r.estado ?? "");
    if (st === "confirmado") confPorOrc.set(id, (confPorOrc.get(id) ?? 0) + v);
    if (st === "autorizado" || st === "em_processamento") {
      authPorOrc.set(id, (authPorOrc.get(id) ?? 0) + v);
    }
  }

  const out: Array<Record<string, unknown>> = [];
  for (const { id, data: d } of params.orcamentos) {
    const status = texto(d.status).toLowerCase();
    const fechado =
      d.orcamento_fechado === true || status === "fechado" || status === "contratado";
    const alocado = alocPorOrc.get(id) ?? 0;
    if (!fechado && alocado <= 0) continue;

    const valorContratado = centavosDeOrcamento(d).contratado;
    const direitos = calcularDireitosContrato({
      valorContratadoCentavos: valorContratado,
      percentualBps: PERCENTUAL_BPS_PADRAO,
      modoComissao: "descontada_fornecedor",
    });
    const confirmado = confPorOrc.get(id) ?? 0;
    const autorizado = authPorOrc.get(id) ?? 0;
    const eleg = avaliarElegibilidadeRepasse({
      direitoFornecedorPrevistoCentavos: direitos.direitoFornecedorPrevistoCentavos,
      alocadoAoContratoCentavos: alocado,
      jaRepassadoCentavos: confirmado,
      jaAutorizadoOuProcessandoCentavos: autorizado,
      politica: params.politica,
    });
    const idContrato =
      (d.contrato_financeiro &&
        typeof d.contrato_financeiro === "object" &&
        texto((d.contrato_financeiro as { id?: unknown }).id)) ||
      id;

    out.push({
      id_orcamento: id,
      id_contrato: idContrato,
      id_fornecedor: texto(d.id_fornecedor) || null,
      nome_servico:
        texto(d.nome_servico) ||
        texto(d.categoria_nome) ||
        texto(d.titulo) ||
        "Serviço contratado",
      fechado,
      valor_contratado_centavos: valorContratado,
      percentual_bps: PERCENTUAL_BPS_PADRAO,
      direito_fornecedor_centavos: direitos.direitoFornecedorPrevistoCentavos,
      comissao_centavos: direitos.comissaoPrevistaCentavos,
      pagamento_declarado_centavos: Number(d.pagamento_declarado_centavos ?? 0),
      alocado_centavos: alocado,
      repasse_autorizado_centavos: autorizado,
      repasse_confirmado_centavos: confirmado,
      elegivel_centavos: eleg.elegivelCentavos,
      motivo_bloqueio: eleg.motivo,
    });
  }
  return out;
}

export { disponivelParaAlocar };
