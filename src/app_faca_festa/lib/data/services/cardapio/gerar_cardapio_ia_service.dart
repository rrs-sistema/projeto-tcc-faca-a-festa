import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/domain/entities/sugestao_cardapio_ia.dart';

import 'package:app_faca_festa/data/services/functions/exigir_conexao_functions.dart';
class GerarCardapioIaException implements Exception {
  const GerarCardapioIaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cliente da callable `gerarCardapioIA` (Windows via HTTPS direto).
class GerarCardapioIaService {
  GerarCardapioIaService({
    FirebaseFunctions? functions,
    CallableHttpsClient? httpsClient,
    this.functionName = 'gerarCardapioIA',
    this.timeout = const Duration(seconds: 90),
  })  : _functions = functions,
        _https = httpsClient;

  final FirebaseFunctions? _functions;
  final CallableHttpsClient? _https;
  final String functionName;
  final Duration timeout;

  factory GerarCardapioIaService.fromGet() {
    return GerarCardapioIaService(
      functions: Get.isRegistered<FirebaseFunctions>()
          ? Get.find<FirebaseFunctions>()
          : null,
      httpsClient: Get.isRegistered<CallableHttpsClient>()
          ? Get.find<CallableHttpsClient>()
          : null,
    );
  }

  Future<SugestaoCardapioIa> gerar(EntradaGeracaoCardapioIa entrada) async {
    if (entrada.idEvento.trim().isEmpty) {
      throw const GerarCardapioIaException('Informe o evento.');
    }
    if (entrada.tipoFesta.trim().isEmpty) {
      throw const GerarCardapioIaException('Informe o tipo de festa.');
    }
    if (entrada.momentoRefeicao.trim().isEmpty) {
      throw const GerarCardapioIaException('Informe o momento da refeição.');
    }
    if (entrada.totalPessoas <= 0) {
      throw const GerarCardapioIaException(
        'A quantidade de pessoas deve ser maior que zero.',
      );
    }

    try {
      final raw = await _chamar(entrada.toPayload());
      return SugestaoCardapioIa.fromMap(raw);
    } on GerarCardapioIaException {
      rethrow;
    } on FormatException {
      throw const GerarCardapioIaException(
        'Não foi possível gerar o cardápio agora. Tente novamente.',
      );
    } on FirebaseFunctionsException catch (e) {
      throw GerarCardapioIaException(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Não foi possível gerar o cardápio agora. Tente novamente.',
      );
    } on CallableHttpsException catch (e) {
      throw GerarCardapioIaException(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Não foi possível gerar o cardápio agora. Tente novamente.',
      );
    } catch (_) {
      throw const GerarCardapioIaException(
        'Não foi possível gerar o cardápio agora. Tente novamente.',
      );
    }
  }

  Future<Map<String, dynamic>> _chamar(Map<String, dynamic> payload) async {
    if (CallableHttpsClient.necessarioNaPlataformaAtual) {
      final https = _https;
      if (https == null) {
        throw const GerarCardapioIaException(
          'Cliente de funções indisponível neste dispositivo.',
        );
      }
      return https.call(functionName, payload, timeout);
    }

    final functions = _functions;
    if (functions == null) {
      throw const GerarCardapioIaException(
        'Serviço de funções não configurado.',
      );
    }

    try {
      garantirConexaoFunctions('Gerar o cardápio com IA');
      final callable = functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );
      final resultado = await callable.call(payload);
      return _asMap(resultado.data);
    } on FirebaseFunctionsException catch (e) {
      final code = e.code.toLowerCase();
      if (_https != null &&
          (code == 'not-found' ||
              code == 'unavailable' ||
              (e.message ?? '').toLowerCase().contains('html'))) {
        return _https.call(functionName, payload, timeout);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    throw const FormatException('Resposta inválida da geração de cardápio.');
  }
}
