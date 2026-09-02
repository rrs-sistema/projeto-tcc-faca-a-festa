const assert = require("node:assert/strict");

const {
  resolverAcaoCotacao,
  resolverAcaoCotacaoFornecedor,
  resolverAcaoEvento,
  resolverAcaoFornecedor,
  resolverAcaoOrcamento,
  resolverAcaoUsuario,
} = require("../lib/functions/auditoria/auditActionResolvers");

function test(name, run) {
  run();
  console.log(`ok - ${name}`);
}

test("classifica alteracoes administrativas de usuario", () => {
  assert.equal(
    resolverAcaoUsuario("updated", {tipo: "organizador"}, {tipo: "admin"}),
    "USUARIO_TIPO_ALTERADO",
  );
  assert.equal(
    resolverAcaoUsuario("updated", {ativo: true}, {ativo: false}),
    "USUARIO_STATUS_ALTERADO",
  );
  assert.equal(resolverAcaoUsuario("created", undefined, {}), "USUARIO_CRIADO");
});

test("classifica aprovacao e ativacao de fornecedor", () => {
  assert.equal(
    resolverAcaoFornecedor(
      "updated",
      {apto_para_operar: false},
      {apto_para_operar: true},
    ),
    "FORNECEDOR_APROVADO",
  );
  assert.equal(
    resolverAcaoFornecedor("updated", {aptoParaOperar: true}, {aptoParaOperar: false}),
    "FORNECEDOR_REPROVADO",
  );
  assert.equal(
    resolverAcaoFornecedor("updated", {ativo: false}, {ativo: true}),
    "FORNECEDOR_ATIVADO",
  );
  assert.equal(
    resolverAcaoFornecedor("updated", {active: true}, {active: false}),
    "FORNECEDOR_DESATIVADO",
  );
});

test("classifica aprovacao de evento", () => {
  assert.equal(
    resolverAcaoEvento("updated", {aprovado: false}, {aprovado: true}),
    "EVENTO_APROVADO",
  );
  assert.equal(
    resolverAcaoEvento("updated", {approved: true}, {approved: true, nome: "Festa"}),
    "EVENTO_ATUALIZADO",
  );
});

test("classifica transicoes de orcamento", () => {
  assert.equal(
    resolverAcaoOrcamento("updated", {status: "pendente"}, {status: "em_negociacao"}),
    "ORCAMENTO_RESPONDIDO",
  );
  assert.equal(
    resolverAcaoOrcamento("updated", {status: "em_negociacao"}, {status: "fechado"}),
    "ORCAMENTO_FECHADO",
  );
  assert.equal(
    resolverAcaoOrcamento(
      "updated",
      {orcamento_fechado: false},
      {orcamento_fechado: true},
    ),
    "ORCAMENTO_FECHADO",
  );
  assert.equal(
    resolverAcaoOrcamento("updated", {status: "pendente"}, {status: "cancelado"}),
    "ORCAMENTO_CANCELADO",
  );
});

test("classifica transicoes da cotacao principal", () => {
  assert.equal(
    resolverAcaoCotacao("updated", {status: "pendente"}, {status: "respondida"}),
    "COTACAO_RESPONDIDA",
  );
  assert.equal(
    resolverAcaoCotacao("updated", {status: "parcial"}, {status: "concluida"}),
    "COTACAO_FECHADA",
  );
  assert.equal(
    resolverAcaoCotacao("updated", {status: "pendente"}, {status: "cancelada"}),
    "COTACAO_CANCELADA",
  );
  assert.equal(
    resolverAcaoCotacao("updated", {status: "pendente"}, {status: "perdeuCotacao"}),
    "COTACAO_CANCELADA",
  );
});

test("classifica transicoes de resposta do fornecedor na cotacao", () => {
  assert.equal(
    resolverAcaoCotacaoFornecedor(
      "updated",
      {status: "aguardando"},
      {status: "respondido"},
    ),
    "COTACAO_RESPONDIDA",
  );
  assert.equal(
    resolverAcaoCotacaoFornecedor("updated", {status: "respondido"}, {status: "fechado"}),
    "COTACAO_FECHADA",
  );
  assert.equal(
    resolverAcaoCotacaoFornecedor("updated", {status: "aguardando"}, {status: "recusado"}),
    "COTACAO_CANCELADA",
  );
});
