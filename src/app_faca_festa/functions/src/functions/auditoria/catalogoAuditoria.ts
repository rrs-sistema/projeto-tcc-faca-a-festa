export const AREAS_AUDITORIA = [
  "ACESSO",
  "USUARIO",
  "FORNECEDOR",
  "SERVICO",
  "CATALOGO",
  "EVENTO",
  "ORCAMENTO",
  "COTACAO",
  "SISTEMA",
] as const;

export const NIVEIS_AUDITORIA = ["CRITICAL", "ERROR", "WARN", "INFO"] as const;

export type AreaAuditoria = (typeof AREAS_AUDITORIA)[number];
export type NivelAuditoria = (typeof NIVEIS_AUDITORIA)[number];

export type DefinicaoAcaoAuditoria = {
  area: AreaAuditoria;
  nivel: NivelAuditoria;
  visivelFornecedor: boolean;
  somenteAdmin: boolean;
};

export const CATALOGO_ACOES_AUDITORIA: Record<string, DefinicaoAcaoAuditoria> = {
  USUARIO_CRIADO: {
    area: "USUARIO",
    nivel: "INFO",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  USUARIO_TIPO_ALTERADO: {
    area: "USUARIO",
    nivel: "WARN",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  USUARIO_STATUS_ALTERADO: {
    area: "USUARIO",
    nivel: "WARN",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  FORNECEDOR_APROVADO: {
    area: "FORNECEDOR",
    nivel: "INFO",
    visivelFornecedor: true,
    somenteAdmin: true,
  },
  FORNECEDOR_REPROVADO: {
    area: "FORNECEDOR",
    nivel: "WARN",
    visivelFornecedor: true,
    somenteAdmin: true,
  },
  FORNECEDOR_ATIVADO: {
    area: "FORNECEDOR",
    nivel: "INFO",
    visivelFornecedor: true,
    somenteAdmin: true,
  },
  FORNECEDOR_DESATIVADO: {
    area: "FORNECEDOR",
    nivel: "WARN",
    visivelFornecedor: true,
    somenteAdmin: true,
  },
  FORNECEDOR_EDITADO: {
    area: "FORNECEDOR",
    nivel: "INFO",
    visivelFornecedor: true,
    somenteAdmin: false,
  },
  SERVICO_CATALOGO_SALVO: {
    area: "CATALOGO",
    nivel: "INFO",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  SERVICO_CATALOGO_EXCLUIDO: {
    area: "CATALOGO",
    nivel: "WARN",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  CATEGORIA_SALVA: {
    area: "CATALOGO",
    nivel: "INFO",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  CATEGORIA_EXCLUIDA: {
    area: "CATALOGO",
    nivel: "WARN",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  SERVICO_FORNECEDOR_SALVO: {
    area: "SERVICO",
    nivel: "INFO",
    visivelFornecedor: true,
    somenteAdmin: false,
  },
  SERVICO_FORNECEDOR_EXCLUIDO: {
    area: "SERVICO",
    nivel: "WARN",
    visivelFornecedor: true,
    somenteAdmin: false,
  },
  EVENTO_APROVADO: {
    area: "EVENTO",
    nivel: "INFO",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  EVENTO_EXCLUIDO: {
    area: "EVENTO",
    nivel: "WARN",
    visivelFornecedor: false,
    somenteAdmin: true,
  },
  ORCAMENTO_RESPONDIDO: {
    area: "ORCAMENTO",
    nivel: "INFO",
    visivelFornecedor: true,
    somenteAdmin: false,
  },
  ORCAMENTO_EXCLUIDO: {
    area: "ORCAMENTO",
    nivel: "WARN",
    visivelFornecedor: true,
    somenteAdmin: false,
  },
  COTACAO_RESPONDIDA: {
    area: "COTACAO",
    nivel: "INFO",
    visivelFornecedor: true,
    somenteAdmin: false,
  },
};

export const ACAO_PADRAO: DefinicaoAcaoAuditoria = {
  area: "SISTEMA",
  nivel: "INFO",
  visivelFornecedor: false,
  somenteAdmin: false,
};

export function definirAcao(acao: string): DefinicaoAcaoAuditoria {
  return CATALOGO_ACOES_AUDITORIA[acao] ?? ACAO_PADRAO;
}
