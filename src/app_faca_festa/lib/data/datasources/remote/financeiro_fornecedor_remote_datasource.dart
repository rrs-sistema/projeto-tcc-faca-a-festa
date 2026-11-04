import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import '../../services/consultas_em_andamento.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';

class FinanceiroFornecedorRemoteDatasource {
  FinanceiroFornecedorRemoteDatasource({
    required FirebaseFunctions functions,
    CallableHttpsClient? httpsClient,
    FinanceiroCallableGateway? gateway,
  }) : _gateway = gateway ??
            FinanceiroCallableGateway(
              functions: functions,
              httpsClient: httpsClient,
            );

  final FinanceiroCallableGateway _gateway;
  final _consultas = ConsultasEmAndamento<Map<String, dynamic>>();
  static const timeoutConsulta = Duration(seconds: 30);

  Future<Map<String, dynamic>> consultarResumo({
    required String idFornecedor,
    String? idEvento,
    double? saldoInicial,
    double? comissao,
    double? taxas,
    double? tributos,
  }) {
    final dados = {
      'idFornecedor': idFornecedor,
      if (idEvento != null) 'idEvento': idEvento,
      if (saldoInicial != null) 'saldoInicial': saldoInicial,
      if (comissao != null) 'comissao': comissao,
      if (taxas != null) 'taxas': taxas,
      if (tributos != null) 'tributos': tributos,
    };
    return _consultas.executar(
        jsonEncode(dados),
        () => _gateway.call(
            'consultarResumoFinanceiroFornecedor', dados, timeoutConsulta));
  }

  /// Compatibilidade com resumos publicados antes de incluírem os eventos.
  /// A consulta usa o planejamento autorizado da própria sessão do fornecedor.
  Future<Map<String, dynamic>> consultarEventosDoPlanejamento() =>
      _gateway.call('consultarPlanejamentoFornecedorFn', {}, timeoutConsulta);

  Future<Map<String, dynamic>> registrarCusto({
    required String idFornecedor,
    required String idEvento,
    required String chaveIdempotencia,
    required int valorCentavos,
    String tipo = 'outro',
    String origem = 'manual',
    int previstoRestanteCentavos = 0,
    int desembolsoCentavos = 0,
    bool reutilizavel = false,
    String? descricao,
    String? categoria,
    String? idServico,
    String? referenciaComprovante,
  }) {
    return _gateway.call('registrarCustoInternoFornecedor', {
      'idFornecedor': idFornecedor,
      'idEvento': idEvento,
      'chaveIdempotencia': chaveIdempotencia,
      'valorCentavos': valorCentavos,
      'tipo': tipo,
      'origem': origem,
      'previstoRestanteCentavos': previstoRestanteCentavos,
      'desembolsoCentavos': desembolsoCentavos,
      'reutilizavel': reutilizavel,
      if (descricao != null) 'descricao': descricao,
      if (categoria != null) 'categoria': categoria,
      if (idServico != null) 'idServico': idServico,
      if (referenciaComprovante != null)
        'referenciaComprovante': referenciaComprovante,
    }).whenComplete(_consultas.invalidar);
  }

  Future<Map<String, dynamic>> consultarOperacaoRecebimento({
    required String idFornecedor,
    required String chaveIdempotencia,
    required Map<String, dynamic> pedido,
  }) =>
      _gateway.call('consultarOperacaoRecebimentoFornecedor', {
        'idFornecedor': idFornecedor,
        'chaveIdempotencia': chaveIdempotencia,
        'pedido': pedido,
      });

  Future<Map<String, dynamic>> registrarRecebimento({
    required String idFornecedor,
    required String idEvento,
    required String chaveIdempotencia,
    required int valorCentavos,
    String tipo = 'recebimento',
    bool execucaoConfirmada = false,
    String? idOrcamento,
    List<Map<String, dynamic>>? alocacoes,
    String? referenciaRecebimento,
    String? motivo,
  }) {
    return _gateway.call('registrarRecebimentoFornecedor', {
      'idFornecedor': idFornecedor,
      'idEvento': idEvento,
      'chaveIdempotencia': chaveIdempotencia,
      'valorCentavos': valorCentavos,
      'tipo': tipo,
      'execucaoConfirmada': execucaoConfirmada,
      if (idOrcamento != null) 'idOrcamento': idOrcamento,
      if (alocacoes != null) 'alocacoes': alocacoes,
      if (referenciaRecebimento != null)
        'referenciaRecebimento': referenciaRecebimento,
      if (motivo != null) 'motivo': motivo,
    }).whenComplete(_consultas.invalidar);
  }
}
