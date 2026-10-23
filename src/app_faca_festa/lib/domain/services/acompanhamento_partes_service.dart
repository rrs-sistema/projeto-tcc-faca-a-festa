import 'package:app_faca_festa/domain/entities/financeiro/intermediacao_financeira.dart';
import 'package:app_faca_festa/domain/services/intermediacao_financeira_service.dart';

/// Acompanhamento das partes (Prompt 04) — domínio puro.
class ProximoPassoAcompanhamento {
  const ProximoPassoAcompanhamento({
    required this.codigo,
    required this.rotulo,
    required this.ehPendenciaConfiguracao,
    this.responsavel,
  });

  final String codigo;
  final String rotulo;
  final String? responsavel;
  final bool ehPendenciaConfiguracao;
}

class VisaoOrganizadorContrato {
  const VisaoOrganizadorContrato({
    required this.idContrato,
    required this.idOrcamento,
    required this.valorContratadoCentavos,
    required this.nivelPagamento,
    required this.valorDeclaradoCentavos,
    required this.valorConfirmadoCentavos,
    required this.aPagarCentavos,
    required this.estadoExecucao,
    required this.proximoPasso,
    this.nomeFornecedor,
    this.nomeServico,
    this.statusRepasse,
  });

  final String idContrato;
  final String idOrcamento;
  final String? nomeFornecedor;
  final String? nomeServico;
  final int valorContratadoCentavos;
  final String nivelPagamento;
  final int valorDeclaradoCentavos;
  final int valorConfirmadoCentavos;
  final int aPagarCentavos;
  final String estadoExecucao;
  final String? statusRepasse;
  final ProximoPassoAcompanhamento proximoPasso;

  factory VisaoOrganizadorContrato.fromMap(Map<String, dynamic> m) {
    int c(dynamic v) => (v is num) ? v.toInt() : 0;
    final pp = m['proximoPasso'] ?? m['proximo_passo'];
    ProximoPassoAcompanhamento passo = const ProximoPassoAcompanhamento(
      codigo: 'acompanhar',
      rotulo: 'Acompanhar',
      ehPendenciaConfiguracao: false,
    );
    if (pp is Map) {
      passo = ProximoPassoAcompanhamento(
        codigo: (pp['codigo'] ?? '').toString(),
        rotulo: (pp['rotulo'] ?? '').toString(),
        responsavel: pp['responsavel']?.toString(),
        ehPendenciaConfiguracao:
            pp['ehPendenciaConfiguracao'] == true ||
                pp['eh_pendencia_configuracao'] == true,
      );
    }
    return VisaoOrganizadorContrato(
      idContrato: (m['idContrato'] ?? m['id_contrato'] ?? '').toString(),
      idOrcamento: (m['idOrcamento'] ?? m['id_orcamento'] ?? '').toString(),
      nomeFornecedor:
          (m['nomeFornecedor'] ?? m['nome_fornecedor'])?.toString(),
      nomeServico: (m['nomeServico'] ?? m['nome_servico'])?.toString(),
      valorContratadoCentavos:
          c(m['valorContratadoCentavos'] ?? m['valor_contratado_centavos']),
      nivelPagamento: (m['nivelPagamentoPlataforma'] ??
              m['nivel_pagamento_plataforma'] ??
              'nao_informado')
          .toString(),
      valorDeclaradoCentavos:
          c(m['valorDeclaradoCentavos'] ?? m['valor_declarado_centavos']),
      valorConfirmadoCentavos: c(m['valorConfirmadoPlataformaAlocadoCentavos'] ??
          m['valor_confirmado_plataforma_alocado_centavos']),
      aPagarCentavos:
          c(m['aPagarPlataformaCentavos'] ?? m['a_pagar_plataforma_centavos']),
      estadoExecucao:
          (m['estadoExecucao'] ?? m['estado_execucao'] ?? '').toString(),
      statusRepasse:
          (m['statusRepassePermitido'] ?? m['status_repasse_permitido'])
              ?.toString(),
      proximoPasso: passo,
    );
  }
}

class VisaoFornecedorContrato {
  const VisaoFornecedorContrato({
    required this.idContrato,
    required this.idOrcamento,
    required this.valorContratadoCentavos,
    required this.direitoLiquidoCentavos,
    required this.comissaoPrevistaCentavos,
    required this.alocadoPlataformaCentavos,
    required this.repasseConfirmadoCentavos,
    required this.saldoPrevistoRepasseCentavos,
    required this.trataAlocadoComoCaixaProprio,
    required this.comissaoJaDescontadaDoRepasse,
    required this.estadoExecucao,
    required this.pendencias,
    required this.proximoPasso,
    this.nomeEvento,
    this.nomeContratante,
    this.nomeServico,
  });

  final String idContrato;
  final String idOrcamento;
  final String? nomeEvento;
  final String? nomeContratante;
  final String? nomeServico;
  final int valorContratadoCentavos;
  final int direitoLiquidoCentavos;
  final int comissaoPrevistaCentavos;
  final int alocadoPlataformaCentavos;
  final int repasseConfirmadoCentavos;
  final int saldoPrevistoRepasseCentavos;
  final bool trataAlocadoComoCaixaProprio;
  final bool comissaoJaDescontadaDoRepasse;
  final String estadoExecucao;
  final List<String> pendencias;
  final ProximoPassoAcompanhamento proximoPasso;

  factory VisaoFornecedorContrato.fromMap(Map<String, dynamic> m) {
    int c(dynamic v) => (v is num) ? v.toInt() : 0;
    final pp = m['proximoPasso'] ?? m['proximo_passo'];
    ProximoPassoAcompanhamento passo = const ProximoPassoAcompanhamento(
      codigo: 'acompanhar_repasse',
      rotulo: 'Acompanhar',
      ehPendenciaConfiguracao: false,
    );
    if (pp is Map) {
      passo = ProximoPassoAcompanhamento(
        codigo: (pp['codigo'] ?? '').toString(),
        rotulo: (pp['rotulo'] ?? '').toString(),
        responsavel: pp['responsavel']?.toString(),
        ehPendenciaConfiguracao:
            pp['ehPendenciaConfiguracao'] == true ||
                pp['eh_pendencia_configuracao'] == true,
      );
    }
    final pend = m['pendencias'];
    return VisaoFornecedorContrato(
      idContrato: (m['idContrato'] ?? m['id_contrato'] ?? '').toString(),
      idOrcamento: (m['idOrcamento'] ?? m['id_orcamento'] ?? '').toString(),
      nomeEvento: (m['nomeEvento'] ?? m['nome_evento'])?.toString(),
      nomeContratante:
          (m['nomeContratante'] ?? m['nome_contratante'])?.toString(),
      nomeServico: (m['nomeServico'] ?? m['nome_servico'])?.toString(),
      valorContratadoCentavos:
          c(m['valorContratadoCentavos'] ?? m['valor_contratado_centavos']),
      direitoLiquidoCentavos: c(m['direitoLiquidoPrevistoCentavos'] ??
          m['direito_liquido_previsto_centavos']),
      comissaoPrevistaCentavos: c(
          m['comissaoPrevistaCentavos'] ?? m['comissao_prevista_centavos']),
      alocadoPlataformaCentavos: c(m['recebidoPlataformaAlocadoCentavos'] ??
          m['recebido_plataforma_alocado_centavos']),
      repasseConfirmadoCentavos: c(
          m['repasseConfirmadoCentavos'] ?? m['repasse_confirmado_centavos']),
      saldoPrevistoRepasseCentavos: c(m['saldoPrevistoRepasseCentavos'] ??
          m['saldo_previsto_repasse_centavos']),
      trataAlocadoComoCaixaProprio: m['trataAlocadoComoCaixaProprio'] == true,
      comissaoJaDescontadaDoRepasse:
          m['comissaoJaDescontadaDoRepasse'] == true ||
              m['comissao_ja_descontada_do_repasse'] == true,
      estadoExecucao:
          (m['estadoExecucao'] ?? m['estado_execucao'] ?? '').toString(),
      pendencias: pend is List
          ? pend.map((e) => e.toString()).toList()
          : const <String>[],
      proximoPasso: passo,
    );
  }
}

class AcompanhamentoPartesService {
  const AcompanhamentoPartesService();

  static const ctasIntegracaoAusente = [
    'Pagar agora',
    'Sacar',
    'Pagamento garantido',
  ];

  String nivelPagamento({
    required int declarado,
    required int conferido,
  }) {
    if (conferido > 0) return 'conferido';
    if (declarado > 0) return 'declarado';
    return 'nao_informado';
  }

  bool podeInformarEntrega(String estado) {
    return estado != 'aceito' &&
        estado != 'cancelado_execucao' &&
        estado != 'entrega_informada';
  }

  bool podeAceitarOuContestar(String estado) =>
      estado == 'entrega_informada';

  /// Cenário Ana × Débora (aceite).
  Map<String, Object?> cenarioAnaDebora({
    int contrato = 1000000,
    int declarado = 400000,
    int confirmado = 400000,
    int bps = 500,
    int repasseConfirmado = 300000,
  }) {
    final nivelAntes = nivelPagamento(declarado: declarado, conferido: 0);
    final direitos = const IntermediacaoFinanceiraService().calcularDireitos(
      valorContratadoCentavos: contrato,
      percentualBps: bps,
      modo: ModoComissaoIntermediacao.descontadaFornecedor,
    );
    return {
      'nivel_antes': nivelAntes,
      'admin_pendencia': nivelAntes == 'declarado',
      'fornecedor_caixa_antes': 0,
      'a_pagar_apos': contrato - confirmado,
      'direito_liquido': direitos.direitoFornecedorPrevistoCentavos,
      'saldo_previsto_repasse':
          direitos.direitoFornecedorPrevistoCentavos - repasseConfirmado,
      'trata_alocado_como_caixa': false,
    };
  }

  ({bool fornecedorEstranho, bool clienteEstranho}) acessoCruzado({
    required String idFornecedorContrato,
    required String idFornecedorConsulta,
    required String idContratanteContrato,
    required String idClienteConsulta,
  }) {
    return (
      fornecedorEstranho: idFornecedorContrato != idFornecedorConsulta,
      clienteEstranho: idContratanteContrato != idClienteConsulta,
    );
  }

  List<String> acoesPermitidasSemIntegracao() => [
        'Registrar declaração de pagamento',
        'Anexar comprovante (não confirma sozinho)',
        'Informar entrega',
        'Registrar aceite',
        'Registrar contestação',
        'Abrir caso de mediação',
      ];

  bool ctaProibidoSemIntegracao(String rotulo) =>
      ctasIntegracaoAusente.contains(rotulo);
}
