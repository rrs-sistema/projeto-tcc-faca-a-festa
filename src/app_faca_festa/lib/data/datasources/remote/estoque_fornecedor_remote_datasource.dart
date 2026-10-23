import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';

class EstoqueFornecedorRemoteDatasource {
  EstoqueFornecedorRemoteDatasource({
    required FirebaseFunctions functions,
    CallableHttpsClient? httpsClient,
    FinanceiroCallableGateway? gateway,
  }) : _gateway = gateway ??
            FinanceiroCallableGateway(
              functions: functions,
              httpsClient: httpsClient,
            );

  final FinanceiroCallableGateway _gateway;

  Future<Map<String, dynamic>> cadastrarItem({
    required String idFornecedor,
    required String nome,
    required String natureza,
    required int quantidadeTotal,
    required int custoUnitarioCentavos,
    String unidade = 'un',
    int custoUsoCentavos = 0,
    int custoLocacaoCentavos = 0,
    int montagemMinutos = 0,
    int transporteMinutos = 0,
    int desmontagemMinutos = 0,
    String? validade,
    String? lote,
    String? localizacao,
  }) {
    return _gateway.call('cadastrarItemEstoqueFornecedor', {
      'idFornecedor': idFornecedor,
      'nome': nome,
      'natureza': natureza,
      'quantidadeTotal': quantidadeTotal,
      'custoUnitarioCentavos': custoUnitarioCentavos,
      'unidade': unidade,
      'custoUsoCentavos': custoUsoCentavos,
      'custoLocacaoCentavos': custoLocacaoCentavos,
      'montagemMinutos': montagemMinutos,
      'transporteMinutos': transporteMinutos,
      'desmontagemMinutos': desmontagemMinutos,
      if (validade != null) 'validade': validade,
      if (lote != null) 'lote': lote,
      if (localizacao != null) 'localizacao': localizacao,
    });
  }

  Future<Map<String, dynamic>> reservar({
    required String idFornecedor,
    required String idItem,
    required String idEvento,
    required int quantidade,
    required String inicioIso,
    required String fimIso,
    required String chaveIdempotencia,
  }) {
    return _gateway.call('reservarEstoqueFornecedor', {
      'idFornecedor': idFornecedor,
      'idItem': idItem,
      'idEvento': idEvento,
      'quantidade': quantidade,
      'inicio': inicioIso,
      'fim': fimIso,
      'chaveIdempotencia': chaveIdempotencia,
    });
  }

  Future<Map<String, dynamic>> retirar({
    required String idFornecedor,
    required String idReserva,
  }) {
    return _gateway.call('retirarEstoqueFornecedor', {
      'idFornecedor': idFornecedor,
      'idReserva': idReserva,
    });
  }

  Future<Map<String, dynamic>> consumir({
    required String idFornecedor,
    required String idItem,
    required String idEvento,
    required int quantidade,
    required String chaveIdempotencia,
    String? idReserva,
  }) {
    return _gateway.call('consumirEstoqueFornecedor', {
      'idFornecedor': idFornecedor,
      'idItem': idItem,
      'idEvento': idEvento,
      'quantidade': quantidade,
      'chaveIdempotencia': chaveIdempotencia,
      if (idReserva != null) 'idReserva': idReserva,
    });
  }

  Future<Map<String, dynamic>> cancelarReserva({
    required String idFornecedor,
    required String idReserva,
  }) {
    return _gateway.call('cancelarReservaEstoqueFornecedor', {
      'idFornecedor': idFornecedor,
      'idReserva': idReserva,
    });
  }

  Future<Map<String, dynamic>> consultar({required String idFornecedor}) {
    return _gateway.call('consultarEstoqueFornecedor', {
      'idFornecedor': idFornecedor,
    });
  }
}
