import type {AuditTrailOperation} from "./auditTrailService";

type AuditData = Record<string, unknown> | undefined;

function text(value: unknown): string | null {
  const normalized = String(value ?? "").trim();
  return normalized.length > 0 ? normalized : null;
}

function boolField(data: AuditData, fields: string[]): boolean | null {
  for (const field of fields) {
    const value = data?.[field];
    if (typeof value === "boolean") return value;
    if (typeof value === "string") {
      const normalized = value.trim().toLowerCase();
      if (["true", "sim", "1", "ativo", "aprovado"].includes(normalized)) {
        return true;
      }
      if (["false", "nao", "não", "0", "inativo", "reprovado"].includes(normalized)) {
        return false;
      }
    }
  }
  return null;
}

function stringField(data: AuditData, fields: string[]): string | null {
  for (const field of fields) {
    const value = text(data?.[field]);
    if (value) return value.toLowerCase();
  }
  return null;
}

export function resolverAcaoUsuario(
  operation: AuditTrailOperation,
  before: AuditData,
  after: AuditData,
): string {
  if (operation !== "updated") return {
    created: "USUARIO_CRIADO",
    updated: "USUARIO_ATUALIZADO",
    deleted: "USUARIO_EXCLUIDO",
  }[operation];

  if (text(before?.tipo) !== text(after?.tipo)) {
    return "USUARIO_TIPO_ALTERADO";
  }

  const ativoAntes = boolField(before, ["ativo", "active"]);
  const ativoDepois = boolField(after, ["ativo", "active"]);
  if (ativoAntes !== ativoDepois) {
    return "USUARIO_STATUS_ALTERADO";
  }

  return "USUARIO_ATUALIZADO";
}

export function resolverAcaoFornecedor(
  operation: AuditTrailOperation,
  before: AuditData,
  after: AuditData,
): string {
  if (operation !== "updated") return {
    created: "FORNECEDOR_CRIADO",
    updated: "FORNECEDOR_ATUALIZADO",
    deleted: "FORNECEDOR_EXCLUIDO",
  }[operation];

  const aptoAntes = boolField(before, ["apto_para_operar", "aptoParaOperar"]);
  const aptoDepois = boolField(after, ["apto_para_operar", "aptoParaOperar"]);
  if (aptoAntes === false && aptoDepois === true) {
    return "FORNECEDOR_APROVADO";
  }
  if (aptoAntes === true && aptoDepois === false) {
    return "FORNECEDOR_REPROVADO";
  }

  const ativoAntes = boolField(before, ["ativo", "active"]);
  const ativoDepois = boolField(after, ["ativo", "active"]);
  if (ativoAntes === false && ativoDepois === true) {
    return "FORNECEDOR_ATIVADO";
  }
  if (ativoAntes === true && ativoDepois === false) {
    return "FORNECEDOR_DESATIVADO";
  }

  return "FORNECEDOR_ATUALIZADO";
}

export function resolverAcaoEvento(
  operation: AuditTrailOperation,
  before: AuditData,
  after: AuditData,
): string {
  if (operation !== "updated") return {
    created: "EVENTO_CRIADO",
    updated: "EVENTO_ATUALIZADO",
    deleted: "EVENTO_EXCLUIDO",
  }[operation];

  const aprovadoAntes = boolField(before, ["aprovado", "approved"]);
  const aprovadoDepois = boolField(after, ["aprovado", "approved"]);
  if (aprovadoAntes !== true && aprovadoDepois === true) {
    return "EVENTO_APROVADO";
  }

  return "EVENTO_ATUALIZADO";
}

export function resolverAcaoOrcamento(
  operation: AuditTrailOperation,
  before: AuditData,
  after: AuditData,
): string {
  if (operation !== "updated") return {
    created: "ORCAMENTO_CRIADO",
    updated: "ORCAMENTO_ATUALIZADO",
    deleted: "ORCAMENTO_EXCLUIDO",
  }[operation];

  const statusAntes = stringField(before, ["status", "situacao"]);
  const statusDepois = stringField(after, ["status", "situacao"]);
  const fechadoAntes = boolField(before, ["orcamento_fechado", "orcamentoFechado"]);
  const fechadoDepois = boolField(after, ["orcamento_fechado", "orcamentoFechado"]);
  const statusMudouParaFechado =
    statusDepois === "fechado" && statusAntes !== statusDepois;
  const flagMudouParaFechado =
    fechadoAntes !== true && fechadoDepois === true;

  if (statusMudouParaFechado || flagMudouParaFechado) {
    return "ORCAMENTO_FECHADO";
  }

  if (statusDepois === "cancelado" && statusAntes !== statusDepois) {
    return "ORCAMENTO_CANCELADO";
  }

  if (statusDepois === "em_negociacao" && statusAntes !== statusDepois) {
    return "ORCAMENTO_RESPONDIDO";
  }

  return "ORCAMENTO_ATUALIZADO";
}

export function resolverAcaoCotacao(
  operation: AuditTrailOperation,
  before: AuditData,
  after: AuditData,
): string {
  if (operation !== "updated") return {
    created: "COTACAO_CRIADA",
    updated: "COTACAO_ATUALIZADA",
    deleted: "COTACAO_EXCLUIDA",
  }[operation];

  const statusAntes = stringField(before, ["status", "situacao"]);
  const statusDepois = stringField(after, ["status", "situacao"]);
  if (statusAntes === statusDepois) return "COTACAO_ATUALIZADA";

  if (statusDepois === "concluida" || statusDepois === "fechado") {
    return "COTACAO_FECHADA";
  }

  if (
    statusDepois === "cancelada" ||
    statusDepois === "perdeucotacao" ||
    statusDepois === "recusado"
  ) {
    return "COTACAO_CANCELADA";
  }

  if (statusDepois === "respondida" || statusDepois === "parcial") {
    return "COTACAO_RESPONDIDA";
  }

  return "COTACAO_ATUALIZADA";
}

export function resolverAcaoCotacaoFornecedor(
  operation: AuditTrailOperation,
  before: AuditData,
  after: AuditData,
): string {
  if (operation !== "updated") return {
    created: "COTACAO_FORNECEDOR_CRIADA",
    updated: "COTACAO_FORNECEDOR_ATUALIZADA",
    deleted: "COTACAO_FORNECEDOR_EXCLUIDA",
  }[operation];

  const statusAntes = stringField(before, ["status", "situacao"]);
  const statusDepois = stringField(after, ["status", "situacao"]);
  if (statusAntes === statusDepois) return "COTACAO_FORNECEDOR_ATUALIZADA";

  if (statusDepois === "respondido" || statusDepois === "respondida") {
    return "COTACAO_RESPONDIDA";
  }

  if (statusDepois === "fechado" || statusDepois === "concluida") {
    return "COTACAO_FECHADA";
  }

  if (
    statusDepois === "cancelada" ||
    statusDepois === "perdeucotacao" ||
    statusDepois === "recusado"
  ) {
    return "COTACAO_CANCELADA";
  }

  return "COTACAO_FORNECEDOR_ATUALIZADA";
}
