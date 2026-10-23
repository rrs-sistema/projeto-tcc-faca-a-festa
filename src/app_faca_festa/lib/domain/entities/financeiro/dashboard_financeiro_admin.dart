/// Fato comercial autorizado (evento pagador) — sem custos privados de fornecedor.
class FatoComercialAdmin {
  const FatoComercialAdmin({
    required this.idEvento,
    required this.idOrcamento,
    required this.contratado,
    this.idNecessidade,
    this.idFornecedor,
    this.idServico,
    this.valorOportunidadeCentavos = 0,
    this.valorContratadoCentavos = 0,
    this.pagoCentavos = 0,
    this.alternativaAtiva = true,
    this.dataEvento,
    this.dataContratacao,
    this.statusEvento,
    this.consultaPagamentoCompleta = true,
  });

  final String idEvento;
  final String idOrcamento;
  final String? idNecessidade;
  final String? idFornecedor;
  final String? idServico;
  final bool contratado;
  final int valorOportunidadeCentavos;
  final int valorContratadoCentavos;
  final int pagoCentavos;
  final bool alternativaAtiva;
  final DateTime? dataEvento;
  final DateTime? dataContratacao;
  final String? statusEvento;
  final bool consultaPagamentoCompleta;
}

class FatoComissaoAdmin {
  const FatoComissaoAdmin({
    required this.id,
    required this.status,
    required this.valorOriginalCentavos,
    this.valorAjustesCentavos = 0,
    this.valorLiquidadoCentavos = 0,
    this.vencimento,
    this.idEvento,
  });

  final String id;
  final String status;
  final int valorOriginalCentavos;
  final int valorAjustesCentavos;
  final int valorLiquidadoCentavos;
  final DateTime? vencimento;
  final String? idEvento;

  int get saldoCentavos =>
      valorOriginalCentavos + valorAjustesCentavos - valorLiquidadoCentavos;
}

class LinhaEventoDashboardAdmin {
  const LinhaEventoDashboardAdmin({
    required this.idEvento,
    required this.qtdServicos,
    required this.qtdContratos,
    required this.contratadoCentavos,
    required this.pagoCentavos,
    required this.saldoCentavos,
    required this.previsaoDisponivelCentavos,
    required this.comissaoCentavos,
    this.dataEvento,
    this.status,
    this.pagamentoIncompleto = false,
  });

  final String idEvento;
  final DateTime? dataEvento;
  final String? status;
  final int qtdServicos;
  final int qtdContratos;
  final int contratadoCentavos;
  final int pagoCentavos;
  final int saldoCentavos;
  final int previsaoDisponivelCentavos;
  final int comissaoCentavos;
  final bool pagamentoIncompleto;
}

class ResumoComissaoDashboard {
  const ResumoComissaoDashboard({
    required this.configurada,
    this.previstasCentavos = 0,
    this.geradasCentavos = 0,
    this.aReceberCentavos = 0,
    this.vencidasCentavos = 0,
    this.recebidasCentavos = 0,
    this.ajustadasCentavos = 0,
  });

  final bool configurada;
  final int previstasCentavos;
  final int geradasCentavos;
  final int aReceberCentavos;
  final int vencidasCentavos;
  final int recebidasCentavos;
  final int ajustadasCentavos;
}

/// Dashboard financeiro/comercial da administração.
/// Volume contratado ≠ receita própria da plataforma.
class DashboardFinanceiroAdmin {
  const DashboardFinanceiroAdmin({
    required this.qtdEventos,
    required this.qtdContratos,
    required this.qtdOportunidades,
    required this.qtdEventosExecucao,
    required this.qtdEventosRealizados,
    required this.qtdServicosDistintos,
    required this.qtdFornecedoresDistintos,
    required this.valorOportunidadesCentavos,
    required this.volumeContratadoCentavos,
    required this.pagamentosEventosCentavos,
    required this.receitaPlataformaCentavos,
    required this.comissao,
    required this.linhasEvento,
    required this.completo,
    required this.eixoTemporal,
    this.despesasPlataformaCentavos,
    this.resultadoGerencialCentavos,
    this.rotuloResultado = 'receitas_e_movimentos',
    this.formulaAbrangencia =
        'receita_plataforma = comissões recebidas; volume_contratado ≠ receita',
    this.origemConsulta = 'agregado_autorizado',
  });

  final int qtdEventos;
  final int qtdContratos;
  final int qtdOportunidades;
  final int qtdEventosExecucao;
  final int qtdEventosRealizados;
  final int qtdServicosDistintos;
  final int qtdFornecedoresDistintos;

  /// Valor em negociação / aberto (não é receita).
  final int valorOportunidadesCentavos;

  /// Volume contratado nos eventos (não é receita da plataforma).
  final int volumeContratadoCentavos;

  /// Pagamentos conhecidos na perspectiva evento_pagador.
  final int pagamentosEventosCentavos;

  /// Receita própria = comissões recebidas (não o volume movimentado).
  final int receitaPlataformaCentavos;

  final ResumoComissaoDashboard comissao;
  final List<LinhaEventoDashboardAdmin> linhasEvento;
  final bool completo;
  final String eixoTemporal;
  final int? despesasPlataformaCentavos;
  final int? resultadoGerencialCentavos;

  /// Sem despesas completas: não rotular como lucro líquido.
  final String rotuloResultado;
  final String formulaAbrangencia;
  final String origemConsulta;

  Map<String, dynamic> toMap() => {
        'qtd_eventos': qtdEventos,
        'qtd_contratos': qtdContratos,
        'qtd_oportunidades': qtdOportunidades,
        'qtd_eventos_execucao': qtdEventosExecucao,
        'qtd_eventos_realizados': qtdEventosRealizados,
        'qtd_servicos_distintos': qtdServicosDistintos,
        'qtd_fornecedores_distintos': qtdFornecedoresDistintos,
        'valor_oportunidades_centavos': valorOportunidadesCentavos,
        'volume_contratado_centavos': volumeContratadoCentavos,
        'pagamentos_eventos_centavos': pagamentosEventosCentavos,
        'receita_plataforma_centavos': receitaPlataformaCentavos,
        'comissao_configurada': comissao.configurada,
        'comissao_previstas_centavos': comissao.previstasCentavos,
        'comissao_geradas_centavos': comissao.geradasCentavos,
        'comissao_a_receber_centavos': comissao.aReceberCentavos,
        'comissao_vencidas_centavos': comissao.vencidasCentavos,
        'comissao_recebidas_centavos': comissao.recebidasCentavos,
        'comissao_ajustadas_centavos': comissao.ajustadasCentavos,
        'completo': completo,
        'eixo_temporal': eixoTemporal,
        'despesas_plataforma_centavos': despesasPlataformaCentavos,
        'resultado_gerencial_centavos': resultadoGerencialCentavos,
        'rotulo_resultado': rotuloResultado,
        'formula_abrangencia': formulaAbrangencia,
        'origem_consulta': origemConsulta,
        'linhas_evento': linhasEvento
            .map((l) => {
                  'id_evento': l.idEvento,
                  'data_evento': l.dataEvento?.toIso8601String(),
                  'status': l.status,
                  'qtd_servicos': l.qtdServicos,
                  'qtd_contratos': l.qtdContratos,
                  'contratado_centavos': l.contratadoCentavos,
                  'pago_centavos': l.pagoCentavos,
                  'saldo_centavos': l.saldoCentavos,
                  'previsao_disponivel_centavos': l.previsaoDisponivelCentavos,
                  'comissao_centavos': l.comissaoCentavos,
                  'pagamento_incompleto': l.pagamentoIncompleto,
                })
            .toList(),
      };
}
