"use strict";
const projeto = require("./exigirEmuladorDemo").exigirEmuladorDemo("demo-decisoes-fornecedor");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { admin } = require("../lib/shared/firebaseAdmin");
const { criarCotacao } = require("../lib/functions/cotacao/criarCotacao");
const { responderCotacao } = require("../lib/functions/cotacao/responderCotacao");
const { fecharCotacao } = require("../lib/functions/cotacao/fecharCotacao");
const { abrirCasoMediacaoParteFn } = require("../lib/functions/financeiro/comandosAcompanhamentoPartes");
const { atribuirResponsavelCasoFn, fecharCasoMediacaoFn, registrarDecisaoCasoFn } = require("../lib/functions/financeiro/comandosMediacao");
const { registrarContratoFinanceiro } = require("../lib/functions/financeiro/comandosFinanceiro");
const { consultarFornecedorAdminFn, consultarFilaFornecedorAdminFn, consultarTriagemFornecedoresAdminFn } = require("../lib/services/fornecedores/consultaFornecedorAdminService");
const { consultarComunicadoFornecedorFn, registrarMedidaFornecedorFn, registrarRecursoFornecedorFn } = require("../lib/services/fornecedores/decisoesFornecedorService");

const db = admin.firestore();
const call = (fn, uid, data = {}) => fn.run({ auth: uid ? { uid, token: {} } : undefined, data });
const recusar = (fn, uid, data, codigo) => assert.rejects(() => call(fn, uid, data), e => e.code === codigo);
const futura = horas => new Date(Date.now() + horas * 3600000);
let etapa = "preparação";
const dadosCotacao = {
  idEvento: "evento", categoriaNome: "Buffet", fornecedoresSelecionados: ["forn"],
  servicos: [{ idFornecedor: "forn", idProdutoServico: "buffet", quantidade: 1 }],
};

async function enviarEPropor() {
  const { idCotacao } = await call(criarCotacao, "cli", dadosCotacao);
  await call(responderCotacao, "forn", {
    idCotacao, idFornecedor: "forn", aceitou: true, valorBrutoCentavos: 30000,
    descontoCentavos: 0, validade: futura(72).toISOString(),
    escopo: "Buffet para a festa", condicaoPagamento: "Pagamento após entrega",
    versaoEsperada: 0, chave: "proposta",
  });
  const proposta = (await db.doc(`cotacao/${idCotacao}/fornecedores/forn`).get()).data().proposta_atual;
  return { idCotacao, idFornecedor: "forn", versaoProposta: proposta.versao, assinaturaProposta: proposta.assinatura };
}

async function testar() {
  for (const [uid, tipo] of [["cli", "O"], ["forn", "F"], ["outro", "F"], ["adm", "A"], ["adm2", "A"]]) {
    await db.doc(`usuarios/${uid}`).set({ tipo, ativo: true, nome: uid });
  }
  await db.doc("fornecedor/forn").set({ razao_social: "Buffet teste" });
  await db.doc("evento/evento").set({ id_usuario: "cli", nome: "Festa teste", data: admin.firestore.Timestamp.fromDate(futura(20)) });
  await db.doc("fornecedor_servico/forn_buffet").set({ id_fornecedor: "forn", id_produto_servico: "buffet", preco: 300 });
  await db.doc("fornecedor_servico/forn_decoracao").set({ id_fornecedor: "forn", id_produto_servico: "decoracao", preco: 200 });
  await db.doc("fornecedor/forn/avaliacoes/antiga").set({ nota: 5, comentario: "Legado sem comprovação" });
  await db.doc("orcamento/legado").set({ id_evento: "evento", id_solicitante: "cli", id_fornecedor: "forn", status: "aberto" });

  const primeira = await enviarEPropor();
  const segunda = await enviarEPropor();
  const { idOrcamento } = await call(fecharCotacao, "cli", primeira);
  const incidente = await call(abrirCasoMediacaoParteFn, "cli", {
    idOrcamento, categoria: "cancelamento_fornecedor", motivo: "Cancelamento comunicado na véspera",
    descricao: "O fornecedor avisou que não conseguirá cumprir o compromisso.", chaveIdempotencia: "incidente",
  });
  const idCaso = incidente.caso.id;
  etapa = "triagem e atribuição";
  const fila = await call(consultarFilaFornecedorAdminFn, "adm");
  assert.equal(fila.casos[0].id, idCaso);
  assert.equal(fila.casos[0].eventoProximo, true);
  assert.equal(fila.casos[0].prioridade, "alta");
  const atribuicoes = await Promise.allSettled(["adm", "adm2"].map(uid =>
    call(atribuirResponsavelCasoFn, uid, { idCaso, assumir: true })));
  assert.equal(atribuicoes.filter(r => r.status === "fulfilled").length, 1);
  assert.equal(atribuicoes.find(r => r.status === "rejected").reason.code, "aborted");

  for (const uid of ["cli", "forn", null]) {
    await recusar(consultarFornecedorAdminFn, uid, { idFornecedor: "forn" }, uid ? "permission-denied" : "unauthenticated");
  }
  const ficha = await call(consultarFornecedorAdminFn, "adm", { idFornecedor: "forn", dias: 90 });
  assert.equal(ficha.atendimento.recebidas, 2);
  assert.equal(ficha.atendimento.amostraRespostas, 2);
  assert.equal(ficha.execucao.contratacoes, 1);
  assert.equal(ficha.contratos[0].idOrcamento, idOrcamento);
  assert.equal(ficha.reputacao.media, null);
  assert.equal(ficha.reputacao.itens[0].verificada, false);

  etapa = "triagem em lote";
  const vencimento = admin.firestore.Timestamp.fromDate(futura(-3));
  for (const [id, status, retorno] of [
    ["vencida", "pendente", null],
    ["cancelada", "cancelada", null],
    ["aguarda-cliente", "pendente", "cliente"],
  ]) {
    await db.doc(`cotacao/${id}`).set({ status, data_limite_resposta: vencimento });
    await db.doc(`cotacao/${id}/fornecedores/forn`).set({
      id_fornecedor: "forn", status: "aguardando", responsavel_retorno: retorno,
    });
  }
  await recusar(consultarTriagemFornecedoresAdminFn, "forn", { ids: ["forn"] }, "permission-denied");
  const triagem = await call(consultarTriagemFornecedoresAdminFn, "adm", { ids: ["forn", "outro", "forn"] });
  assert.equal(triagem.fornecedores.length, 2);
  const sinais = triagem.fornecedores.find(s => s.idFornecedor === "forn");
  assert.equal(sinais.casosAbertos, 1);
  assert.equal(sinais.semResponsavel, 0);
  assert.ok(["adm", "adm2"].includes(sinais.responsavel));
  assert.ok(sinais.eventoProximoEm);
  assert.equal(sinais.cotacoesVencidas, 1);
  assert.equal(triagem.fornecedores.find(s => s.idFornecedor === "outro").cotacoesVencidas, 0);

  etapa = "restrição geral e recurso";
  const medida = {
    idFornecedor: "forn", acao: "restringir", versao: 0, chave: "medida", dias: 2, fundamento: "preventiva", idCaso,
    justificativa: "Evidência interna da tratativa", comunicado: "O caso está em apuração.", retorno: "Apresentar plano de atendimento.",
  };
  await recusar(registrarMedidaFornecedorFn, "forn", medida, "permission-denied");
  await recusar(registrarMedidaFornecedorFn, "adm", { ...medida, fundamento: "confirmada" }, "failed-precondition");
  const resultados = await Promise.all([1, 2].map(() => call(registrarMedidaFornecedorFn, "adm", medida)));
  assert.equal(resultados.filter(r => !r.idempotente).length, 1);
  await recusar(criarCotacao, "cli", dadosCotacao, "failed-precondition");
  await recusar(fecharCotacao, "cli", segunda, "failed-precondition");
  await recusar(registrarContratoFinanceiro, "cli", {
    idEvento: "evento", idOrcamento: "legado", valorCentavos: 30000,
  }, "failed-precondition");
  assert.equal((await call(fecharCotacao, "cli", primeira)).idOrcamento, idOrcamento);
  assert.equal((await db.doc(`orcamento/${idOrcamento}`).get()).data().estado_execucao, "nao_iniciado");
  const { medida: aviso } = await call(consultarComunicadoFornecedorFn, "forn");
  assert.equal(aviso.vigente, true);
  assert.equal(aviso.justificativa, undefined);
  assert.equal(aviso.idCaso, undefined);
  assert.equal((await call(consultarComunicadoFornecedorFn, "outro")).medida, null);
  await recusar(registrarRecursoFornecedorFn, "outro", { idMedida: aviso.id, mensagem: "Recurso indevido" }, "failed-precondition");
  await call(registrarRecursoFornecedorFn, "forn", { idMedida: aviso.id, mensagem: "Proposta de regularização" });
  assert.equal((await call(consultarFilaFornecedorAdminFn, "adm")).recursos.length, 1);
  const retirar = { idFornecedor: "forn", acao: "retirar", chave: "retirar", justificativa: "Recurso apurado", comunicado: "Restrição retirada." };
  await recusar(registrarMedidaFornecedorFn, "adm", { ...retirar, versao: 1 }, "aborted");

  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(":");
  const regras = await initializeTestEnvironment({
    projectId: projeto,
    firestore: { host, port: Number(port), rules: fs.readFileSync("firestore.rules", "utf8") },
  });
  try {
    const cliente = regras.authenticatedContext("cli").firestore();
    const fornecedor = regras.authenticatedContext("forn").firestore();
    await assertFails(fornecedor.doc("plataforma_medidas_fornecedor/forn").get());
    await assertFails(fornecedor.doc("plataforma_medidas_fornecedor/forn").delete());
    await assertFails(cliente.doc("orcamento/legado").update({ status: "fechado", orcamento_fechado: true }));
    await call(registrarMedidaFornecedorFn, "adm", { ...retirar, versao: 2 });
    await assertSucceeds(cliente.doc("orcamento/legado").update({ status: "fechado", orcamento_fechado: true }));
    assert.ok((await call(fecharCotacao, "cli", segunda)).idOrcamento);
    etapa = "restrição por serviço";
    await call(registrarMedidaFornecedorFn, "adm", { ...medida, chave: "servico", versao: 3, idServico: "buffet" });
    const resumo = await call(consultarTriagemFornecedoresAdminFn, "adm", { ids: ["forn"] });
    assert.equal(resumo.fornecedores[0].restricao.acao, "restringir");
    assert.equal(resumo.fornecedores[0].restricao.servico, "Serviço do fornecedor");
    await recusar(criarCotacao, "cli", dadosCotacao, "failed-precondition");
    const decoracao = { ...dadosCotacao, servicos: [{ idFornecedor: "forn", idProdutoServico: "decoracao", quantidade: 1 }] };
    assert.ok((await call(criarCotacao, "cli", decoracao)).idCotacao);
    const novoContrato = { id_evento: "evento", id_solicitante: "cli", id_fornecedor: "forn", status: "fechado" };
    await assertSucceeds(cliente.doc("orcamento/nova-decoracao").set({ ...novoContrato, id_servico_fornecido: "decoracao" }));
    await assertFails(cliente.doc("orcamento/novo-buffet").set({ ...novoContrato, id_servico_fornecido: "buffet" }));
    etapa = "descredenciamento após apuração";
    const definitivo = { ...medida, chave: "descredenciar", versao: 4, acao: "descredenciar",
      dias: undefined, fundamento: "confirmada" };
    await recusar(registrarMedidaFornecedorFn, "adm", definitivo, "failed-precondition");
    await call(registrarDecisaoCasoFn, "adm", {
      idCaso, tipoDecisao: "encaminhar", texto: "Evidências verificadas; encaminhar para decisão comercial.",
    });
    await call(fecharCasoMediacaoFn, "adm", { idCaso, conclusao: "Descumprimento confirmado na apuração." });
    await call(registrarMedidaFornecedorFn, "adm", definitivo);
    await recusar(criarCotacao, "cli", decoracao, "failed-precondition");
    assert.equal((await call(consultarFilaFornecedorAdminFn, "adm")).restricoes[0].acao, "descredenciar");
  } finally {
    await regras.cleanup();
  }
  console.log("PASS: incidente sem aceite, triagem, atribuição concorrente, permissões, restrições, descredenciamento, recurso e retirada.");
}

testar().catch(error => { console.error(etapa, error); process.exitCode = 1; }).finally(() => db.terminate());
