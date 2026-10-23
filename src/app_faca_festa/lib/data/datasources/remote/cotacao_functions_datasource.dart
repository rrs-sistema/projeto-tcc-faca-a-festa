import 'package:cloud_functions/cloud_functions.dart';

import '../../services/functions/callable_https_client.dart';

/// Callables do fluxo de cotação (região southamerica-east1).
class CotacaoFunctionsDatasource {
  CotacaoFunctionsDatasource({
    required FirebaseFunctions functions,
    required CallableHttpsClient httpsClient,
  })  : _functions = functions,
        _https = httpsClient;

  final FirebaseFunctions _functions;
  final CallableHttpsClient _https;

  Future<String> criarCotacao({
    required String idEvento,
    required String categoriaNome,
    required String observacao,
    required double valorEstimadoTotal,
    required DateTime dataLimiteResposta,
    required List<String> fornecedoresSelecionados,
    required List<Map<String, dynamic>> servicos,
  }) async {
    final data = await _chamar('criarCotacao', {
      'idEvento': idEvento,
      'categoriaNome': categoriaNome,
      'observacao': observacao,
      'valorEstimadoTotal': valorEstimadoTotal,
      'dataLimiteResposta': dataLimiteResposta.toUtc().toIso8601String(),
      'fornecedoresSelecionados': fornecedoresSelecionados,
      'servicos': servicos,
    });
    return (data['idCotacao'] ?? '').toString();
  }

  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    required String condicaoPagamento,
    required String observacaoFornecedor,
    double? valorProposto,
  }) async {
    await _chamar('responderCotacao', {
      'idCotacao': idCotacao,
      'aceitou': aceitou,
      if (prazoEntrega != null)
        'prazoEntrega': prazoEntrega.toUtc().toIso8601String(),
      'condicaoPagamento': condicaoPagamento,
      'observacaoFornecedor': observacaoFornecedor,
      if (valorProposto != null) 'valorProposto': valorProposto,
    });
  }

  Future<Map<String, dynamic>> fecharCotacao({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String nomeSolicitante,
  }) async {
    return _chamar('fecharCotacao', {
      'idCotacao': idCotacao,
      'idFornecedor': idFornecedor,
      'nomeFornecedor': nomeFornecedor,
      'nomeSolicitante': nomeSolicitante,
    });
  }

  Future<void> cancelarCotacao({
    required String idCotacao,
    String? idFornecedor,
  }) async {
    await _chamar('cancelarCotacao', {
      'idCotacao': idCotacao,
      if (idFornecedor != null && idFornecedor.isNotEmpty)
        'idFornecedor': idFornecedor,
    });
  }

  Future<Map<String, dynamic>> _chamar(
    String nome,
    Map<String, dynamic> data,
  ) async {
    try {
      if (CallableHttpsClient.necessarioNaPlataformaAtual) {
        return _https.call(nome, data);
      }

      final callable = _functions.httpsCallable(
        nome,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final resultado = await callable.call(data);
      final payload = resultado.data;
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) {
        return payload.map((key, value) => MapEntry(key.toString(), value));
      }
      return const {};
    } on FirebaseFunctionsException catch (e) {
      throw CotacaoFunctionsException(
        e.code,
        e.message ?? 'Falha ao processar a cotação.',
      );
    } on CallableHttpsException catch (e) {
      throw CotacaoFunctionsException(
        e.code,
        e.message ?? 'Falha ao processar a cotação.',
      );
    }
  }
}

class CotacaoFunctionsException implements Exception {
  const CotacaoFunctionsException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
