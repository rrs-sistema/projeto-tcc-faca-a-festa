const assert = require("assert");
const path = require("path");
const {
  capacidadesParaTipoUsuario,
  filtrarRegistrosPorPapel,
  registrosParaExportacao,
  escopoBloqueioRevisao,
  aplicarRecomendacaoBloqueio,
  registrarDecisaoSemEfeitoFinanceiro,
  fecharCasoSemMovimentoFinanceiro,
  calcularDimensoesFinanceiras,
  montarLinhaCentral,
  casoPertenceAoVinculo,
} = require(path.join(
  __dirname,
  "../lib/services/financeiro/mediacaoOperacionalService.js",
));

(function operadorVeNomesNasDimensoes() {
  const fin = calcularDimensoesFinanceiras({
    valorContratadoCentavos: 1_000_000,
    recebidoAlocadoCentavos: 400_000,
    repassadoConfirmadoCentavos: 0,
  });
  const linha = montarLinhaCentral({
    idContrato: "c1",
    idOrcamento: "o1",
    idEvento: "e1",
    nomeEvento: "Festa Ana",
    dataEvento: "2026-12-01",
    nomeContratante: "Maria",
    nomeFornecedor: "Buffet Sol",
    nomeServico: "Coffee break",
    escopoCurto: "50 pessoas",
    estadoComercial: "contratado",
    estadoExecucao: "nao_iniciado",
    identidadeIncompleta: false,
    pendenciasIdentificacao: [],
    financeiro: fin,
    casoAberto: null,
  });
  assert.strictEqual(linha.nomeContratante, "Maria");
  assert.strictEqual(linha.nomeFornecedor, "Buffet Sol");
  assert.strictEqual(linha.nomeServico, "Coffee break");
  assert.strictEqual(linha.aReceberClienteCentavos, 600_000);
  assert.strictEqual(linha.pendenteRepasseCentavos, 400_000);
  assert.strictEqual(linha.repassadoCentavos, 0);
  // Dimensões expostas separadamente (não um campo "saldo" único).
  assert.ok("aReceberClienteCentavos" in linha);
  assert.ok("pendenteRepasseCentavos" in linha);
  assert.ok(!("saldo" in linha));
  console.log("✓ linha identifica cliente/fornecedor/serviço com saldos separados");
})();

(function doisFornecedoresCasoNaoBloqueiaOutro() {
  const escopo = escopoBloqueioRevisao({
    idContratoAlvo: "c-buffet",
    idsContratosDoEvento: ["c-buffet", "c-som"],
  });
  assert.deepStrictEqual(escopo.contratosAfetados, ["c-buffet"]);
  assert.deepStrictEqual(escopo.naoAfetados, ["c-som"]);
  const caso = {
    id: "caso1",
    idEvento: "e1",
    idContrato: "c-buffet",
    idOrcamento: "o1",
    idFornecedor: "f1",
    idContratante: "u1",
    categoria: "divergencia_servico",
    motivo: "atraso",
    descricao: "",
    prioridade: "normal",
    estado: "aberto",
    idResponsavel: null,
    abertoPorId: "admin",
    abertoEm: "2026-01-01",
    fechadoEm: null,
    conclusao: null,
    recomendacaoBloqueioAtiva: false,
    motivoRecomendacaoBloqueio: null,
    retencaoEfetivaAtiva: false,
  };
  const r = aplicarRecomendacaoBloqueio({
    caso,
    motivo: "revisar entrega buffet",
    politicaRetencaoAtiva: false,
    temCapacidadeAutorizacao: true,
  });
  assert.strictEqual(r.somenteRecomendacao, true);
  assert.strictEqual(r.retencaoAplicada, false);
  assert.strictEqual(r.caso.recomendacaoBloqueioAtiva, true);
  console.log("✓ caso em um contrato não afeta o outro; só recomendação sem retenção");
})();

(function notaInternaNaoVaza() {
  const capsAdmin = capacidadesParaTipoUsuario("A");
  const regs = [
    {
      id: "1",
      idCaso: "c",
      tipo: "nota_interna",
      visibilidade: "interna",
      texto: "margem interna",
      autorId: "a",
      criadoEm: "1",
      efeitoFinanceiroExecutado: false,
    },
    {
      id: "2",
      idCaso: "c",
      tipo: "info_compartilhavel",
      visibilidade: "compartilhavel",
      texto: "aguardamos foto",
      autorId: "a",
      criadoEm: "2",
      efeitoFinanceiroExecutado: false,
    },
  ];
  const cliente = filtrarRegistrosPorPapel(regs, "cliente", ["consulta_comercial"]);
  assert.strictEqual(cliente.length, 1);
  assert.strictEqual(cliente[0].texto, "aguardamos foto");
  const exportacao = registrosParaExportacao(regs);
  assert.strictEqual(exportacao.length, 1);
  assert.ok(!exportacao.some((r) => r.visibilidade === "interna"));
  const admin = filtrarRegistrosPorPapel(regs, "admin", capsAdmin);
  assert.strictEqual(admin.length, 2);
  console.log("✓ cliente só vê compartilhável; nota interna não exporta");
})();

(function fecharCasoSemReembolso() {
  const caso = {
    id: "caso1",
    idEvento: "e1",
    idContrato: "c1",
    idOrcamento: "o1",
    idFornecedor: "f1",
    idContratante: "u1",
    categoria: "reembolso_solicitado",
    motivo: "pedido reembolso",
    descricao: "",
    prioridade: "alta",
    estado: "em_decisao",
    idResponsavel: "admin",
    abertoPorId: "admin",
    abertoEm: "2026-01-01",
    fechadoEm: null,
    conclusao: null,
    recomendacaoBloqueioAtiva: false,
    motivoRecomendacaoBloqueio: null,
    retencaoEfetivaAtiva: false,
  };
  const dec = registrarDecisaoSemEfeitoFinanceiro({
    caso,
    tipoDecisao: "recomendar_reembolso",
    texto: "recomenda análise financeira",
    autorId: "admin",
    agoraIso: "2026-02-01",
    referenciasComandos: ["registrarAjustePosRepasse"],
  });
  assert.strictEqual(dec.registro.efeitoFinanceiroExecutado, false);
  assert.deepStrictEqual(dec.registro.referenciasComandos, [
    "registrarAjustePosRepasse",
  ]);
  const fech = fecharCasoSemMovimentoFinanceiro({
    caso: dec.caso,
    conclusao: "encerrado sem pagamento",
    autorId: "admin",
    agoraIso: "2026-02-02",
  });
  assert.deepStrictEqual(fech.efeitosFinanceiros, []);
  assert.strictEqual(fech.caso.estado, "fechado");
  console.log("✓ fechar/decidir não executa reembolso/repasse silencioso");
})();

(function vinculoFornecedorEEstados() {
  const caso = {
    id: "x",
    idEvento: "e",
    idContrato: "c",
    idOrcamento: "o",
    idFornecedor: "forn-A",
    idContratante: "cli-1",
    categoria: "outro",
    motivo: "m",
    descricao: "",
    prioridade: "baixa",
    estado: "aberto",
    idResponsavel: null,
    abertoPorId: "a",
    abertoEm: "1",
    fechadoEm: null,
    conclusao: null,
    recomendacaoBloqueioAtiva: false,
    motivoRecomendacaoBloqueio: null,
    retencaoEfetivaAtiva: false,
  };
  assert.strictEqual(
    casoPertenceAoVinculo({
      caso,
      papel: "fornecedor",
      uid: "op",
      idFornecedorOperador: "forn-A",
    }),
    true,
  );
  assert.strictEqual(
    casoPertenceAoVinculo({
      caso,
      papel: "fornecedor",
      uid: "op",
      idFornecedorOperador: "forn-B",
    }),
    false,
  );
  assert.strictEqual(
    casoPertenceAoVinculo({ caso, papel: "cliente", uid: "cli-1" }),
    true,
  );
  const fin = calcularDimensoesFinanceiras({
    valorContratadoCentavos: 500_000,
    recebidoAlocadoCentavos: 100_000,
    repassadoConfirmadoCentavos: 50_000,
  });
  const linha = montarLinhaCentral({
    idContrato: "c",
    idOrcamento: "o",
    idEvento: "e",
    nomeEvento: "E",
    dataEvento: null,
    nomeContratante: "C",
    nomeFornecedor: "F",
    nomeServico: "S",
    escopoCurto: null,
    estadoComercial: "contratado",
    estadoExecucao: "contestado",
    identidadeIncompleta: true,
    pendenciasIdentificacao: ["pagador"],
    financeiro: fin,
    casoAberto: caso,
  });
  assert.ok(linha.pendencias.includes("caso_mediacao_aberto"));
  assert.ok(linha.pendencias.includes("financeiro_cliente"));
  assert.ok(linha.pendencias.includes("pagador"));
  assert.ok(linha.pendencias.includes("repasse_pendente"));
  console.log("✓ vínculo fornecedor/cliente e pendências multi-estado visíveis");
})();

console.log("✓ mediacaoOperacional: todos os aceites");
