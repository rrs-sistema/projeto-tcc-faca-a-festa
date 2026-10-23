import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';

class IntermediacaoFinanceiraRemote {
  IntermediacaoFinanceiraRemote({
    required FirebaseFunctions functions,
    CallableHttpsClient? httpsClient,
    FinanceiroCallableGateway? gateway,
  }) : _gateway = gateway ??
            FinanceiroCallableGateway(
              functions: functions,
              httpsClient: httpsClient,
            );

  final FinanceiroCallableGateway _gateway;

  Future<Map<String, dynamic>> registrarRecebimento({
    required String idEvento,
    required int valorCentavos,
    required String chaveIdempotencia,
    String? idPagador,
    String nivelConfirmacao = 'conferencia',
    String? referencia,
  }) {
    return _gateway.call('registrarRecebimentoPlataforma', {
      'idEvento': idEvento,
      'valorCentavos': valorCentavos,
      'chaveIdempotencia': chaveIdempotencia,
      if (idPagador != null) 'idPagador': idPagador,
      'nivelConfirmacao': nivelConfirmacao,
      if (referencia != null) 'referencia': referencia,
    });
  }

  Future<Map<String, dynamic>> alocar({
    required String idRecebimento,
    required List<Map<String, dynamic>> alocacoes,
    required String chaveIdempotencia,
  }) {
    return _gateway.call('alocarRecebimentoContratos', {
      'idRecebimento': idRecebimento,
      'alocacoes': alocacoes,
      'chaveIdempotencia': chaveIdempotencia,
    });
  }

  Future<Map<String, dynamic>> prepararRepasse({
    required String idContrato,
    required String idOrcamento,
    required String idFornecedor,
    required int valorCentavos,
    required int percentualBps,
    required int valorContratadoCentavos,
    required String chaveIdempotencia,
    bool autorizarSeElegivel = true,
  }) {
    return _gateway.call('prepararRepasseFornecedor', {
      'idContrato': idContrato,
      'idOrcamento': idOrcamento,
      'idFornecedor': idFornecedor,
      'valorCentavos': valorCentavos,
      'percentualBps': percentualBps,
      'valorContratadoCentavos': valorContratadoCentavos,
      'chaveIdempotencia': chaveIdempotencia,
      'autorizarSeElegivel': autorizarSeElegivel,
      'modoComissao': 'descontada_fornecedor',
    });
  }

  Future<Map<String, dynamic>> confirmarRepasseManual({
    required String idRepasse,
    String? evidencias,
  }) {
    return _gateway.call('confirmarRepasseManual', {
      'idRepasse': idRepasse,
      if (evidencias != null) 'evidencias': evidencias,
    });
  }

  Future<Map<String, dynamic>> salvarPoliticaLiberacao({
    String? idPolitica,
    required bool ativa,
    required bool permiteRepasseParcial,
    int? tetoParcialCentavos,
  }) {
    return _gateway.call('salvarPoliticaLiberacaoRepasse', {
      if (idPolitica != null && idPolitica.isNotEmpty) 'idPolitica': idPolitica,
      'ativa': ativa,
      'permiteRepasseParcial': permiteRepasseParcial,
      if (tetoParcialCentavos != null)
        'tetoParcialCentavos': tetoParcialCentavos,
    });
  }

  Future<Map<String, dynamic>> consultarExtrato(String idEvento) {
    return _gateway.call('consultarExtratoIntermediacao', {
      'idEvento': idEvento,
    });
  }

  Future<Map<String, dynamic>> simularPosicao({
    required int valorContratadoCentavos,
    int percentualBps = 500,
    int recebimentosPedidoCentavos = 0,
    int alocadoCentavos = 0,
    int alocadoPedidoCentavos = 0,
    int repassadoConfirmadoCentavos = 0,
    Map<String, dynamic>? politica,
  }) {
    return _gateway.call('simularPosicaoIntermediacao', {
      'valorContratadoCentavos': valorContratadoCentavos,
      'percentualBps': percentualBps,
      'recebimentosPedidoCentavos': recebimentosPedidoCentavos,
      'alocadoCentavos': alocadoCentavos,
      'alocadoPedidoCentavos': alocadoPedidoCentavos,
      'repassadoConfirmadoCentavos': repassadoConfirmadoCentavos,
      if (politica != null) 'politica': politica,
      'modoComissao': 'descontada_fornecedor',
    });
  }
}
