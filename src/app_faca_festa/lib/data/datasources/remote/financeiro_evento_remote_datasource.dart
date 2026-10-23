import 'package:cloud_functions/cloud_functions.dart';

/// Comandos financeiros críticos via Cloud Functions (Admin SDK + auth própria).
class FinanceiroEventoRemoteDatasource {
  FinanceiroEventoRemoteDatasource({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> registrarContrato({
    required String idEvento,
    required String idOrcamento,
    int? valorCentavos,
    double? valorReais,
    String? idNecessidade,
    String? motivo,
  }) async {
    final callable = _functions.httpsCallable('registrarContratoFinanceiro');
    final result = await callable.call(<String, dynamic>{
      'idEvento': idEvento,
      'idOrcamento': idOrcamento,
      if (valorCentavos != null) 'valorCentavos': valorCentavos,
      if (valorReais != null) 'valorReais': valorReais,
      if (idNecessidade != null) 'idNecessidade': idNecessidade,
      if (motivo != null) 'motivo': motivo,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> cancelarContrato({
    required String idEvento,
    required String idOrcamento,
    required String motivo,
    int retencaoCentavos = 0,
    int reembolsoCentavos = 0,
  }) async {
    final callable = _functions.httpsCallable('cancelarContratoFinanceiro');
    final result = await callable.call(<String, dynamic>{
      'idEvento': idEvento,
      'idOrcamento': idOrcamento,
      'motivo': motivo,
      'retencaoCentavos': retencaoCentavos,
      'reembolsoCentavos': reembolsoCentavos,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> registrarLiquidacao({
    required String idEvento,
    required String idOrcamento,
    required String chaveIdempotencia,
    int? valorCentavos,
    double? valorReais,
    String tipo = 'pagamento',
    String? motivo,
    String? confirmacao,
  }) async {
    final callable = _functions.httpsCallable('registrarLiquidacaoFinanceira');
    final result = await callable.call(<String, dynamic>{
      'idEvento': idEvento,
      'idOrcamento': idOrcamento,
      'chaveIdempotencia': chaveIdempotencia,
      if (valorCentavos != null) 'valorCentavos': valorCentavos,
      if (valorReais != null) 'valorReais': valorReais,
      'tipo': tipo,
      if (motivo != null) 'motivo': motivo,
      if (confirmacao != null) 'confirmacao': confirmacao,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
