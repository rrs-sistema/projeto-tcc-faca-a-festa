const assert = require("assert");
const path = require("path");
const {
  montarSnapshotAceite,
  avaliarPendencias,
  resolverLinhaContratacao,
  parseEstadoExecucao,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/contratacaoIdentidadeService.js",
));

(function snapshotNaoInventaNome() {
  const s = montarSnapshotAceite({
    origem: "teste",
    idEvento: "ev1",
    idFornecedor: "f1",
    nomeFornecedor: null,
  });
  assert.strictEqual(s.nome_fornecedor, null);
  assert.strictEqual(s.id_evento, "ev1");
  console.log("✓ snapshot preserva ausência de nome");
})();

(function doisFornecedoresMesmoEvento() {
  const base = {
    id_evento: "ev-sofia",
    id_solicitante: "ana",
    nome_solicitante: "Ana Souza",
  };
  const a = resolverLinhaContratacao({
    idOrcamento: "orc-decor",
    orcamento: {
      ...base,
      id_fornecedor: "decora",
      nome_fornecedor: "Decora Festas",
      nome: "Decoração do salão",
      orcamento_fechado: true,
      status: "fechado",
      contrato_financeiro: {
        estado_comercial: "contratado",
        estado_execucao: "nao_iniciado",
        snapshot_identidade: montarSnapshotAceite({
          origem: "teste",
          idEvento: "ev-sofia",
          nomeEvento: "Aniversário da Sofia",
          idOrganizador: "ana",
          nomeOrganizador: "Ana Souza",
          idContratante: "ana",
          nomeContratante: "Ana Souza",
          idPagador: "ana",
          nomePagador: "Ana Souza",
          idFornecedor: "decora",
          nomeFornecedor: "Decora Festas",
          nomeServico: "Decoração do salão",
          valorCentavos: 1000000,
        }),
      },
    },
    evento: { id_usuario: "ana", nome_evento: "Aniversário da Sofia" },
    organizador: { nome: "Ana Souza" },
    valorContratadoCentavos: 1000000,
    pagoCentavos: 0,
    contratado: true,
  });
  const b = resolverLinhaContratacao({
    idOrcamento: "orc-buffet",
    orcamento: {
      ...base,
      id_fornecedor: "buffet",
      nome_fornecedor: "Buffet Sabor",
      nome: "Buffet para convidados",
      status: "em_negociacao",
      alternativa_ativa: true,
    },
    evento: { id_usuario: "ana", nome_evento: "Aniversário da Sofia" },
    organizador: { nome: "Ana Souza" },
    valorContratadoCentavos: 500000,
    pagoCentavos: 0,
    contratado: false,
  });
  assert.strictEqual(a.nome_evento, "Aniversário da Sofia");
  assert.strictEqual(b.nome_evento, "Aniversário da Sofia");
  assert.strictEqual(a.nome_organizador, "Ana Souza");
  assert.strictEqual(b.nome_organizador, "Ana Souza");
  assert.strictEqual(a.nome_fornecedor, "Decora Festas");
  assert.strictEqual(b.nome_fornecedor, "Buffet Sabor");
  assert.strictEqual(a.contratado, true);
  assert.strictEqual(b.contratado, false);
  assert.strictEqual(a.estado_execucao, "nao_iniciado");
  assert.notStrictEqual(a.estado_comercial, "serviço prestado");
  console.log("✓ mesmo organizador, duas contratações distintas");
})();

(function pagadorDistintoNaoTrocaOrganizador() {
  const linha = resolverLinhaContratacao({
    idOrcamento: "orc1",
    orcamento: {
      id_evento: "ev1",
      id_solicitante: "contratante-x",
      id_pagador: "pagador-y",
      id_fornecedor: "f1",
      nome_fornecedor: "Forn",
      nome: "Som",
      orcamento_fechado: true,
      contrato_financeiro: {
        estado_comercial: "contratado",
        snapshot_identidade: montarSnapshotAceite({
          origem: "t",
          idEvento: "ev1",
          nomeEvento: "Festa",
          idOrganizador: "org-z",
          nomeOrganizador: "Organizador Z",
          idContratante: "contratante-x",
          nomeContratante: "Contratante X",
          idPagador: "pagador-y",
          nomePagador: "Pagador Y",
          idFornecedor: "f1",
          nomeFornecedor: "Forn",
          nomeServico: "Som",
        }),
      },
    },
    evento: { id_usuario: "org-z", nome_evento: "Festa" },
    organizador: { nome: "Organizador Z" },
    contratante: { nome: "Contratante X" },
    pagador: { nome: "Pagador Y" },
    valorContratadoCentavos: 100,
    pagoCentavos: 0,
    contratado: true,
  });
  assert.strictEqual(linha.id_organizador, "org-z");
  assert.strictEqual(linha.id_contratante, "contratante-x");
  assert.strictEqual(linha.id_pagador, "pagador-y");
  assert.notStrictEqual(linha.id_pagador, linha.id_organizador);
  console.log("✓ pagador ≠ organizador/contratante preservado");
})();

(function perfilAtualSeparadoDoSnapshot() {
  const snap = montarSnapshotAceite({
    origem: "t",
    idEvento: "ev1",
    nomeEvento: "Festa",
    idFornecedor: "f1",
    nomeFornecedor: "Nome Antigo",
    idContratante: "u1",
    nomeContratante: "Cliente",
    nomeServico: "Foto",
  });
  const linha = resolverLinhaContratacao({
    idOrcamento: "orc1",
    orcamento: {
      id_evento: "ev1",
      id_fornecedor: "f1",
      orcamento_fechado: true,
      contrato_financeiro: {
        estado_comercial: "contratado",
        snapshot_identidade: snap,
      },
    },
    evento: { id_usuario: "u1", nome_evento: "Festa" },
    fornecedor: { nome_fornecedor: "Nome Novo Ltda" },
    valorContratadoCentavos: 1,
    pagoCentavos: 0,
    contratado: true,
  });
  assert.strictEqual(linha.nome_fornecedor, "Nome Antigo");
  assert.strictEqual(linha.nome_fornecedor_atual, "Nome Novo Ltda");
  assert.strictEqual(linha.perfil_atual_separado, true);
  console.log("✓ snapshot preservado; perfil atual separado");
})();

(function legadoIncompletoGeraPendencia() {
  const p = avaliarPendencias({
    idEvento: "ev",
    nomeEvento: null,
    idOrganizador: null,
    nomeOrganizador: null,
    idContratante: null,
    nomeContratante: null,
    idPagador: null,
    nomePagador: null,
    idFornecedor: null,
    nomeFornecedor: null,
    idServico: null,
    nomeServico: null,
    contratado: true,
  });
  assert.ok(p.includes("evento"));
  assert.ok(p.includes("fornecedor"));
  assert.ok(p.includes("servico"));
  assert.strictEqual(parseEstadoExecucao("aceito"), "aceito");
  assert.strictEqual(parseEstadoExecucao(null), "nao_iniciado");
  console.log("✓ legado incompleto → pendências; execução separada");
})();

console.log("✓ contratacaoIdentidade: todos os casos");
