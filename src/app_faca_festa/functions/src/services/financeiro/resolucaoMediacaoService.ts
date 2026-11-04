import { prepararLiberacaoAgenda } from "../agenda/agendaFornecedorService";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

/** Regulariza a execução por decisão administrativa, sem pagar ou autorizar antecipação. */
export async function resolverExecucaoAposMediacao(db: Firestore, entrada: {
  idCaso: string; autorId: string; estadoExecucao: string; motivo: string; retirarBloqueio: boolean;
}) {
  if (!["aceito", "em_execucao", "cancelado_execucao"].includes(entrada.estadoExecucao) ||
      entrada.motivo.trim().length < 10 || entrada.motivo.length > 1000) {
    throw new HttpsError("invalid-argument", "Informe a resolução e um motivo de 10 a 1000 caracteres.");
  }
  return db.runTransaction(async tx => {
    const casoRef = db.collection("plataforma_mediacao_casos").doc(entrada.idCaso);
    const casoSnap = await tx.get(casoRef);
    if (!casoSnap.exists) throw new HttpsError("not-found", "Mediação não encontrada.");
    const caso = casoSnap.data()!;
    if (caso.estado !== "fechado") throw new HttpsError("failed-precondition", "Registre a decisão e encerre a mediação antes de regularizar a execução.");
    const orcRef = db.collection("orcamento").doc(caso.id_orcamento);
    const orcSnap = await tx.get(orcRef);
    if (!orcSnap.exists) throw new HttpsError("not-found", "Contratação não encontrada.");
    const orc = orcSnap.data()!;
    const cf = orc.contrato_financeiro ?? {};
    if (orc.id_evento !== caso.id_evento || (cf.id_contrato || orcSnap.id) !== caso.id_contrato) {
      throw new HttpsError("failed-precondition", "A mediação não corresponde à contratação atual.");
    }
    const anterior = caso.resolucao_execucao;
    if ((cf.estado_execucao || orc.estado_execucao) === entrada.estadoExecucao &&
        anterior?.autor_id === entrada.autorId && anterior?.motivo === entrada.motivo.trim()) {
      return { ok: true, estadoExecucao: entrada.estadoExecucao, reservasCanceladas: 0,
        efeitoFinanceiroExecutado: false, idempotente: true };
    }
    if ((cf.estado_execucao || orc.estado_execucao) !== "contestado") {
      throw new HttpsError("failed-precondition", "Esta ação regulariza somente execução contestada.");
    }
    const casos = await tx.get(db.collection("plataforma_mediacao_casos").where("id_orcamento", "==", orcSnap.id));
    if (casos.docs.some(d => !["fechado", "cancelado_caso"].includes(d.data().estado))) {
      throw new HttpsError("failed-precondition", "Há outra mediação em aberto nesta contratação.");
    }
    const registros = await tx.get(db.collection("plataforma_mediacao_registros").where("id_caso", "==", casoSnap.id));
    const decisoes = registros.docs.map(d => d.data()).filter(d => d.tipo === "decisao")
      .sort((a, b) => instante(b.criado_em) - instante(a.criado_em));
    const ultima = decisoes[0]?.tipo_decisao;
    const permitidas = entrada.estadoExecucao === "cancelado_execucao"
      ? ["recomendar_cancelamento"] : ["manter", "recomendar_repasse"];
    if (!permitidas.includes(ultima)) {
      throw new HttpsError("failed-precondition", "A resolução precisa corresponder à última decisão registrada na mediação.");
    }
    if ((caso.retencao_efetiva_ativa || caso.recomendacao_bloqueio_ativa) && !entrada.retirarBloqueio) {
      throw new HttpsError("failed-precondition", "Confirme explicitamente a retirada do bloqueio desta mediação.");
    }
    const historico = await tx.get(orcRef.collection("execucao_historico"));
    if (historico.docs.some(d => d.data().acao === "contestar" &&
        instante(d.data().criado_em) > instante(caso.fechado_em))) {
      throw new HttpsError("failed-precondition", "Há contestação posterior ao encerramento. Abra uma nova mediação.");
    }
    const repasses = await tx.get(db.collection("plataforma_repasses").where("id_orcamento", "==", orcSnap.id));
    if (repasses.docs.some(d => d.data().estado === "em_processamento")) {
      throw new HttpsError("failed-precondition", "Há repasse em processamento. Confira a transferência antes de regularizar a execução.");
    }
    const autorizacaoRef = db.collection("plataforma_autorizacoes_repasses").doc(orcSnap.id);
    const autorizacao = await tx.get(autorizacaoRef);
    const liberarAgenda = entrada.estadoExecucao === "cancelado_execucao" ? await prepararLiberacaoAgenda(db, tx, orc, orcSnap.id, entrada.autorId) : () => {};
    liberarAgenda();
    const agora = FieldValue.serverTimestamp();
    const resolucao = { id_caso: casoSnap.id, autor_id: entrada.autorId,
      estado_anterior: "contestado", estado_novo: entrada.estadoExecucao,
      motivo: entrada.motivo.trim(), criado_em: agora };
    tx.update(orcRef, { contrato_financeiro: { ...cf, estado_execucao: entrada.estadoExecucao },
      estado_execucao: entrada.estadoExecucao, repasse_revisao: FieldValue.increment(1) });
    tx.create(orcRef.collection("execucao_historico").doc(), {
      ...resolucao, acao: "resolver_mediacao", papel: "admin", efeito_financeiro_executado: false,
    });
    tx.update(casoRef, { resolucao_execucao: resolucao, atualizado_em: agora,
      ...(entrada.retirarBloqueio ? { retencao_efetiva_ativa: false, recomendacao_bloqueio_ativa: false } : {}) });
    if (autorizacao.exists) tx.update(autorizacaoRef, { ativa: false, atualizado_em: agora,
      motivo_revogacao: "Condições revistas em mediação; nova autorização do organizador necessária." });
    let reservasCanceladas = 0;
    for (const r of repasses.docs) {
      if (["autorizado", "em_processamento", "elegivel_pendente", "previsto"].includes(r.data().estado)) {
        tx.update(r.ref, { estado: "cancelado", cancelado_por: entrada.autorId, cancelado_em: agora,
          motivo_cancelamento: "Regularização da execução após mediação. Confira novamente o repasse." });
        reservasCanceladas++;
      }
    }
    tx.create(db.collection("plataforma_mediacao_auditoria").doc(), {
      ...resolucao, acao: "regularizar_execucao", reservas_canceladas: reservasCanceladas,
      efeito_financeiro_executado: false,
    });
    tx.create(db.collection("plataforma_mediacao_registros").doc(), {
      id_caso: casoSnap.id, tipo: "analise", visibilidade: "interna",
      texto: `Execução regularizada pela administração: ${entrada.estadoExecucao}. ${entrada.motivo.trim()}`,
      autor_id: entrada.autorId, criado_em: new Date().toISOString(), efeito_financeiro_executado: false,
    });
    return { ok: true, estadoExecucao: entrada.estadoExecucao, reservasCanceladas, efeitoFinanceiroExecutado: false };
  });
}

function instante(v: any): number {
  return v?.toMillis instanceof Function ? v.toMillis() : Date.parse(String(v ?? "")) || 0;
}
