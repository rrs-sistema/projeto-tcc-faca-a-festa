import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';

class LgpdFunctionsException implements Exception {
  const LgpdFunctionsException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class LgpdFunctionsClient {
  LgpdFunctionsClient({
    FirebaseFunctions? functions,
    CallableHttpsClient? https,
  })  : _functions = functions ?? Get.find<FirebaseFunctions>(),
        _https = https ?? Get.find<CallableHttpsClient>();

  final FirebaseFunctions _functions;
  final CallableHttpsClient _https;

  Future<String> exportarDossie({String? idUsuario}) async {
    final data = await _chamar(
      'exportarDossieTitular',
      {if (idUsuario != null && idUsuario.isNotEmpty) 'idUsuario': idUsuario},
      const Duration(seconds: 60),
    );
    final texto = data['texto']?.toString() ?? '';
    if (texto.trim().isEmpty) {
      throw const LgpdFunctionsException(
        'failed-precondition',
        'O dossiê voltou vazio.',
      );
    }
    return texto;
  }

  Future<String> atender({
    required String idUsuario,
    required String idSolicitacao,
    required String acao,
  }) async {
    final data = await _chamar(
      'atenderSolicitacaoLgpd',
      {
        'idUsuario': idUsuario,
        'idSolicitacao': idSolicitacao,
        'acao': acao,
      },
      const Duration(seconds: 120),
    );
    return data['resultado']?.toString() ?? 'Pedido atualizado.';
  }

  Future<Map<String, dynamic>> _chamar(
    String nome,
    Map<String, dynamic> data,
    Duration timeout,
  ) async {
    try {
      if (CallableHttpsClient.necessarioNaPlataformaAtual) {
        return _https.call(nome, data, timeout);
      }
      final callable = _functions.httpsCallable(
        nome,
        options: HttpsCallableOptions(timeout: timeout),
      );
      final resultado = await callable.call(data);
      final payload = resultado.data;
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) {
        return payload.map((key, value) => MapEntry(key.toString(), value));
      }
      return const {};
    } on FirebaseFunctionsException catch (e) {
      throw LgpdFunctionsException(
        e.code,
        e.message ?? 'Não foi possível concluir o pedido.',
      );
    } on CallableHttpsException catch (e) {
      throw LgpdFunctionsException(
        e.code,
        e.message ?? 'Não foi possível concluir o pedido.',
      );
    }
  }
}
