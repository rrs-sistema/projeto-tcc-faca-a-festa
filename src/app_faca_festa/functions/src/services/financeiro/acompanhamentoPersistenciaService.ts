/**
 * Persistência do acompanhamento das partes + execução.
 */

import { FieldValue, Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import {
  EstadoExecucaoParte,
  montarVisaoFornecedor,
  montarVisaoOrganizador,
  NivelPagamentoPlataforma,
  transicionarExecucao,
  VisaoContratoFornecedor,
  VisaoContratoOrganizador,
} from "./acompanhamentoPartesService";
import {
  COL_ALOCACOES,
  COL_RECEBIMENTOS,
  COL_REPASSES,
} from "./intermediacaoPersistenciaService";
import { parseEstadoExecucao } from "./contratacaoIdentidadeService";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function parseData(v: unknown): string | null {
  if (!v) return null;
  if (typeof v === "string") return v;
  if (typeof v === "object" && v !== null && "toDate" in v) {
    try {
      return (v as { toDate: () => Date }).toDate().toISOString();
    } catch {
      return null;
    }
  }
  return null;
}

async function agregadosContrato(
  db: Firestore,
  idOrcamento: string,
): Promise<{
  declarado: number;
  alocado: number;
  repasseAutorizado: number;
  repasseConfirmado: number;
  estadoRepasse: string;
}> {
  const [declSnap, alocSnap, repSnap] = await Promise.all([
    db
      .collection(COL_RECEBIMENTOS)
      .where("id_orcamento_declarado", "==", idOrcamento)
      .limit(50)
      .get()
      .catch(() => null),
    db
      .collection(COL_ALOCACOES)
      .where("id_orcamento", "==", idOrcamento)
      .limit(50)
      .get()
      .catch(() => null),
    db
      .collection(COL_REPASSES)
      .where("id_orcamento", "==", idOrcamento)
      .limit(50)
      .get()
      .catch(() => null),
  ]);

  let declarado = 0;
  if (declSnap) {
    for (const d of declSnap.docs) {
      const x = d.data();
      if (String(x.nivel_confirmacao ?? "") === "declaracao") {
        declarado += Number(x.valor_centavos ?? 0);
      }
    }
  }
  // Também declarações no próprio orçamento.
  const orc = await db.collection("orcamento").doc(idOrcamento).get();
  const od = orc.data() ?? {};
  declarado += Number(od.pagamento_declarado_centavos ?? 0);

  let alocado = 0;
  if (alocSnap) {
    for (const d of alocSnap.docs) {
      alocado += Number(d.data().valor_centavos ?? 0);
    }
  }

  let repasseAutorizado = 0;
  let repasseConfirmado = 0;
  let estadoRepasse = "sem_repasse";
  if (repSnap) {
    for (const d of repSnap.docs) {
      const x = d.data();
      const st = String(x.estado ?? "");
      const v = Number(x.valor_centavos ?? 0);
      if (st === "confirmado") {
        repasseConfirmado += v;
        estadoRepasse = "confirmado";
      } else if (st === "autorizado" || st === "em_processamento") {
        repasseAutorizado += v;
        if (estadoRepasse === "sem_repasse") estadoRepasse = st;
      } else if (st === "elegivel_pendente" && estadoRepasse === "sem_repasse") {
        estadoRepasse = "elegivel_pendente";
      }
    }
  }

  return { declarado, alocado, repasseAutorizado, repasseConfirmado, estadoRepasse };
}

function nomeUsuario(u: Record<string, unknown> | null): string | null {
  if (!u) return null;
  return (
    texto(u.nome) ||
    texto(u.nome_completo) ||
    texto(u.display_name) ||
    null
  );
}

function nomeForn(f: Record<string, unknown> | null): string | null {
  if (!f) return null;
  return (
    texto(f.nome_fornecedor) ||
    texto(f.nomeFantasia) ||
    texto(f.nome_fantasia) ||
    texto(f.nome) ||
    null
  );
}

export async function listarAcompanhamentoOrganizador(
  db: Firestore,
  params: { idEvento: string; uid: string },
): Promise<{
  linhas: VisaoContratoOrganizador[];
  completo: boolean;
  aviso: string | null;
}> {
  const ev = await db.collection("evento").doc(params.idEvento).get();
  if (!ev.exists) throw new HttpsError("not-found", "Evento não encontrado.");
  const dono = texto(ev.data()?.id_usuario);
  if (dono !== params.uid) {
    // solicitante de algum orçamento também pode ver só os seus — filtrado abaixo
  }

  const orcSnap = await db
    .collection("orcamento")
    .where("id_evento", "==", params.idEvento)
    .limit(100)
    .get();

  const nomeEvento =
    texto(ev.data()?.nome_evento) ||
    texto(ev.data()?.nome) ||
    null;

  const linhas: VisaoContratoOrganizador[] = [];
  for (const doc of orcSnap.docs) {
    const d = doc.data();
    const solicitante = texto(d.id_solicitante);
    if (dono !== params.uid && solicitante !== params.uid) continue;

    const status = texto(d.status).toLowerCase();
    const contratado =
      d.orcamento_fechado === true ||
      status === "fechado" ||
      status === "contratado";
    if (!contratado) continue;

    const idForn = texto(d.id_fornecedor);
    const forn = idForn
      ? (await db.collection("fornecedor").doc(idForn).get()).data() ?? null
      : null;
    const agg = await agregadosContrato(db, doc.id);
    const exec = parseEstadoExecucao(
      d.contrato_financeiro && typeof d.contrato_financeiro === "object"
        ? (d.contrato_financeiro as { estado_execucao?: string }).estado_execucao
        : d.estado_execucao,
    ) as EstadoExecucaoParte;

    linhas.push(
      montarVisaoOrganizador({
        idContrato: texto((d.contrato_financeiro as { id?: string })?.id) || doc.id,
        idOrcamento: doc.id,
        idEvento: params.idEvento,
        nomeEvento,
        nomeFornecedor: nomeForn(forn as Record<string, unknown> | null),
        nomeServico:
          texto(d.nome_servico) ||
          texto(d.nome) ||
          null,
        escopo: texto(d.anotacoes) || null,
        valorContratadoCentavos:
          Number(d.valor_contratado_centavos ?? 0) ||
          Math.round(Number(d.valor_contratado ?? d.valor ?? 0) * 100),
        declaradoCentavos: agg.declarado,
        confirmadoAlocadoCentavos: agg.alocado,
        estadoRepasse: agg.estadoRepasse as "sem_repasse",
        estadoExecucao: exec,
        parcelasConhecidas: true,
        politicaLiberacaoAtiva: false,
      }),
    );
  }

  return {
    linhas,
    completo: orcSnap.size < 100,
    aviso:
      orcSnap.size >= 100
        ? "Lista limitada; não é inventário total."
        : null,
  };
}

export async function listarAcompanhamentoFornecedor(
  db: Firestore,
  params: { idFornecedor: string },
): Promise<{
  linhas: VisaoContratoFornecedor[];
  completo: boolean;
  aviso: string | null;
}> {
  const orcSnap = await db
    .collection("orcamento")
    .where("id_fornecedor", "==", params.idFornecedor)
    .limit(100)
    .get();

  const linhas: VisaoContratoFornecedor[] = [];
  for (const doc of orcSnap.docs) {
    const d = doc.data();
    const status = texto(d.status).toLowerCase();
    const contratado =
      d.orcamento_fechado === true ||
      status === "fechado" ||
      status === "contratado";
    if (!contratado) continue;

    const idEvento = texto(d.id_evento);
    const ev = idEvento
      ? (await db.collection("evento").doc(idEvento).get()).data()
      : null;
    const idSol = texto(d.id_solicitante) || texto(ev?.id_usuario);
    const user = idSol
      ? (await db.collection("usuarios").doc(idSol).get()).data()
      : null;

    const agg = await agregadosContrato(db, doc.id);
    const exec = parseEstadoExecucao(
      d.contrato_financeiro && typeof d.contrato_financeiro === "object"
        ? (d.contrato_financeiro as { estado_execucao?: string }).estado_execucao
        : d.estado_execucao,
    ) as EstadoExecucaoParte;

    const valor =
      Number(d.valor_contratado_centavos ?? 0) ||
      Math.round(Number(d.valor_contratado ?? d.valor ?? 0) * 100);

    linhas.push(
      montarVisaoFornecedor({
        idContrato: texto((d.contrato_financeiro as { id?: string })?.id) || doc.id,
        idOrcamento: doc.id,
        idEvento,
        nomeEvento:
          texto(ev?.nome_evento) || texto(ev?.nome) || null,
        dataEvento: parseData(ev?.data) || parseData(d.data_evento),
        nomeContratante: nomeUsuario(user as Record<string, unknown> | null),
        nomeServico: texto(d.nome_servico) || texto(d.nome) || null,
        escopo: texto(d.anotacoes) || null,
        valorContratadoCentavos: valor,
        percentualBps: 500,
        modoComissao: "descontada_fornecedor",
        alocadoPlataformaCentavos: agg.alocado,
        repasseAutorizadoCentavos: agg.repasseAutorizado,
        repasseConfirmadoCentavos: agg.repasseConfirmado,
        politicaLiberacaoAtiva: false,
        estadoExecucao: exec,
      }),
    );
  }

  return {
    linhas,
    completo: orcSnap.size < 100,
    aviso: orcSnap.size >= 100 ? "Lista limitada." : null,
  };
}

export async function declararPagamentoCliente(
  db: Firestore,
  entrada: {
    idOrcamento: string;
    idEvento: string;
    valorCentavos: number;
    chaveIdempotencia: string;
    autorId: string;
    referenciaComprovante?: string | null;
  },
): Promise<{
  ok: true;
  nivel: NivelPagamentoPlataforma;
  confirmado: false;
  idempotente: boolean;
}> {
  const chave = texto(entrada.chaveIdempotencia);
  if (!chave) {
    throw new HttpsError("invalid-argument", "Informe chave de idempotência.");
  }
  if (!Number.isInteger(entrada.valorCentavos) || entrada.valorCentavos <= 0) {
    throw new HttpsError("invalid-argument", "Valor inválido.");
  }

  const col = db.collection("plataforma_pagamentos_declarados");
  const existentes = await col.where("chave_idempotencia", "==", chave).limit(1).get();
  if (!existentes.empty) {
    return {
      ok: true,
      nivel: "declarado",
      confirmado: false,
      idempotente: true,
    };
  }

  const orcRef = db.collection("orcamento").doc(entrada.idOrcamento);
  const orc = await orcRef.get();
  if (!orc.exists) throw new HttpsError("not-found", "Contrato não encontrado.");

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orcRef);
    const atual = Number(snap.data()?.pagamento_declarado_centavos ?? 0);
    tx.set(col.doc(), {
      schema: 1,
      id_evento: entrada.idEvento,
      id_orcamento: entrada.idOrcamento,
      valor_centavos: entrada.valorCentavos,
      nivel_confirmacao: "declaracao",
      referencia_comprovante: entrada.referenciaComprovante ?? null,
      chave_idempotencia: chave,
      autor_id: entrada.autorId,
      confirmado: false,
      criado_em: FieldValue.serverTimestamp(),
    });
    tx.update(orcRef, {
      pagamento_declarado_centavos: atual + entrada.valorCentavos,
      pagamento_declarado_em: FieldValue.serverTimestamp(),
    });
  });

  return {
    ok: true,
    nivel: "declarado",
    confirmado: false,
    idempotente: false,
  };
}

export async function atualizarExecucaoContrato(
  db: Firestore,
  entrada: {
    idOrcamento: string;
    acao: "informar_entrega" | "aceitar" | "contestar" | "decisao_operador";
    autorId: string;
    papel: "fornecedor" | "cliente" | "admin";
    motivo?: string;
    novoEstadoOperador?: EstadoExecucaoParte;
    chaveIdempotencia: string;
  },
): Promise<{ estado: EstadoExecucaoParte; idempotente: boolean }> {
  const chave = texto(entrada.chaveIdempotencia);
  const histCol = db
    .collection("orcamento")
    .doc(entrada.idOrcamento)
    .collection("execucao_historico");

  const idem = await histCol.where("chave_idempotencia", "==", chave).limit(1).get();
  if (!idem.empty) {
    const st = String(idem.docs[0].data().estado_novo ?? "nao_iniciado");
    return {
      estado: parseEstadoExecucao(st) as EstadoExecucaoParte,
      idempotente: true,
    };
  }

  const ref = db.collection("orcamento").doc(entrada.idOrcamento);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Contrato não encontrado.");
    const d = snap.data()!;
    const atual = parseEstadoExecucao(
      d.contrato_financeiro && typeof d.contrato_financeiro === "object"
        ? (d.contrato_financeiro as { estado_execucao?: string }).estado_execucao
        : d.estado_execucao,
    ) as EstadoExecucaoParte;

    if (entrada.acao === "informar_entrega" && entrada.papel !== "fornecedor" && entrada.papel !== "admin") {
      throw new HttpsError("permission-denied", "Só o fornecedor informa entrega.");
    }
    if (
      (entrada.acao === "aceitar" || entrada.acao === "contestar") &&
      entrada.papel !== "cliente" &&
      entrada.papel !== "admin"
    ) {
      throw new HttpsError("permission-denied", "Só o cliente registra aceite/contestação.");
    }

    let novo: EstadoExecucaoParte;
    try {
      novo = transicionarExecucao({
        atual,
        acao: entrada.acao,
        novoEstadoOperador: entrada.novoEstadoOperador,
      }).novo;
    } catch (e) {
      throw new HttpsError(
        "failed-precondition",
        e instanceof Error ? e.message : "Transição inválida.",
      );
    }

    const cf =
      d.contrato_financeiro && typeof d.contrato_financeiro === "object"
        ? { ...(d.contrato_financeiro as Record<string, unknown>) }
        : {};
    cf.estado_execucao = novo;

    tx.update(ref, {
      contrato_financeiro: cf,
      estado_execucao: novo,
    });
    const histRef = histCol.doc();
    tx.set(histRef, {
      schema: 1,
      acao: entrada.acao,
      estado_anterior: atual,
      estado_novo: novo,
      autor_id: entrada.autorId,
      papel: entrada.papel,
      motivo: texto(entrada.motivo) || null,
      chave_idempotencia: chave,
      // Manifestação preservada — não apaga anteriores.
      criado_em: FieldValue.serverTimestamp(),
    });

    return { estado: novo, idempotente: false };
  });
}
