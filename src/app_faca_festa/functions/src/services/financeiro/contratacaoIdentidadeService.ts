/**
 * Identidade comercial da contratação (Prompt 01 — mediação).
 * Papéis explícitos; snapshot no aceite ≠ perfil atual.
 * Não inventa nomes; marca pendência quando faltar vínculo confiável.
 */

export type EstadoExecucaoContrato =
  | "nao_iniciado"
  | "agendado"
  | "em_execucao"
  | "entrega_informada"
  | "aceito"
  | "contestado"
  | "cancelado_execucao";

export type PendenciaIdentificacao =
  | "evento"
  | "organizador"
  | "contratante"
  | "pagador"
  | "fornecedor"
  | "servico";

export type SnapshotIdentidadeComercial = {
  schema: 1;
  origem: string;
  capturado_em: string;
  id_evento: string;
  nome_evento: string | null;
  id_organizador: string | null;
  nome_organizador: string | null;
  id_contratante: string | null;
  nome_contratante: string | null;
  id_pagador: string | null;
  nome_pagador: string | null;
  id_fornecedor: string | null;
  nome_fornecedor: string | null;
  id_servico: string | null;
  nome_servico: string | null;
  descricao_escopo: string | null;
  quantidade: number | null;
  unidade: string | null;
  valor_centavos: number | null;
  id_operador_acompanhamento: string | null;
};

export type LinhaContratacaoAdmin = {
  id_contrato: string;
  id_orcamento: string;
  id_evento: string;
  nome_evento: string | null;
  id_organizador: string | null;
  nome_organizador: string | null;
  id_contratante: string | null;
  nome_contratante: string | null;
  id_pagador: string | null;
  nome_pagador: string | null;
  id_fornecedor: string | null;
  nome_fornecedor: string | null;
  id_servico: string | null;
  nome_servico: string | null;
  descricao_escopo: string | null;
  estado_comercial: string;
  estado_execucao: EstadoExecucaoContrato;
  contratado: boolean;
  valor_contratado_centavos: number;
  pago_centavos: number;
  pendencias_identificacao: PendenciaIdentificacao[];
  identidade_incompleta: boolean;
  snapshot_aceite: SnapshotIdentidadeComercial | null;
  perfil_atual_separado: boolean;
  nome_fornecedor_atual: string | null;
  origem_identidade: "snapshot" | "documento" | "enriquecimento" | "ausente";
};

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function nomeDeUsuario(data: Record<string, unknown> | null | undefined): string | null {
  if (!data) return null;
  const n =
    texto(data.nome) ||
    texto(data.nome_completo) ||
    texto(data.nomeCompleto) ||
    texto(data.display_name);
  return n || null;
}

function nomeDeFornecedor(
  data: Record<string, unknown> | null | undefined,
): string | null {
  if (!data) return null;
  const n =
    texto(data.nome_fornecedor) ||
    texto(data.nomeFantasia) ||
    texto(data.nome_fantasia) ||
    texto(data.razao_social) ||
    texto(data.nome);
  return n || null;
}

function nomeDeEvento(data: Record<string, unknown> | null | undefined): string | null {
  if (!data) return null;
  const n =
    texto(data.nome_evento) ||
    texto(data.nomeEvento) ||
    texto(data.titulo) ||
    texto(data.nome);
  return n || null;
}

export function parseEstadoExecucao(v: unknown): EstadoExecucaoContrato {
  const s = texto(v).toLowerCase();
  switch (s) {
    case "agendado":
    case "em_execucao":
    case "entrega_informada":
    case "aceito":
    case "contestado":
    case "cancelado_execucao":
      return s;
    case "nao_iniciado":
    default:
      return "nao_iniciado";
  }
}

export function rotuloEstadoExecucao(e: EstadoExecucaoContrato): string {
  switch (e) {
    case "agendado":
      return "Agendado";
    case "em_execucao":
      return "Em execução";
    case "entrega_informada":
      return "Entrega informada";
    case "aceito":
      return "Aceito";
    case "contestado":
      return "Contestado";
    case "cancelado_execucao":
      return "Execução cancelada";
    default:
      return "Execução não iniciada";
  }
}

export function rotuloEstadoComercial(contratado: boolean, status: string): string {
  const s = status.toLowerCase();
  if (s.includes("cancel")) return "Cancelado";
  if (contratado) return "Contratado";
  if (s.includes("negoci") || s.includes("cotad")) return "Em negociação";
  return "Oportunidade";
}

/**
 * Monta snapshot no aceite a partir de vínculos confiáveis já conhecidos.
 * Não preenche por semelhança; campos ausentes ficam null.
 */
export function montarSnapshotAceite(params: {
  origem: string;
  capturadoEm?: string;
  idEvento: string;
  nomeEvento?: string | null;
  idOrganizador?: string | null;
  nomeOrganizador?: string | null;
  idContratante?: string | null;
  nomeContratante?: string | null;
  idPagador?: string | null;
  nomePagador?: string | null;
  idFornecedor?: string | null;
  nomeFornecedor?: string | null;
  idServico?: string | null;
  nomeServico?: string | null;
  descricaoEscopo?: string | null;
  quantidade?: number | null;
  unidade?: string | null;
  valorCentavos?: number | null;
  idOperadorAcompanhamento?: string | null;
}): SnapshotIdentidadeComercial {
  return {
    schema: 1,
    origem: params.origem,
    capturado_em: params.capturadoEm ?? new Date().toISOString(),
    id_evento: params.idEvento,
    nome_evento: params.nomeEvento ?? null,
    id_organizador: params.idOrganizador ?? null,
    nome_organizador: params.nomeOrganizador ?? null,
    id_contratante: params.idContratante ?? null,
    nome_contratante: params.nomeContratante ?? null,
    id_pagador: params.idPagador ?? null,
    nome_pagador: params.nomePagador ?? null,
    id_fornecedor: params.idFornecedor ?? null,
    nome_fornecedor: params.nomeFornecedor ?? null,
    id_servico: params.idServico ?? null,
    nome_servico: params.nomeServico ?? null,
    descricao_escopo: params.descricaoEscopo ?? null,
    quantidade: params.quantidade ?? null,
    unidade: params.unidade ?? null,
    valor_centavos: params.valorCentavos ?? null,
    id_operador_acompanhamento: params.idOperadorAcompanhamento ?? null,
  };
}

export function avaliarPendencias(p: {
  idEvento: string;
  nomeEvento: string | null;
  idOrganizador: string | null;
  nomeOrganizador: string | null;
  idContratante: string | null;
  nomeContratante: string | null;
  idPagador: string | null;
  nomePagador: string | null;
  idFornecedor: string | null;
  nomeFornecedor: string | null;
  idServico: string | null;
  nomeServico: string | null;
  contratado: boolean;
}): PendenciaIdentificacao[] {
  const out: PendenciaIdentificacao[] = [];
  if (!p.idEvento || !p.nomeEvento) out.push("evento");
  if (!p.idOrganizador || !p.nomeOrganizador) out.push("organizador");
  if (!p.idContratante || !p.nomeContratante) out.push("contratante");
  // Pagador pode coincidir com contratante; só exige se houver id sem nome.
  if (p.idPagador && !p.nomePagador) out.push("pagador");
  if (p.contratado && (!p.idFornecedor || !p.nomeFornecedor)) {
    out.push("fornecedor");
  }
  if (p.contratado && !p.nomeServico && !p.idServico) out.push("servico");
  return out;
}

export function lerSnapshotDeContrato(
  contrato: Record<string, unknown> | null | undefined,
): SnapshotIdentidadeComercial | null {
  if (!contrato) return null;
  const raw = contrato.snapshot_identidade ?? contrato.snapshotIdentidade;
  if (!raw || typeof raw !== "object") return null;
  const s = raw as Record<string, unknown>;
  if (!texto(s.id_evento)) return null;
  return {
    schema: 1,
    origem: texto(s.origem) || "desconhecida",
    capturado_em: texto(s.capturado_em) || "",
    id_evento: texto(s.id_evento),
    nome_evento: texto(s.nome_evento) || null,
    id_organizador: texto(s.id_organizador) || null,
    nome_organizador: texto(s.nome_organizador) || null,
    id_contratante: texto(s.id_contratante) || null,
    nome_contratante: texto(s.nome_contratante) || null,
    id_pagador: texto(s.id_pagador) || null,
    nome_pagador: texto(s.nome_pagador) || null,
    id_fornecedor: texto(s.id_fornecedor) || null,
    nome_fornecedor: texto(s.nome_fornecedor) || null,
    id_servico: texto(s.id_servico) || null,
    nome_servico: texto(s.nome_servico) || null,
    descricao_escopo: texto(s.descricao_escopo) || null,
    quantidade: typeof s.quantidade === "number" ? s.quantidade : null,
    unidade: texto(s.unidade) || null,
    valor_centavos: typeof s.valor_centavos === "number" ? s.valor_centavos : null,
    id_operador_acompanhamento: texto(s.id_operador_acompanhamento) || null,
  };
}

/**
 * Resolve identidade para admin: prefer snapshot do aceite;
 * completa com perfil atual sem reescrever o histórico.
 */
export function resolverLinhaContratacao(params: {
  idOrcamento: string;
  orcamento: Record<string, unknown>;
  evento?: Record<string, unknown> | null;
  organizador?: Record<string, unknown> | null;
  contratante?: Record<string, unknown> | null;
  pagador?: Record<string, unknown> | null;
  fornecedor?: Record<string, unknown> | null;
  valorContratadoCentavos: number;
  pagoCentavos: number;
  contratado: boolean;
}): LinhaContratacaoAdmin {
  const d = params.orcamento;
  const contrato =
    d.contrato_financeiro && typeof d.contrato_financeiro === "object"
      ? (d.contrato_financeiro as Record<string, unknown>)
      : null;
  const snap = lerSnapshotDeContrato(contrato);

  const idEvento = texto(d.id_evento) || snap?.id_evento || "";
  const idFornecedor =
    texto(d.id_fornecedor) || snap?.id_fornecedor || null;
  const idSolicitante = texto(d.id_solicitante) || null;
  const idOrganizador =
    texto(params.evento?.id_usuario) ||
    texto(params.evento?.idUsuario) ||
    snap?.id_organizador ||
    null;
  const idContratante =
    snap?.id_contratante || idSolicitante || idOrganizador;
  const idPagador =
    texto(d.id_pagador) ||
    snap?.id_pagador ||
    idContratante;

  const nomeEventoSnap = snap?.nome_evento ?? null;
  const nomeEventoAtual = nomeDeEvento(params.evento);
  const nomeOrganizadorAtual = nomeDeUsuario(params.organizador);
  const nomeContratanteAtual =
    nomeDeUsuario(params.contratante) ||
    texto(d.nome_solicitante) ||
    null;
  const nomePagadorAtual = nomeDeUsuario(params.pagador);
  const nomeFornecedorAtual =
    nomeDeFornecedor(params.fornecedor) ||
    texto(d.nome_fornecedor) ||
    null;
  const nomeServicoDoc =
    texto(d.nome) ||
    texto(d.nome_servico) ||
    texto(d.anotacoes) ||
    null;
  const idServico =
    texto(d.id_servico_fornecido) ||
    texto(d.id_servico) ||
    snap?.id_servico ||
    null;

  // Preferência: snapshot (época do aceite) para identidades comerciais.
  const nomeEvento = nomeEventoSnap || nomeEventoAtual;
  const nomeOrganizador = snap?.nome_organizador || nomeOrganizadorAtual;
  const nomeContratante = snap?.nome_contratante || nomeContratanteAtual;
  const nomePagador = snap?.nome_pagador || nomePagadorAtual || nomeContratante;
  const nomeFornecedor = snap?.nome_fornecedor || nomeFornecedorAtual;
  const nomeServico = snap?.nome_servico || nomeServicoDoc;

  const perfilAtualSeparado =
    snap != null &&
    ((nomeFornecedorAtual != null &&
      snap.nome_fornecedor != null &&
      nomeFornecedorAtual !== snap.nome_fornecedor) ||
      (nomeEventoAtual != null &&
        snap.nome_evento != null &&
        nomeEventoAtual !== snap.nome_evento));

  const estadoComercialRaw = texto(contrato?.estado_comercial) || texto(d.status);
  const estadoExecucao = parseEstadoExecucao(
    d.estado_execucao ?? contrato?.estado_execucao ?? "nao_iniciado",
  );

  const pendencias = avaliarPendencias({
    idEvento,
    nomeEvento,
    idOrganizador,
    nomeOrganizador,
    idContratante,
    nomeContratante,
    idPagador,
    nomePagador,
    idFornecedor,
    nomeFornecedor,
    idServico,
    nomeServico,
    contratado: params.contratado,
  });

  let origem: LinhaContratacaoAdmin["origem_identidade"] = "ausente";
  if (snap) origem = "snapshot";
  else if (nomeEvento || nomeFornecedor || nomeContratante) {
    origem = params.evento || params.fornecedor ? "enriquecimento" : "documento";
  }

  return {
    id_contrato: texto(contrato?.id_contrato) || params.idOrcamento,
    id_orcamento: params.idOrcamento,
    id_evento: idEvento,
    nome_evento: nomeEvento,
    id_organizador: idOrganizador,
    nome_organizador: nomeOrganizador,
    id_contratante: idContratante,
    nome_contratante: nomeContratante,
    id_pagador: idPagador,
    nome_pagador: nomePagador,
    id_fornecedor: idFornecedor,
    nome_fornecedor: nomeFornecedor,
    id_servico: idServico,
    nome_servico: nomeServico,
    descricao_escopo: snap?.descricao_escopo || nomeServicoDoc,
    estado_comercial: rotuloEstadoComercial(params.contratado, estadoComercialRaw),
    estado_execucao: estadoExecucao,
    contratado: params.contratado,
    valor_contratado_centavos: params.contratado
      ? params.valorContratadoCentavos
      : 0,
    pago_centavos: params.contratado ? params.pagoCentavos : 0,
    pendencias_identificacao: pendencias,
    identidade_incompleta: pendencias.length > 0,
    snapshot_aceite: snap,
    perfil_atual_separado: perfilAtualSeparado,
    nome_fornecedor_atual: nomeFornecedorAtual,
    origem_identidade: origem,
  };
}

export function nomeUsuarioDeDoc(
  data: Record<string, unknown> | null | undefined,
): string | null {
  return nomeDeUsuario(data);
}

export function nomeFornecedorDeDoc(
  data: Record<string, unknown> | null | undefined,
): string | null {
  return nomeDeFornecedor(data);
}

export function nomeEventoDeDoc(
  data: Record<string, unknown> | null | undefined,
): string | null {
  return nomeDeEvento(data);
}
