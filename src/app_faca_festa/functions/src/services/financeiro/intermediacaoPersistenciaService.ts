import { createHash } from "crypto";
import { carregarContextoRepasse, COL_AUTORIZACOES, contratado, divisaoContrato, assinaturaContrato, impedimentoRepasse } from "./liberacaoRepasseService";
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

  // Compatibilidade com recebimentos anteriores à identidade determinística.
  const existente = await db
    .collection(COL_RECEBIMENTOS)
    .where("chave_idempotencia", "==", chave)
    .limit(1)
    .get();
  if (!existente.empty) {
    const anterior = existente.docs[0].data();
    if (anterior.id_evento !== idEvento || anterior.valor_centavos !== entrada.valorCentavos || anterior.operador_id !== entrada.autorId) {
      throw new HttpsError("already-exists", "Chave já utilizada para outro recebimento.");
    }
    return { id: existente.docs[0].id, idempotente: true };
  }

  const ref = db.collection(COL_RECEBIMENTOS).doc(createHash("sha256").update(`${entrada.autorId}:${chave}`).digest("hex"));
  return db.runTransaction(async tx => {
    const previa = await tx.get(ref);
    if (previa.exists) {
      if (previa.data()?.id_evento !== idEvento || previa.data()?.valor_centavos !== entrada.valorCentavos) {
        throw new HttpsError("already-exists", "Chave já utilizada para outro recebimento.");
      }
      return { id: ref.id, idempotente: true };
    }
    const evento = await tx.get(db.collection("evento").doc(idEvento));
    if (!evento.exists) throw new HttpsError("not-found", "Evento não encontrado.");
    if (entrada.valorCentavos <= 0 || !["declaracao", "conferencia", "fonte_externa"].includes(entrada.nivelConfirmacao ?? "conferencia")) {
      throw new HttpsError("invalid-argument", "Valor ou nível de confirmação inválido.");
    }
    tx.set(ref, {
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
    tx.set(db.collection(COL_AUDITORIA).doc(), { acao: "registrar_recebimento", autor_id: entrada.autorId,
      id_recebimento: ref.id, id_evento: idEvento, valor_centavos: entrada.valorCentavos,
      criado_em: FieldValue.serverTimestamp() });
    return { id: ref.id, idempotente: false };
  });
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
    const repetida = await tx.get(db.collection(COL_ALOCACOES).where("chave_idempotencia", "==", chave));
    if (!repetida.empty) return { ids: repetida.docs.map(d => d.id), idempotente: true };
    const recRef = db.collection(COL_RECEBIMENTOS).doc(entrada.idRecebimento);
    const recSnap = await tx.get(recRef);
    if (!recSnap.exists) {
      throw new HttpsError("not-found", "Recebimento não encontrado.");
    }
    const rec = recSnap.data() ?? {};
    if (!["conferencia", "fonte_externa"].includes(rec.nivel_confirmacao)) {
      throw new HttpsError("failed-precondition", "Declaração de pagamento não pode financiar um repasse. Confira o recebimento primeiro.");
    }
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
      const contratoReal = orc.contrato_financeiro?.id_contrato || a.idOrcamento;
      if (!contratado(orc) || a.idContrato !== contratoReal ||
          (a.idFornecedor && a.idFornecedor !== orc.id_fornecedor)) {
        throw new HttpsError("failed-precondition", "Alocação exige contratação confirmada com contrato e fornecedor correspondentes.");
      }
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
  if (!chave || chave.length > 128 || !entrada.idOrcamento) {
    throw new HttpsError("invalid-argument", "Contrato e chave de idempotência são obrigatórios.");
  }
  dinheiro(entrada.valorCentavos);
  if (entrada.valorCentavos <= 0) throw new HttpsError("invalid-argument", "Informe um valor positivo.");
  const ref = db.collection(COL_REPASSES).doc(createHash("sha256").update(`${entrada.autorId}:${chave}`).digest("hex"));
  return db.runTransaction(async tx => {
    const anterior = await tx.get(ref);
    if (anterior.exists) {
      const d = anterior.data()!;
      if (d.id_orcamento !== entrada.idOrcamento || d.valor_centavos !== entrada.valorCentavos || d.id_fornecedor !== entrada.idFornecedor) {
        throw new HttpsError("already-exists", "Chave já utilizada para outro repasse.");
      }
      return { id: ref.id, estado: d.estado as EstadoRepasse, elegivelCentavos: 0, motivo: d.motivo_bloqueio || null, idempotente: true };
    }
    const ctx = await carregarContextoRepasse(db, tx, entrada.idOrcamento);
    if (ctx.idContrato !== entrada.idContrato || ctx.orcamento.id_fornecedor !== entrada.idFornecedor) {
      throw new HttpsError("failed-precondition", "Contrato ou fornecedor não corresponde à contratação.");
    }
    const alocSnap = await tx.get(db.collection(COL_ALOCACOES).where("id_orcamento", "==", entrada.idOrcamento));
    const repSnap = await tx.get(db.collection(COL_REPASSES).where("id_orcamento", "==", entrada.idOrcamento));
    const polSnap = await tx.get(db.collection(COL_LIBERACAO).where("ativa", "==", true));
    const p = polSnap.size === 1 ? polSnap.docs[0] : null;
    const politica = p ? { id: p.id, versao: Number(p.data().versao ?? 1), ativa: true,
      permiteRepasseParcial: p.data().permite_repasse_parcial === true,
      tetoParcialCentavos: p.data().teto_parcial_centavos ?? null } : null;
    let alocado = 0, confirmado = 0, reservado = 0;
    for (const a of alocSnap.docs) alocado += Number(a.data().valor_centavos ?? 0);
    for (const r of repSnap.docs) {
      if (r.data().estado === "confirmado") confirmado += Number(r.data().valor_centavos ?? 0);
      if (["autorizado", "em_processamento"].includes(r.data().estado)) reservado += Number(r.data().valor_centavos ?? 0);
    }
    const eleg = avaliarElegibilidadeRepasse({
      direitoFornecedorPrevistoCentavos: ctx.divisao?.direitoFornecedorCentavos ?? 0,
      alocadoAoContratoCentavos: Math.max(0, alocado - (ctx.divisao?.comissaoReservadaNoContratoCentavos ?? 0)), jaRepassadoCentavos: confirmado,
      jaAutorizadoOuProcessandoCentavos: reservado, politica,
    });
    const motivo = ctx.motivo || eleg.motivo;
    // Tentativas bloqueadas não reservam dinheiro nem criam pagamentos pendentes.
    if (motivo || entrada.valorCentavos > eleg.elegivelCentavos) {
      throw new HttpsError("failed-precondition", motivo || "Valor excede o saldo elegível para repasse.");
    }
    const estado: EstadoRepasse = "autorizado";
    tx.set(ref, {
      schema: 2, id_repasse: ref.id, id_contrato: ctx.idContrato,
      id_orcamento: entrada.idOrcamento, id_evento: ctx.orcamento.id_evento,
      id_fornecedor: ctx.orcamento.id_fornecedor, id_beneficiario: ctx.orcamento.id_fornecedor,
      valor: dinheiro(entrada.valorCentavos), valor_centavos: entrada.valorCentavos, estado,
      divisao_contrato: ctx.divisao, assinatura_contrato: ctx.assinatura,
      criterio_liberacao: ctx.evento.status === "finalizado" ? "evento_finalizado" : "autorizacao_organizador",
      ids_alocacao_origem: alocSnap.docs.map(d => d.id), confirmacao_manual: false,
      motivo_bloqueio: null, politica_liberacao_id: politica?.id,
      chave_idempotencia: chave, operador_id: entrada.autorId, transferencia_bancaria: false,
      criado_em: FieldValue.serverTimestamp(),
    });
    // Serializa reservas concorrentes do mesmo contrato e abertura de mediação.
    tx.update(ctx.ref, { repasse_revisao: FieldValue.increment(1) });
    tx.set(db.collection(COL_AUDITORIA).doc(), { acao: "autorizar_repasse", autor_id: entrada.autorId,
      id_repasse: ref.id, divisao_contrato: ctx.divisao, criado_em: FieldValue.serverTimestamp() });
    return { id: ref.id, estado, elegivelCentavos: eleg.elegivelCentavos, motivo: null, idempotente: false };
  });
}

export async function autorizarRepasseOrganizador(db: Firestore, entrada: {
  idOrcamento: string; autorId: string; motivo: string; autorizar: boolean;
}): Promise<{ ok: true }> {
  if (texto(entrada.motivo).length < 10 || entrada.motivo.length > 500) {
    throw new HttpsError("invalid-argument", "Descreva a autorização em 10 a 500 caracteres.");
  }
  return db.runTransaction(async tx => {
    const ctx = await carregarContextoRepasse(db, tx, entrada.idOrcamento);
    if ((ctx.evento.id_usuario || ctx.evento.idUsuario) !== entrada.autorId) {
      throw new HttpsError("permission-denied", "Somente o organizador do evento pode autorizar o pagamento antecipado.");
    }
    if (entrada.autorizar && (!contratado(ctx.orcamento) || !ctx.divisao)) {
      throw new HttpsError("failed-precondition", "Confirme a contratação e confira a comissão antes de autorizar.");
    }
    const dados = { id_orcamento: entrada.idOrcamento, id_evento: ctx.orcamento.id_evento,
      autor_id: entrada.autorId, ativa: entrada.autorizar, motivo: texto(entrada.motivo),
      assinatura_contrato: ctx.assinatura, atualizado_em: FieldValue.serverTimestamp() };
    tx.set(db.collection(COL_AUTORIZACOES).doc(entrada.idOrcamento), dados);
    tx.update(ctx.ref, { repasse_revisao: FieldValue.increment(1) });
    tx.set(db.collection(COL_AUDITORIA).doc(), { ...dados, acao: entrada.autorizar ? "organizador_autorizou_repasse" : "organizador_revogou_autorizacao" });
    return { ok: true as const };
  });
}

export async function confirmarRepasseManual(
  db: Firestore,
  entrada: { idRepasse: string; autorId: string; evidencias?: string | null },
): Promise<{ estado: EstadoRepasse }> {
  const evidencia = texto(entrada.evidencias);
  if (evidencia.length < 5 || evidencia.length > 1000) {
    throw new HttpsError("invalid-argument", "Informe a referência ou comprovante da transferência (5 a 1000 caracteres).");
  }
  const ref = db.collection(COL_REPASSES).doc(entrada.idRepasse);
  return db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Repasse não encontrado.");
    const d = snap.data()!;
    if (d.estado === "confirmado") return { estado: "confirmado" as EstadoRepasse };
    const ctx = await carregarContextoRepasse(db, tx, d.id_orcamento);
    if (ctx.motivo) throw new HttpsError("failed-precondition", ctx.motivo);
    if (d.assinatura_contrato !== ctx.assinatura || d.id_fornecedor !== ctx.orcamento.id_fornecedor) {
      throw new HttpsError("failed-precondition", "Condições do contrato alteradas: revise a autorização do repasse.");
    }
    const next = transicionarRepasse({ estadoAtual: d.estado, acao: "confirmar_manual", confirmacaoManual: true });
    const politica = await tx.get(db.collection(COL_LIBERACAO).doc(d.politica_liberacao_id));
    if (politica.data()?.ativa !== true) {
      throw new HttpsError("failed-precondition", "Política de repasse desativada: revise a autorização antes de confirmar.");
    }
    const obrRef = db.collection("plataforma_comissao_obrigacoes").doc(ctx.divisao!.idObrigacao);
    const obrigacao = await tx.get(obrRef);
    const liquidado = Number(obrigacao.data()?.valor_liquidado?.centavos ?? 0);
    // Retenção proporcional cumulativa; último repasse absorve o resíduo do arredondamento.
    const anteriores = await tx.get(db.collection(COL_REPASSES).where("id_orcamento", "==", d.id_orcamento));
    const confirmadoAntes = anteriores.docs.filter(r => r.data().estado === "confirmado")
      .reduce((s,r) => s + Number(r.data().valor_centavos),0);
    const retidaAntes = Number(obrigacao.data()?.liquidado_por_retencao_repasse_centavos ?? 0);
    const baseRetencao = ctx.divisao!.comissaoCentavos - ctx.divisao!.comissaoRecebidaSeparadamenteCentavos;
    const proporcao = Math.min(1, (confirmadoAntes + Number(d.valor_centavos)) / ctx.divisao!.direitoFornecedorCentavos);
    const reter = ctx.divisao!.pagadorComissao !== "plataforma_absorve"
      ? Math.min(Math.max(0, ctx.divisao!.comissaoCentavos - liquidado), Math.max(0, Math.round(baseRetencao * proporcao) - retidaAntes)) : 0;
    if (reter > 0) {
      tx.update(obrRef, { valor_liquidado: dinheiro(liquidado + reter), saldo_centavos: ctx.divisao!.comissaoCentavos - liquidado - reter, status: liquidado + reter >= ctx.divisao!.comissaoCentavos ? "recebida" : "a_vencer",
        liquidado_por_retencao_repasse_centavos: Number(obrigacao.data()?.liquidado_por_retencao_repasse_centavos ?? 0) + reter, atualizado_em: FieldValue.serverTimestamp() });
      tx.set(db.collection("plataforma_comissao_liquidacoes").doc(`retencao-${ctx.divisao!.idObrigacao}-${ref.id}`), {
        schema: 1, id_obrigacao: ctx.divisao!.idObrigacao, id_repasse: ref.id,
        tipo: "retencao_repasse", valor: dinheiro(reter), autor_id: entrada.autorId,
        registro_manual: true, confirmacao_bancaria: false, perspectiva: "plataforma_comissao",
        criado_em: FieldValue.serverTimestamp(),
      });
    }
    tx.update(ref, { estado: next.estado, confirmacao_manual: true, evidencias: evidencia,
      confirmado_em: FieldValue.serverTimestamp(), confirmado_por: entrada.autorId });
    tx.update(ctx.ref, { repasse_revisao: FieldValue.increment(1) });
    tx.set(db.collection(COL_AUDITORIA).doc(), { acao: "confirmar_repasse_manual", autor_id: entrada.autorId,
      id_repasse: ref.id, evidencias: evidencia, criado_em: FieldValue.serverTimestamp() });
    return { estado: next.estado };
  });
}

export async function cancelarRepassePendente(db: Firestore, id: string, autorId: string) {
  return db.runTransaction(async tx => {
    const ref = db.collection(COL_REPASSES).doc(id);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Repasse não encontrado.");
    const d = snap.data()!;
    const estado = transicionarRepasse({ estadoAtual: d.estado, acao: "cancelar" }).estado;
    tx.update(ref, { estado, cancelado_por: autorId, cancelado_em: FieldValue.serverTimestamp() });
    tx.update(db.collection("orcamento").doc(d.id_orcamento), { repasse_revisao: FieldValue.increment(1) });
    tx.set(db.collection(COL_AUDITORIA).doc(), { acao: "cancelar_repasse", id_repasse: id,
      autor_id: autorId, criado_em: FieldValue.serverTimestamp() });
    return { ok: true, estado };
  });
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
  const [rec, aloc, rep, pol, orcs, evento, comissoes, casos, autorizacoes] = await Promise.all([
    db.collection(COL_RECEBIMENTOS).where("id_evento", "==", ev).get(),
    db.collection(COL_ALOCACOES).where("id_evento", "==", ev).get(),
    db.collection(COL_REPASSES).where("id_evento", "==", ev).get(),
    carregarPoliticaAtiva(db),
    db.collection("orcamento").where("id_evento", "==", ev).get(),
    db.collection("evento").doc(ev).get(),
    db.collection("plataforma_comissao_obrigacoes").where("id_evento", "==", ev).get(),
    db.collection("plataforma_mediacao_casos").where("id_evento", "==", ev).get(),
    db.collection(COL_AUTORIZACOES).where("id_evento", "==", ev).get(),
  ]);

  const recebimentos = rec.docs.map((d) => ({ id: d.id, ...d.data() }));
  const alocacoes = aloc.docs.map((d) => ({ id: d.id, ...d.data() }));
  const repasses = rep.docs.map((d) => ({ id: d.id, ...d.data() }));

  const contratos = montarContratosDoEvento({
    orcamentos: orcs.docs.map((d) => ({ id: d.id, data: d.data() })),
    alocacoes: aloc.docs.map((d) => d.data()),
    repasses: rep.docs.map((d) => d.data()),
    politica: pol,
    evento: evento.data(),
    comissoes: comissoes.docs.map(d => ({ id_obrigacao: d.id, ...d.data() })),
    casos: casos.docs.map(d => d.data()),
    autorizacoes: autorizacoes.docs.map(d => d.data()),
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
  evento?: Record<string, any>;
  comissoes?: Record<string, any>[];
  casos?: Record<string, any>[];
  autorizacoes?: Record<string, any>[];
}): Array<Record<string, unknown>> {
  // Um orçamento legado pode ser espelho da mesma contratação.
  const unicos = new Map<string, typeof params.orcamentos[number]>();
  for (const o of params.orcamentos) {
    const id = (o.data.contrato_financeiro as any)?.id_contrato || o.id;
    if (!unicos.has(id) || o.id === id) unicos.set(id, o);
  }
  const alias = new Map(params.orcamentos.map(o => [o.id, unicos.get((o.data.contrato_financeiro as any)?.id_contrato || o.id)!.id]));
  const alocPorOrc = new Map<string, number>();
  for (const a of params.alocacoes) {
    const id = alias.get(texto(a.id_orcamento)) || texto(a.id_orcamento);
    alocPorOrc.set(id, (alocPorOrc.get(id) ?? 0) + Number(a.valor_centavos ?? 0));
  }
  const confPorOrc = new Map<string, number>();
  const authPorOrc = new Map<string, number>();
  for (const r of params.repasses) {
    const id = alias.get(texto(r.id_orcamento)) || texto(r.id_orcamento);
    const v = Number(r.valor_centavos ?? 0);
    const st = String(r.estado ?? "");
    if (st === "confirmado") confPorOrc.set(id, (confPorOrc.get(id) ?? 0) + v);
    if (st === "autorizado" || st === "em_processamento") {
      authPorOrc.set(id, (authPorOrc.get(id) ?? 0) + v);
    }
  }

  const out: Array<Record<string, unknown>> = [];
  for (const { id, data: d } of unicos.values()) {
    const status = texto(d.status).toLowerCase();
    const fechado =
      d.orcamento_fechado === true || status === "fechado" || status === "contratado";
    const alocado = alocPorOrc.get(id) ?? 0;
    if (!fechado && alocado <= 0) continue;

    const idContratoReal = (d.contrato_financeiro as any)?.id_contrato || id;
    const divisao = divisaoContrato(d, (params.comissoes ?? []).filter(o => o.id_contrato === idContratoReal));
    const valorContratado = centavosDeOrcamento(d).contratado;
    const assinatura = assinaturaContrato(id, d, divisao);
    const impedimento = !divisao ? "Comissão ausente ou inconsistente: confira a obrigação do contrato."
        : impedimentoRepasse({ orcamento: d, evento: params.evento ?? {},
        casos: (params.casos ?? []).filter(c => c.id_orcamento === id),
        autorizacao: (params.autorizacoes ?? []).find(a => a.id_orcamento === id), assinatura });
    const reservaComissao = divisao?.comissaoReservadaNoContratoCentavos ?? 0;
    const confirmado = confPorOrc.get(id) ?? 0;
    const autorizado = authPorOrc.get(id) ?? 0;
    const eleg = avaliarElegibilidadeRepasse({
      direitoFornecedorPrevistoCentavos: divisao?.direitoFornecedorCentavos ?? 0,
      alocadoAoContratoCentavos: Math.max(0, alocado - reservaComissao),
      jaRepassadoCentavos: confirmado,
      jaAutorizadoOuProcessandoCentavos: autorizado,
      politica: params.politica,
    });
    const idContrato =
      (d.contrato_financeiro &&
        typeof d.contrato_financeiro === "object" &&
        texto((d.contrato_financeiro as { id_contrato?: unknown }).id_contrato)) ||
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
      percentual_bps: divisao?.percentualBps ?? null,
      pagador_comissao: divisao?.pagadorComissao ?? null,
      preco_cliente_centavos: divisao?.precoClienteCentavos ?? null,
      direito_fornecedor_centavos: divisao?.direitoFornecedorCentavos ?? null,
      comissao_centavos: divisao?.comissaoCentavos ?? null,
      comissao_recebida_separadamente_centavos: divisao?.comissaoRecebidaSeparadamenteCentavos ?? 0,
      criterio_liberacao: params.evento?.status === "finalizado" ? "Evento finalizado" :
        !impedimento ? "Autorização do organizador registrada" : "Autorização do organizador necessária",
      pagamento_declarado_centavos: Number(d.pagamento_declarado_centavos ?? 0),
      alocado_centavos: alocado,
      repasse_autorizado_centavos: autorizado,
      repasse_confirmado_centavos: confirmado,
      elegivel_centavos: impedimento ? 0 : eleg.elegivelCentavos,
      motivo_bloqueio: impedimento || eleg.motivo,
    });
  }
  return out;
}

export { disponivelParaAlocar };
