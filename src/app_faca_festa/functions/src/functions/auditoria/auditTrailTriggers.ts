import {
  onDocumentWrittenWithAuthContext,
  type FirestoreAuthEvent,
  type Change,
  type DocumentSnapshot,
} from "firebase-functions/v2/firestore";

import {
  firstRelevantText,
  registrarAuditTrail,
  type AuditTrailOperation,
} from "./auditTrailService";
import { admin } from "../../shared/firebaseAdmin";
import {
  resolverAcaoCotacao,
  resolverAcaoCotacaoFornecedor,
  resolverAcaoEvento,
  resolverAcaoFornecedor,
  resolverAcaoOrcamento,
  resolverAcaoUsuario,
} from "./auditActionResolvers";

const REGION = "southamerica-east1";

type WrittenEvent = FirestoreAuthEvent<
  Change<DocumentSnapshot> | undefined,
  Record<string, string>
>;

type AuditConfig = {
  document: string;
  entidadeTipo: string;
  nomeCampos: string[];
  acoes: Record<AuditTrailOperation, string>;
  acao?: (
    operation: AuditTrailOperation,
    before: Record<string, unknown> | undefined,
    after: Record<string, unknown> | undefined,
  ) => string;
  idFornecedor?: (
    id: string,
    data: Record<string, unknown> | undefined,
    params: Record<string, string>,
  ) => string | null;
  idEvento?: (
    id: string,
    data: Record<string, unknown> | undefined,
    params: Record<string, string>,
  ) => string | null;
  idServico?: (
    id: string,
    data: Record<string, unknown> | undefined,
    params: Record<string, string>,
  ) => string | null;
  idCotacao?: (
    id: string,
    data: Record<string, unknown> | undefined,
    params: Record<string, string>,
  ) => string | null;
  idOrcamento?: (
    id: string,
    data: Record<string, unknown> | undefined,
    params: Record<string, string>,
  ) => string | null;
  relatedIds?: (
    id: string,
    data: Record<string, unknown> | undefined,
    params: Record<string, string>,
  ) => Promise<{
    idFornecedor?: string | null;
    idEvento?: string | null;
    idServico?: string | null;
    idCotacao?: string | null;
    idOrcamento?: string | null;
  }>;
};

function asData(snapshot: DocumentSnapshot | undefined): Record<string, unknown> | undefined {
  return snapshot?.data() as Record<string, unknown> | undefined;
}

function text(value: unknown): string | null {
  const normalized = String(value ?? "").trim();
  return normalized.length > 0 ? normalized : null;
}

function firstId(
  id: string,
  data: Record<string, unknown> | undefined,
  fields: string[],
): string | null {
  return firstRelevantText(data, fields) ?? text(id);
}

function operationFromEvent(event: WrittenEvent): AuditTrailOperation | null {
  const beforeExists = event.data?.before.exists ?? false;
  const afterExists = event.data?.after.exists ?? false;

  if (!beforeExists && afterExists) return "created";
  if (beforeExists && afterExists) return "updated";
  if (beforeExists && !afterExists) return "deleted";
  return null;
}

function createAuditTrigger(config: AuditConfig) {
  return onDocumentWrittenWithAuthContext(
    {
      document: config.document,
      region: REGION,
      timeoutSeconds: 60,
      memory: "256MiB",
    },
    async (event: WrittenEvent) => {
      const operation = operationFromEvent(event);
      if (!operation) return;

      const after = asData(event.data?.after);
      const before = asData(event.data?.before);
      const current = after ?? before;
      const id = text(event.params.id) ?? text(event.params.idUsuario) ??
        text(event.params.idFornecedor) ?? text(event.params.idEvento) ??
        text(event.params.idOrcamento) ?? text(event.params.idCotacao) ??
        text(event.params.idServico) ?? "sem-id";
      const relatedIds = await config.relatedIds?.(id, current, event.params);

      await registrarAuditTrail({
        acao: config.acao?.(operation, before, after) ?? config.acoes[operation],
        operacao: operation,
        entidadeTipo: config.entidadeTipo,
        entidadeId: id,
        entidadeNome: firstRelevantText(current, config.nomeCampos),
        before,
        after,
        actorUid: event.authId ?? null,
        actorAuthType: event.authType ?? "unknown",
        documentPath: event.document,
        sourceEventId: event.id,
        idFornecedor: config.idFornecedor?.(id, current, event.params) ??
          relatedIds?.idFornecedor ?? null,
        idEvento: config.idEvento?.(id, current, event.params) ??
          relatedIds?.idEvento ?? null,
        idServico: config.idServico?.(id, current, event.params) ??
          relatedIds?.idServico ?? null,
        idCotacao: config.idCotacao?.(id, current, event.params) ??
          relatedIds?.idCotacao ?? null,
        idOrcamento: config.idOrcamento?.(id, current, event.params) ??
          relatedIds?.idOrcamento ?? null,
      });
    },
  );
}

async function relatedIdsFromOrcamentoPai(
  _id: string,
  data: Record<string, unknown> | undefined,
  params: Record<string, string>,
) {
  const idOrcamento = text(params.idOrcamento) ??
    firstRelevantText(data, ["id_orcamento", "idOrcamento"]);
  if (!idOrcamento) return {};

  const snapshot = await admin.firestore()
    .collection("orcamento")
    .doc(idOrcamento)
    .get();
  const orcamento = snapshot.data() as Record<string, unknown> | undefined;

  return {
    idEvento: firstRelevantText(orcamento, ["id_evento", "idEvento"]),
    idFornecedor: firstRelevantText(
      orcamento,
      ["id_fornecedor", "idFornecedor"],
    ),
    idOrcamento,
  };
}

async function relatedIdsFromEventoPai(
  _id: string,
  _data: Record<string, unknown> | undefined,
  params: Record<string, string>,
) {
  return {
    idEvento: text(params.idEvento),
  };
}

async function relatedIdsFromCardapioPai(
  _id: string,
  _data: Record<string, unknown> | undefined,
  params: Record<string, string>,
) {
  const idCardapio = text(params.idCardapio);
  if (!idCardapio) return {};

  const snapshot = await admin.firestore()
    .collection("cardapios")
    .doc(idCardapio)
    .get();
  const cardapio = snapshot.data() as Record<string, unknown> | undefined;

  return {
    idEvento: firstRelevantText(cardapio, ["id_evento", "idEvento"]),
  };
}

async function relatedIdsFromPresentePai(
  _id: string,
  _data: Record<string, unknown> | undefined,
  params: Record<string, string>,
) {
  return {
    idEvento: text(params.idEvento),
  };
}

async function relatedIdsFromFornecedorServicoPai(
  _id: string,
  data: Record<string, unknown> | undefined,
  params: Record<string, string>,
) {
  const idServico = text(params.idServico) ??
    firstRelevantText(data, ["id_servico", "idServico"]);
  if (!idServico) return {};

  const snapshot = await admin.firestore()
    .collection("fornecedor_servico")
    .doc(idServico)
    .get();
  const servico = snapshot.data() as Record<string, unknown> | undefined;

  return {
    idFornecedor: firstRelevantText(servico, ["id_fornecedor", "idFornecedor"]),
    idServico: firstRelevantText(
      servico,
      ["id_produto_servico", "idProdutoServico", "id_servico", "idServico"],
    ) ?? idServico,
  };
}

async function relatedIdsFromCotacaoPai(
  _id: string,
  _data: Record<string, unknown> | undefined,
  params: Record<string, string>,
) {
  const idCotacao = text(params.idCotacao);
  if (!idCotacao) return {};

  const snapshot = await admin.firestore()
    .collection("cotacao")
    .doc(idCotacao)
    .get();
  const cotacao = snapshot.data() as Record<string, unknown> | undefined;

  return {
    idCotacao,
    idEvento: firstRelevantText(cotacao, ["id_evento", "idEvento"]),
    idFornecedor: text(params.idFornecedor),
  };
}

async function relatedIdsFromCalculadoraPai(
  _id: string,
  data: Record<string, unknown> | undefined,
  params: Record<string, string>,
) {
  const idCalculo = text(params.idCalculo);
  const fromChild = {
    idEvento: firstRelevantText(data, ["id_evento", "idEvento"]),
  };
  if (!idCalculo || fromChild.idEvento) return fromChild;

  const snapshot = await admin.firestore()
    .collection("calculadora_festa")
    .doc(idCalculo)
    .get();
  const calculo = snapshot.data() as Record<string, unknown> | undefined;

  return {
    idEvento: firstRelevantText(calculo, ["id_evento", "idEvento"]),
  };
}

export const auditarUsuarios = createAuditTrigger({
  document: "usuarios/{id}",
  entidadeTipo: "usuario",
  nomeCampos: ["nome", "email", "displayName"],
  acoes: {
    created: "USUARIO_CRIADO",
    updated: "USUARIO_ATUALIZADO",
    deleted: "USUARIO_EXCLUIDO",
  },
  acao: resolverAcaoUsuario,
});

export const auditarFornecedores = createAuditTrigger({
  document: "fornecedor/{id}",
  entidadeTipo: "fornecedor",
  nomeCampos: ["nome_fantasia", "nomeFantasia", "razao_social", "razaoSocial"],
  acoes: {
    created: "FORNECEDOR_CRIADO",
    updated: "FORNECEDOR_ATUALIZADO",
    deleted: "FORNECEDOR_EXCLUIDO",
  },
  acao: resolverAcaoFornecedor,
  idFornecedor: (id, data) => firstId(
    id,
    data,
    ["id_fornecedor", "idFornecedor", "id_usuario", "idUsuario"],
  ),
});

export const auditarServicosFornecedor = createAuditTrigger({
  document: "fornecedor_servico/{id}",
  entidadeTipo: "fornecedor_servico",
  nomeCampos: ["nome", "nome_servico", "nomeServico", "titulo"],
  acoes: {
    created: "SERVICO_FORNECEDOR_CRIADO",
    updated: "SERVICO_FORNECEDOR_ATUALIZADO",
    deleted: "SERVICO_FORNECEDOR_EXCLUIDO",
  },
  idFornecedor: (_id, data) => firstRelevantText(data, ["id_fornecedor", "idFornecedor"]),
  idServico: (id, data) => firstId(id, data, ["id_servico", "idServico", "id"]),
});

export const auditarTerritoriosFornecedor = createAuditTrigger({
  document: "territorio/{id}",
  entidadeTipo: "territorio",
  nomeCampos: ["descricao", "tipo_cobertura", "tipoCobertura"],
  acoes: {
    created: "TERRITORIO_CRIADO",
    updated: "TERRITORIO_ATUALIZADO",
    deleted: "TERRITORIO_EXCLUIDO",
  },
  idFornecedor: (_id, data) => firstRelevantText(data, ["id_fornecedor", "idFornecedor"]),
});

export const auditarCatalogoServicos = createAuditTrigger({
  document: "servico_produto/{id}",
  entidadeTipo: "servico_produto",
  nomeCampos: ["nome", "titulo", "descricao"],
  acoes: {
    created: "SERVICO_CATALOGO_CRIADO",
    updated: "SERVICO_CATALOGO_ATUALIZADO",
    deleted: "SERVICO_CATALOGO_EXCLUIDO",
  },
  idServico: (id, data) => firstId(
    id,
    data,
    ["id_servico_produto", "idServicoProduto", "id"],
  ),
});

export const auditarCategoriasServico = createAuditTrigger({
  document: "categoria_servico/{id}",
  entidadeTipo: "categoria_servico",
  nomeCampos: ["nome", "descricao"],
  acoes: {
    created: "CATEGORIA_CRIADA",
    updated: "CATEGORIA_ATUALIZADA",
    deleted: "CATEGORIA_EXCLUIDA",
  },
});

export const auditarSubcategoriasServico = createAuditTrigger({
  document: "subcategoria_servico/{id}",
  entidadeTipo: "subcategoria_servico",
  nomeCampos: ["nome", "descricao"],
  acoes: {
    created: "SUBCATEGORIA_CRIADA",
    updated: "SUBCATEGORIA_ATUALIZADA",
    deleted: "SUBCATEGORIA_EXCLUIDA",
  },
});

export const auditarEventos = createAuditTrigger({
  document: "evento/{id}",
  entidadeTipo: "evento",
  nomeCampos: ["nome_evento", "nomeEvento", "nome", "titulo"],
  acoes: {
    created: "EVENTO_CRIADO",
    updated: "EVENTO_ATUALIZADO",
    deleted: "EVENTO_EXCLUIDO",
  },
  acao: resolverAcaoEvento,
  idEvento: (id, data) => firstId(id, data, ["id_evento", "idEvento", "id"]),
});

export const auditarEnderecosUsuario = createAuditTrigger({
  document: "usuarios/{idUsuario}/enderecos/{id}",
  entidadeTipo: "usuario_endereco",
  nomeCampos: ["apelido", "logradouro", "cidade", "nome_cidade"],
  acoes: {
    created: "USUARIO_ENDERECO_CRIADO",
    updated: "USUARIO_ENDERECO_ATUALIZADO",
    deleted: "USUARIO_ENDERECO_EXCLUIDO",
  },
});

export const auditarCidadesEstado = createAuditTrigger({
  document: "estado/{idEstado}/cidades/{id}",
  entidadeTipo: "cidade",
  nomeCampos: ["nome", "cidade"],
  acoes: {
    created: "CIDADE_CRIADA",
    updated: "CIDADE_ATUALIZADA",
    deleted: "CIDADE_EXCLUIDA",
  },
});

export const auditarPresentesEvento = createAuditTrigger({
  document: "evento/{idEvento}/presentes/{id}",
  entidadeTipo: "presente",
  nomeCampos: ["nome", "titulo", "descricao"],
  acoes: {
    created: "PRESENTE_CRIADO",
    updated: "PRESENTE_ATUALIZADO",
    deleted: "PRESENTE_EXCLUIDO",
  },
  relatedIds: relatedIdsFromEventoPai,
});

export const auditarContribuicoesPresente = createAuditTrigger({
  document: "evento/{idEvento}/presentes/{idPresente}/contributions/{id}",
  entidadeTipo: "presente_contribuicao",
  nomeCampos: ["nome", "nome_contribuidor", "mensagem"],
  acoes: {
    created: "PRESENTE_CONTRIBUICAO_CRIADA",
    updated: "PRESENTE_CONTRIBUICAO_ATUALIZADA",
    deleted: "PRESENTE_CONTRIBUICAO_EXCLUIDA",
  },
  relatedIds: relatedIdsFromPresentePai,
});

export const auditarTarefasEvento = createAuditTrigger({
  document: "evento/{idEvento}/tarefas/{id}",
  entidadeTipo: "evento_tarefa",
  nomeCampos: ["titulo", "nome", "descricao"],
  acoes: {
    created: "EVENTO_TAREFA_CRIADA",
    updated: "EVENTO_TAREFA_ATUALIZADA",
    deleted: "EVENTO_TAREFA_EXCLUIDA",
  },
  relatedIds: relatedIdsFromEventoPai,
});

export const auditarOrcamentosEvento = createAuditTrigger({
  document: "evento/{idEvento}/orcamento/{id}",
  entidadeTipo: "evento_orcamento",
  nomeCampos: ["nome", "titulo", "descricao"],
  acoes: {
    created: "EVENTO_ORCAMENTO_CRIADO",
    updated: "EVENTO_ORCAMENTO_ATUALIZADO",
    deleted: "EVENTO_ORCAMENTO_EXCLUIDO",
  },
  relatedIds: relatedIdsFromEventoPai,
});

export const auditarItensCardapio = createAuditTrigger({
  document: "cardapios/{idCardapio}/itens/{id}",
  entidadeTipo: "cardapio_item",
  nomeCampos: ["nome", "titulo", "descricao"],
  acoes: {
    created: "CARDAPIO_ITEM_CRIADO",
    updated: "CARDAPIO_ITEM_ATUALIZADO",
    deleted: "CARDAPIO_ITEM_EXCLUIDO",
  },
  relatedIds: relatedIdsFromCardapioPai,
});

export const auditarOrcamentos = createAuditTrigger({
  document: "orcamento/{id}",
  entidadeTipo: "orcamento",
  nomeCampos: ["nome", "anotacoes", "categoria_nome", "categoriaNome"],
  acoes: {
    created: "ORCAMENTO_CRIADO",
    updated: "ORCAMENTO_ATUALIZADO",
    deleted: "ORCAMENTO_EXCLUIDO",
  },
  acao: resolverAcaoOrcamento,
  idEvento: (_id, data) => firstRelevantText(data, ["id_evento", "idEvento"]),
  idFornecedor: (_id, data) => firstRelevantText(data, ["id_fornecedor", "idFornecedor"]),
  idOrcamento: (id, data) => firstId(id, data, ["id_orcamento", "idOrcamento", "id"]),
});

export const auditarGastosOrcamento = createAuditTrigger({
  document: "orcamento/{idOrcamento}/orcamento_gasto/{id}",
  entidadeTipo: "orcamento_gasto",
  nomeCampos: ["nome", "descricao", "categoria"],
  acoes: {
    created: "ORCAMENTO_GASTO_CRIADO",
    updated: "ORCAMENTO_GASTO_ATUALIZADO",
    deleted: "ORCAMENTO_GASTO_EXCLUIDO",
  },
  idOrcamento: (_id, _data, params) => text(params.idOrcamento),
  relatedIds: relatedIdsFromOrcamentoPai,
});

export const auditarAvaliacoesFornecedor = createAuditTrigger({
  document: "fornecedor/{idFornecedor}/avaliacoes/{id}",
  entidadeTipo: "fornecedor_avaliacao",
  nomeCampos: ["nome_cliente", "nomeCliente", "comentario", "resumo"],
  acoes: {
    created: "FORNECEDOR_AVALIACAO_CRIADA",
    updated: "FORNECEDOR_AVALIACAO_ATUALIZADA",
    deleted: "FORNECEDOR_AVALIACAO_EXCLUIDA",
  },
  idFornecedor: (_id, _data, params) => text(params.idFornecedor),
});

export const auditarAvaliacoesServicoFornecedor = createAuditTrigger({
  document: "fornecedor_servico/{idServico}/avaliacoes/{id}",
  entidadeTipo: "servico_avaliacao",
  nomeCampos: ["nome_cliente", "nomeCliente", "comentario", "resumo"],
  acoes: {
    created: "SERVICO_AVALIACAO_CRIADA",
    updated: "SERVICO_AVALIACAO_ATUALIZADA",
    deleted: "SERVICO_AVALIACAO_EXCLUIDA",
  },
  relatedIds: relatedIdsFromFornecedorServicoPai,
});

export const auditarCotacoes = createAuditTrigger({
  document: "cotacao/{id}",
  entidadeTipo: "cotacao",
  nomeCampos: ["categoria_nome", "categoriaNome", "observacao", "descricao"],
  acoes: {
    created: "COTACAO_CRIADA",
    updated: "COTACAO_ATUALIZADA",
    deleted: "COTACAO_EXCLUIDA",
  },
  acao: resolverAcaoCotacao,
  idEvento: (_id, data) => firstRelevantText(data, ["id_evento", "idEvento"]),
  idCotacao: (id, data) => firstId(id, data, ["id_cotacao", "idCotacao", "id"]),
});

export const auditarRespostasCotacaoFornecedor = createAuditTrigger({
  document: "cotacao/{idCotacao}/fornecedores/{idFornecedor}",
  entidadeTipo: "cotacao_fornecedor",
  nomeCampos: ["nome_fornecedor", "nomeFornecedor", "status"],
  acoes: {
    created: "COTACAO_FORNECEDOR_CRIADA",
    updated: "COTACAO_FORNECEDOR_ATUALIZADA",
    deleted: "COTACAO_FORNECEDOR_EXCLUIDA",
  },
  acao: resolverAcaoCotacaoFornecedor,
  idFornecedor: (_id, _data, params) => text(params.idFornecedor),
  idCotacao: (_id, _data, params) => text(params.idCotacao),
});

export const auditarServicosCotacaoFornecedor = createAuditTrigger({
  document: "cotacao/{idCotacao}/fornecedores/{idFornecedor}/servicos/{id}",
  entidadeTipo: "cotacao_servico",
  nomeCampos: ["nome_produto_servico", "nomeServico", "nome", "status"],
  acoes: {
    created: "COTACAO_SERVICO_CRIADO",
    updated: "COTACAO_SERVICO_ATUALIZADO",
    deleted: "COTACAO_SERVICO_EXCLUIDO",
  },
  idServico: (id, data) => firstId(
    id,
    data,
    ["id_produto_servico", "idProdutoServico", "id_servico", "idServico"],
  ),
  relatedIds: relatedIdsFromCotacaoPai,
});

export const auditarItensCalculadoraFesta = createAuditTrigger({
  document: "calculadora_festa/{idCalculo}/itens/{id}",
  entidadeTipo: "calculadora_item",
  nomeCampos: ["nome", "descricao", "categoria"],
  acoes: {
    created: "CALCULADORA_ITEM_CRIADO",
    updated: "CALCULADORA_ITEM_ATUALIZADO",
    deleted: "CALCULADORA_ITEM_EXCLUIDO",
  },
  relatedIds: relatedIdsFromCalculadoraPai,
});

export const auditarAnalisesCalculadoraFesta = createAuditTrigger({
  document: "calculadora_festa/{idCalculo}/analises_ia/{id}",
  entidadeTipo: "calculadora_analise_ia",
  nomeCampos: ["titulo", "resumo", "fonte"],
  acoes: {
    created: "CALCULADORA_ANALISE_IA_CRIADA",
    updated: "CALCULADORA_ANALISE_IA_ATUALIZADA",
    deleted: "CALCULADORA_ANALISE_IA_EXCLUIDA",
  },
  relatedIds: relatedIdsFromCalculadoraPai,
});

export const auditarComentariosComunidade = createAuditTrigger({
  document: "posts/{idPost}/comentarios/{id}",
  entidadeTipo: "post_comentario",
  nomeCampos: ["autor_nome", "nomeAutor", "texto"],
  acoes: {
    created: "POST_COMENTARIO_CRIADO",
    updated: "POST_COMENTARIO_ATUALIZADO",
    deleted: "POST_COMENTARIO_EXCLUIDO",
  },
});
