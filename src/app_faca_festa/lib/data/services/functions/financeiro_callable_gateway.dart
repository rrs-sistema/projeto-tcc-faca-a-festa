import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';

/// Gateway único para callables financeiras.
/// Windows: HTTP direto (plugin pigeon falha). Web/mobile: `httpsCallable`.
class FinanceiroCallableGateway {
  FinanceiroCallableGateway({
    required FirebaseFunctions functions,
    CallableHttpsClient? httpsClient,
  })  : _functions = functions,
        _https = httpsClient;

  final FirebaseFunctions _functions;
  final CallableHttpsClient? _https;

  factory FinanceiroCallableGateway.fromGet() {
    return FinanceiroCallableGateway(
      functions: Get.find<FirebaseFunctions>(),
      httpsClient: Get.isRegistered<CallableHttpsClient>()
          ? Get.find<CallableHttpsClient>()
          : null,
    );
  }

  Future<Map<String, dynamic>> call(
    String nome, [
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 90),
  ]) async {
    final payload = data ?? <String, dynamic>{};
    try {
      // Windows: HTTPS direto (plugin pigeon falha).
      // Web/mobile: httpsCallable; se o plugin devolver HTML/404 opaco,
      // tenta o mesmo endpoint HTTPS quando o cliente estiver registrado.
      if (CallableHttpsClient.necessarioNaPlataformaAtual) {
        return _callHttps(nome, payload, timeout);
      }

      try {
        final callable = _functions.httpsCallable(
          nome,
          options: HttpsCallableOptions(timeout: timeout),
        );
        final resultado = await callable.call(payload);
        final raw = resultado.data;
        if (raw is Map<String, dynamic>) return raw;
        if (raw is Map) {
          return raw.map((k, v) => MapEntry(k.toString(), v));
        }
        return const {};
      } on FirebaseFunctionsException catch (e) {
        final code = e.code.toLowerCase();
        if (_https != null &&
            (code == 'not-found' ||
                code == 'unavailable' ||
                (e.message ?? '').toLowerCase().contains('html'))) {
          return _callHttps(nome, payload, timeout);
        }
        throw FinanceiroCallableException(
          e.code,
          e.message ?? 'Falha na função financeira.',
        );
      }
    } on FinanceiroCallableException {
      rethrow;
    } on CallableHttpsException catch (e) {
      throw FinanceiroCallableException(
        e.code,
        e.message ?? 'Falha na função financeira.',
      );
    } on FormatException catch (e) {
      // HTML/404 da URL cloudfunctions.net sem function deployada.
      throw FinanceiroCallableException(
        'unavailable',
        e.message.isNotEmpty
            ? e.message
            : 'Resposta inválida da function financeira.',
      );
    }
  }

  Future<Map<String, dynamic>> _callHttps(
    String nome,
    Map<String, dynamic> payload,
    Duration timeout,
  ) {
    final https = _https;
    if (https == null) {
      throw const FinanceiroCallableException(
        'failed-precondition',
        'Cliente HTTPS financeiro indisponível nesta plataforma.',
      );
    }
    return https.call(nome, payload, timeout);
  }
}

class FinanceiroCallableException implements Exception {
  const FinanceiroCallableException(this.code, [this.message]);

  final String code;
  final String? message;

  bool get podeUsarFallbackLocal {
    final c = code.toLowerCase();
    final m = message?.toLowerCase() ?? '';
    return c == 'internal' ||
        c == 'not-found' ||
        c == 'unavailable' ||
        c == 'deadline-exceeded' ||
        c.contains('channel') ||
        c.contains('pigeon') ||
        m.contains('pigeon') ||
        m.contains('unable to establish') ||
        m.contains('html') ||
        m.contains('não-json') ||
        m.contains('nao-json') ||
        m.contains('formatexception');
  }

  @override
  String toString() =>
      message?.trim().isNotEmpty == true ? '[$code] $message' : code;
}
