/**
 * Persistência de casos de mediação — escrita só via Admin SDK / callables.
 */

import { FieldValue, Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { transacaoIdempotente } from "../../shared/transacaoIdempotente";
import {
  aplicarRecomendacaoBloqueio,
  CasoMediacao,
  CategoriaCaso,
  EstadoCasoMediacao,
  fecharCasoSemMovimentoFinanceiro,
  filtrarRegistrosPorPapel,
  podeAbrirCaso,
  PrioridadeCaso,
  registrarDecisaoSemEfeitoFinanceiro,
  RegistroMediacao,
  TipoDecisaoMediacao,
  TipoRegistroMediacao,
  VisibilidadeRegistro,
  visibilidadeObrigatoriaDoTipo,
  CapacidadeMediacao,
  PapelConsultaMediacao,
} from "./mediacaoOperacionalService";

export const COL_CASOS = "plataforma_mediacao_casos";
export const COL_REGISTROS = "plataforma_mediacao_registros";
export const COL_AUDITORIA = "plataforma_mediacao_auditoria";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

async function auditar(
  db: Firestore,
  entrada: Record<string, unknown>,
): Promise<void> {
  await db.collection(COL_AUDITORIA).add({
    ...entrada,
    criado_em: FieldValue.serverTimestamp(),
  });
}

export function casoDeDoc(id: string, d: FirebaseFirestore.DocumentData): CasoMediacao {
  return {
    id,
    idEvento: String(d.id_evento ?? ""),
    idContrato: String(d.id_contrato ?? ""),
    idOrcamento: String(d.id_orcamento ?? ""),
    idFornecedor: d.id_fornecedor ? String(d.id_fornecedor) : null,
    idContratante: d.id_contratante ? String(d.id_contratante) : null,
    categoria: (d.categoria as CategoriaCaso) || "outro",
    motivo: String(d.motivo ?? ""),
    descricao: String(d.descricao ?? ""),
    prioridade: (d.prioridade as PrioridadeCaso) || "normal",
    estado: (d.estado as EstadoCasoMediacao) || "aberto",
    idResponsavel: d.id_responsavel ? String(d.id_responsavel) : null,
    abertoPorId: String(d.aberto_por_id ?? ""),
    abertoEm: String(d.aberto_em ?? ""),
    fechadoEm: d.fechado_em ? String(d.fechado_em) : null,
    conclusao: d.conclusao ? String(d.conclusao) : null,
    recomendacaoBloqueioAtiva: d.recomendacao_bloqueio_ativa === true,
    motivoRecomendacaoBloqueio: d.motivo_recomendacao_bloqueio
      ? String(d.motivo_recomendacao_bloqueio)
      : null,
    retencaoEfetivaAtiva: d.retencao_efetiva_ativa === true,
  };
}

function casoParaFirestore(c: CasoMediacao): Record<string, unknown> {
  return {
    id_evento: c.idEvento,
    id_contrato: c.idContrato,
    id_orcamento: c.idOrcamento,
    id_fornecedor: c.idFornecedor,
    id_contratante: c.idContratante,
    categoria: c.categoria,
    motivo: c.motivo,
    descricao: c.descricao,
    prioridade: c.prioridade,
    estado: c.estado,
    id_responsavel: c.idResponsavel,
    aberto_por_id: c.abertoPorId,
    aberto_em: c.abertoEm,
    fechado_em: c.fechadoEm,
    conclusao: c.conclusao,
    recomendacao_bloqueio_ativa: c.recomendacaoBloqueioAtiva,
    motivo_recomendacao_bloqueio: c.motivoRecomendacaoBloqueio,
    retencao_efetiva_ativa: c.retencaoEfetivaAtiva,
    schema: 1,
  };
}

export async function abrirCasoMediacao(
  db: Firestore,
  entrada: {
    idEvento: string;
    idContrato: string;
    idOrcamento: string;
    idFornecedor: string | null;
    idContratante: string | null;
    categoria: CategoriaCaso;
    motivo: string;
    descricao: string;
    prioridade?: PrioridadeCaso;
    chaveIdempotencia: string;
    autorId: string;
  },
): Promise<{ caso: CasoMediacao; idempotente: boolean }> {
  const chave = texto(entrada.chaveIdempotencia);
  if (!chave) {
    throw new HttpsError("invalid-argument", "Informe chave de idempotência.");
  }
  const motivo = texto(entrada.motivo);
  if (!motivo) {
    throw new HttpsError("invalid-argument", "Informe o motivo.");
  }

  const agora = new Date().toISOString();
  const ref = db.collection(COL_CASOS).doc();
  const caso: CasoMediacao = {
    id: ref.id,
    idEvento: texto(entrada.idEvento),
    idContrato: texto(entrada.idContrato),
    idOrcamento: texto(entrada.idOrcamento),
    idFornecedor: entrada.idFornecedor,
    idContratante: entrada.idContratante,
    categoria: entrada.categoria,
    motivo,
    descricao: texto(entrada.descricao),
    prioridade: entrada.prioridade ?? "normal",
    estado: "aberto",
    idResponsavel: null,
    abertoPorId: entrada.autorId,
    abertoEm: agora,
    fechadoEm: null,
    conclusao: null,
    recomendacaoBloqueioAtiva: false,
    motivoRecomendacaoBloqueio: null,
    retencaoEfetivaAtiva: false,
  };

  return db.runTransaction(async tx => {
    const orcRef = db.collection("orcamento").doc(entrada.idOrcamento);
    const orc = await tx.get(orcRef);
    if (!orc.exists || orc.data()?.id_evento !== caso.idEvento ||
        (orc.data()?.contrato_financeiro?.id_contrato || orcRef.id) !== caso.idContrato) {
      throw new HttpsError("failed-precondition", "A mediação deve corresponder ao evento e à contratação.");
    }
    const existentes = await tx.get(db.collection(COL_CASOS).where("chave_idempotencia", "==", chave));
    if (!existentes.empty) {
      const anterior = casoDeDoc(existentes.docs[0].id, existentes.docs[0].data());
      if (anterior.idOrcamento !== caso.idOrcamento || anterior.idEvento !== caso.idEvento) {
        throw new HttpsError("already-exists", "Chave já utilizada em outra mediação.");
      }
      return { caso: anterior, idempotente: true };
    }
    const todos = await tx.get(db.collection(COL_CASOS).where("id_orcamento", "==", caso.idOrcamento));
    const check = podeAbrirCaso({ idContrato: caso.idContrato, idEvento: caso.idEvento,
      casosAbertosNoContrato: todos.docs.filter(d => !["fechado", "cancelado_caso"].includes(d.data().estado)).length });
    if (!check.ok) throw new HttpsError("failed-precondition", check.motivo);
    tx.update(orcRef, { repasse_revisao: FieldValue.increment(1) });
    tx.create(ref, { ...casoParaFirestore(caso), chave_idempotencia: chave, atualizado_em: FieldValue.serverTimestamp() });
    tx.create(db.collection(COL_REGISTROS).doc(), { id_caso: caso.id, tipo: "abertura", visibilidade: "interna",
      texto: motivo, autor_id: entrada.autorId, criado_em: agora, efeito_financeiro_executado: false });
    tx.create(db.collection(COL_AUDITORIA).doc(), { acao: "abrir_caso", id_caso: caso.id,
      id_contrato: caso.idContrato, autor_id: entrada.autorId, criado_em: FieldValue.serverTimestamp() });
    return { caso, idempotente: false };
  });
}

export async function atribuirResponsavel(
  db: Firestore,
  entrada: {
    idCaso: string;
    idResponsavel: string;
    somenteSemResponsavel?: boolean;
    autorId: string;
  },
): Promise<CasoMediacao> {
  const ref = db.collection(COL_CASOS).doc(texto(entrada.idCaso));
  return transacaoIdempotente(db, async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Caso não encontrado.");
    }
    const caso = casoDeDoc(snap.id, snap.data()!);
    if (caso.estado === "fechado" || caso.estado === "cancelado_caso") {
      throw new HttpsError("failed-precondition", "Caso já encerrado.");
    }
    if (entrada.somenteSemResponsavel && caso.idResponsavel) {
      if (caso.idResponsavel === entrada.idResponsavel) return caso;
      throw new HttpsError("aborted", "Outro administrador já assumiu este caso. Atualize a fila.");
    }
    const agora = new Date().toISOString();
    const novo: CasoMediacao = {
      ...caso,
      idResponsavel: texto(entrada.idResponsavel),
      estado: caso.estado === "aberto" ? "em_analise" : caso.estado,
    };
    tx.update(ref, {
      id_responsavel: novo.idResponsavel,
      estado: novo.estado,
      atualizado_em: FieldValue.serverTimestamp(),
    });
    tx.create(db.collection(COL_REGISTROS).doc(), {
      id_caso: caso.id,
      tipo: "atribuicao",
      visibilidade: "interna",
      texto: `Responsável atribuído: ${novo.idResponsavel}`,
      autor_id: entrada.autorId,
      criado_em: agora,
      efeito_financeiro_executado: false,
    });
    return novo;
  });
}

export async function adicionarRegistro(
  db: Firestore,
  entrada: {
    idCaso: string;
    tipo: TipoRegistroMediacao;
    texto: string;
    visibilidade?: VisibilidadeRegistro;
    autorId: string;
    novoEstado?: EstadoCasoMediacao;
  },
): Promise<{ registroId: string }> {
  const ref = db.collection(COL_CASOS).doc(texto(entrada.idCaso));
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Caso não encontrado.");
  }
  const textoReg = texto(entrada.texto);
  if (!textoReg) {
    throw new HttpsError("invalid-argument", "Informe o texto do registro.");
  }
  const vis =
    entrada.visibilidade ?? visibilidadeObrigatoriaDoTipo(entrada.tipo);
  const agora = new Date().toISOString();
  const regRef = db.collection(COL_REGISTROS).doc();
  const batch = db.batch();
  batch.set(regRef, {
    id_caso: snap.id,
    tipo: entrada.tipo,
    visibilidade: vis,
    texto: textoReg,
    autor_id: entrada.autorId,
    criado_em: agora,
    efeito_financeiro_executado: false,
  });
  if (entrada.novoEstado) {
    batch.update(ref, {
      estado: entrada.novoEstado,
      atualizado_em: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return { registroId: regRef.id };
}

export async function registrarDecisao(
  db: Firestore,
  entrada: {
    idCaso: string;
    tipoDecisao: TipoDecisaoMediacao;
    texto: string;
    autorId: string;
    referenciasComandos?: string[];
    compartilharComPartes?: boolean;
  },
): Promise<{ caso: CasoMediacao; efeitoFinanceiroExecutado: false }> {
  const ref = db.collection(COL_CASOS).doc(texto(entrada.idCaso));
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Caso não encontrado.");
  }
  const caso = casoDeDoc(snap.id, snap.data()!);
  if (["fechado", "cancelado_caso"].includes(caso.estado)) {
    throw new HttpsError("failed-precondition", "Mediação encerrada: abra um novo caso para registrar outra decisão.");
  }
  if (!["manter", "recomendar_repasse", "recomendar_reembolso", "recomendar_cancelamento", "encaminhar", "arquivar"].includes(entrada.tipoDecisao) ||
      texto(entrada.texto).length < 10 || entrada.texto.length > 2000) {
    throw new HttpsError("invalid-argument", "Selecione a decisão e descreva a justificativa em 10 a 2000 caracteres.");
  }

  const agora = new Date().toISOString();
  const r = registrarDecisaoSemEfeitoFinanceiro({
    caso,
    tipoDecisao: entrada.tipoDecisao,
    texto: texto(entrada.texto),
    autorId: entrada.autorId,
    agoraIso: agora,
    referenciasComandos: entrada.referenciasComandos,
    compartilharComPartes: entrada.compartilharComPartes,
  });
  const batch = db.batch();
  batch.update(ref, {
    ...casoParaFirestore(r.caso),
    atualizado_em: FieldValue.serverTimestamp(),
  });
  batch.set(db.collection(COL_REGISTROS).doc(), {
    id_caso: r.registro.idCaso,
    tipo: r.registro.tipo,
    visibilidade: r.registro.visibilidade,
    texto: r.registro.texto,
    autor_id: r.registro.autorId,
    criado_em: r.registro.criadoEm,
    tipo_decisao: r.registro.tipoDecisao,
    referencias_comandos: r.registro.referenciasComandos ?? [],
    efeito_financeiro_executado: false,
  });
  await batch.commit();
  await auditar(db, {
    acao: "decisao",
    id_caso: caso.id,
    tipo_decisao: entrada.tipoDecisao,
    efeito_financeiro: false,
    autor_id: entrada.autorId,
  });
  return { caso: r.caso, efeitoFinanceiroExecutado: false };
}

export async function fecharCaso(
  db: Firestore,
  entrada: { idCaso: string; conclusao: string; autorId: string },
): Promise<{ caso: CasoMediacao; efeitosFinanceiros: [] }> {
  const ref = db.collection(COL_CASOS).doc(texto(entrada.idCaso));
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Caso não encontrado.");
  }
  if (snap.data()?.estado === "fechado") {
    return { caso: casoDeDoc(snap.id, snap.data()!), efeitosFinanceiros: [] };
  }
  if (texto(entrada.conclusao).length < 10 || entrada.conclusao.length > 2000) {
    throw new HttpsError("invalid-argument", "Descreva a conclusão em 10 a 2000 caracteres.");
  }
  const decisoes = await db.collection(COL_REGISTROS).where("id_caso", "==", ref.id).get();
  if (!decisoes.docs.some(d => d.data().tipo === "decisao")) {
    throw new HttpsError("failed-precondition", "Registre uma decisão antes de encerrar a mediação.");
  }
  const caso = casoDeDoc(snap.id, snap.data()!);
  const agora = new Date().toISOString();
  const r = fecharCasoSemMovimentoFinanceiro({
    caso,
    conclusao: entrada.conclusao,
    autorId: entrada.autorId,
    agoraIso: agora,
  });
  const batch = db.batch();
  batch.update(ref, {
    ...casoParaFirestore(r.caso),
    atualizado_em: FieldValue.serverTimestamp(),
  });
  batch.set(db.collection(COL_REGISTROS).doc(), {
    id_caso: r.registro.idCaso,
    tipo: r.registro.tipo,
    visibilidade: r.registro.visibilidade,
    texto: r.registro.texto,
    autor_id: r.registro.autorId,
    criado_em: r.registro.criadoEm,
    efeito_financeiro_executado: false,
  });
  await batch.commit();
  await auditar(db, {
    acao: "fechar_caso",
    id_caso: caso.id,
    efeitos_financeiros: [],
    autor_id: entrada.autorId,
  });
  return { caso: r.caso, efeitosFinanceiros: [] };
}

export async function recomendarBloqueio(
  db: Firestore,
  entrada: {
    idCaso: string;
    motivo: string;
    autorId: string;
    /** Sempre false nesta entrega — política de retenção não definida. */
    politicaRetencaoAtiva?: boolean;
  },
): Promise<{
  caso: CasoMediacao;
  retencaoAplicada: boolean;
  somenteRecomendacao: boolean;
  contratosNaoAfetadosDoEvento: string[];
}> {
  const ref = db.collection(COL_CASOS).doc(texto(entrada.idCaso));
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Caso não encontrado.");
  }
  const caso = casoDeDoc(snap.id, snap.data()!);
  const r = aplicarRecomendacaoBloqueio({
    caso,
    motivo: entrada.motivo,
    politicaRetencaoAtiva: entrada.politicaRetencaoAtiva === true,
    temCapacidadeAutorizacao: true,
  });

  // Outros contratos do mesmo evento não são afetados.
  const outros = await db
    .collection("orcamento")
    .where("id_evento", "==", caso.idEvento)
    .limit(100)
    .get();
  const idsOutros = outros.docs
    .map((d) => d.id)
    .filter((id) => id !== caso.idOrcamento && id !== caso.idContrato);

  const agora = new Date().toISOString();
  const batch = db.batch();
  batch.update(ref, {
    ...casoParaFirestore(r.caso),
    atualizado_em: FieldValue.serverTimestamp(),
  });
  batch.set(db.collection(COL_REGISTROS).doc(), {
    id_caso: caso.id,
    tipo: "recomendacao_bloqueio",
    visibilidade: "interna",
    texto: entrada.motivo,
    autor_id: entrada.autorId,
    criado_em: agora,
    efeito_financeiro_executado: false,
    retencao_aplicada: r.retencaoAplicada,
    somente_recomendacao: r.somenteRecomendacao,
    id_contrato_afetado: caso.idContrato,
  });
  await batch.commit();

  return {
    caso: r.caso,
    retencaoAplicada: r.retencaoAplicada,
    somenteRecomendacao: r.somenteRecomendacao,
    contratosNaoAfetadosDoEvento: idsOutros,
  };
}

export async function lerCasoMediacao(db: Firestore, idCaso: string): Promise<CasoMediacao> {
  const snap = await db.collection(COL_CASOS).doc(texto(idCaso)).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Caso não encontrado.");
  }
  return casoDeDoc(snap.id, snap.data()!);
}

export async function carregarRegistrosCaso(
  db: Firestore,
  entrada: {
    idCaso: string;
    papel: PapelConsultaMediacao;
    caps: CapacidadeMediacao[];
  },
): Promise<RegistroMediacao[]> {
  const regs = await db
    .collection(COL_REGISTROS)
    .where("id_caso", "==", entrada.idCaso)
    .limit(200)
    .get();
  const todos: RegistroMediacao[] = regs.docs.map((d) => {
    const x = d.data();
    return {
      id: d.id,
      idCaso: String(x.id_caso ?? ""),
      tipo: x.tipo as TipoRegistroMediacao,
      visibilidade: x.visibilidade as VisibilidadeRegistro,
      texto: String(x.texto ?? ""),
      autorId: String(x.autor_id ?? ""),
      criadoEm: String(x.criado_em ?? ""),
      tipoDecisao: (x.tipo_decisao as TipoDecisaoMediacao) || null,
      referenciasComandos: Array.isArray(x.referencias_comandos)
        ? (x.referencias_comandos as string[])
        : [],
      efeitoFinanceiroExecutado: x.efeito_financeiro_executado === true,
    };
  });
  todos.sort((a, b) => a.criadoEm.localeCompare(b.criadoEm));
  return filtrarRegistrosPorPapel(todos, entrada.papel, entrada.caps);
}

export async function listarCasosPorContratos(
  db: Firestore,
  idsContrato: string[],
): Promise<Map<string, CasoMediacao>> {
  const mapa = new Map<string, CasoMediacao>();
  const unicos = [...new Set(idsContrato.filter(Boolean))];
  const chunk = 30;
  const lotes: string[][] = [];
  for (let i = 0; i < unicos.length; i += chunk) {
    lotes.push(unicos.slice(i, i + chunk));
  }
  const resultados = await Promise.all(lotes.map(fatia => db
      .collection(COL_CASOS)
      .where("id_contrato", "in", fatia)
      .get()
      .catch(() => null)));
  for (const snap of resultados) {
    if (!snap) continue;
    for (const doc of snap.docs) {
      const c = casoDeDoc(doc.id, doc.data());
      if (
        c.estado === "fechado" ||
        c.estado === "cancelado_caso"
      ) {
        continue;
      }
      const atual = mapa.get(c.idContrato);
      if (!atual || c.abertoEm > atual.abertoEm) {
        mapa.set(c.idContrato, c);
      }
    }
  }
  return mapa;
}
