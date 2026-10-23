import 'package:cloud_functions/cloud_functions.dart';

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

  Future<Map<String, dynamic>> consultarResumo({
    required String idFornecedor,
    String? idEvento,
    double? saldoInicial,
    double? comissao,
    double? taxas,
    double? tributos,
  }) {
    // Timeout curto: a tela não deve ficar bloqueada em cold start longo.
    return _gateway.call(
      'consultarResumoFinanceiroFornecedor',
      {
        'idFornecedor': idFornecedor,
        if (idEvento != null) 'idEvento': idEvento,
        if (saldoInicial != null) 'saldoInicial': saldoInicial,
        if (comissao != null) 'comissao': comissao,
        if (taxas != null) 'taxas': taxas,
        if (tributos != null) 'tributos': tributos,
      },
      const Duration(seconds: 15),
    );
  }

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
    });
  }

  Future<Map<String, dynamic>> registrarRecebimento({
    required String idFornecedor,
    required String idEvento,
    required String chaveIdempotencia,
    required int valorCentavos,
    String tipo = 'recebimento',
    bool execucaoConfirmada = false,
    String? idOrcamento,
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
      if (motivo != null) 'motivo': motivo,
    });
  }
}
