import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';

class AcompanhamentoPartesRemote {
  AcompanhamentoPartesRemote({
    required FirebaseFunctions functions,
    CallableHttpsClient? httpsClient,
    FinanceiroCallableGateway? gateway,
  }) : _gateway = gateway ??
            FinanceiroCallableGateway(
              functions: functions,
              httpsClient: httpsClient,
            );

  final FinanceiroCallableGateway _gateway;

  Future<Map<String, dynamic>> consultarOrganizador({
    required String idEvento,
  }) {
    return _gateway.call('consultarAcompanhamentoOrganizador', {
      'idEvento': idEvento,
    });
  }

  Future<Map<String, dynamic>> consultarFornecedor({
    required String idFornecedor,
  }) {
    return _gateway.call('consultarAcompanhamentoFornecedor', {
      'idFornecedor': idFornecedor,
    });
  }

  Future<Map<String, dynamic>> declararPagamento({
    required String idEvento,
    required String idOrcamento,
    required int valorCentavos,
    required String chaveIdempotencia,
    String? referenciaComprovante,
  }) {
    return _gateway.call('declararPagamentoPlataforma', {
      'idEvento': idEvento,
      'idOrcamento': idOrcamento,
      'valorCentavos': valorCentavos,
      'chaveIdempotencia': chaveIdempotencia,
      if (referenciaComprovante != null)
        'referenciaComprovante': referenciaComprovante,
    });
  }

  Future<Map<String, dynamic>> informarEntrega({
    required String idOrcamento,
    required String chaveIdempotencia,
    String? motivo,
  }) {
    return _gateway.call('informarEntregaFornecedor', {
      'idOrcamento': idOrcamento,
      'chaveIdempotencia': chaveIdempotencia,
      if (motivo != null) 'motivo': motivo,
    });
  }

  Future<Map<String, dynamic>> registrarAceite({
    required String idOrcamento,
    required String chaveIdempotencia,
    bool contestar = false,
    String? motivo,
  }) {
    return _gateway.call('registrarAceiteCliente', {
      'idOrcamento': idOrcamento,
      'chaveIdempotencia': chaveIdempotencia,
      'contestar': contestar,
      if (motivo != null) 'motivo': motivo,
    });
  }

  Future<Map<String, dynamic>> abrirCasoParte({
    required String idOrcamento,
    required String motivo,
    required String chaveIdempotencia,
    String? descricao,
    String categoria = 'divergencia_servico',
  }) {
    return _gateway.call('abrirCasoMediacaoParte', {
      'idOrcamento': idOrcamento,
      'motivo': motivo,
      'chaveIdempotencia': chaveIdempotencia,
      if (descricao != null) 'descricao': descricao,
      'categoria': categoria,
    });
  }
}
