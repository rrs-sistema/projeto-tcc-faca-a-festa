import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';

class Functions extends Fake implements FirebaseFunctions {
  int chamadas = 0;
  @override
  HttpsCallable httpsCallable(String nome, {HttpsCallableOptions? options}) =>
      Consulta(() => chamadas++);
}

class Consulta extends Fake implements HttpsCallable {
  Consulta(this.contar);
  final void Function() contar;
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    contar();
    throw FirebaseFunctionsException(code: 'internal', message: 'internal');
  }
}

class Https extends Fake implements CallableHttpsClient {
  int chamadas = 0;
  @override
  Future<Map<String, dynamic>> call(String nome,
      [Map<String, dynamic>? dados, Duration? timeout]) async {
    chamadas++;
    throw const CallableHttpsException('not-found', 'Serviço não publicado');
  }
}

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test(
      'consulta da jornada recupera diagnóstico HTTP quando SDK devolve internal opaco',
      () async {
    final functions = Functions(), https = Https();
    final gateway =
        FinanceiroCallableGateway(functions: functions, httpsClient: https);
    await expectLater(
        gateway.call('consultarJornadaAtendimentoFn',
            {'idCotacao': 'q', 'idFornecedor': 'f'}),
        throwsA(isA<FinanceiroCallableException>()
            .having((e) => e.code, 'código', 'not-found')));
    expect(functions.chamadas, 1);
    expect(https.chamadas, 1);
  });
  test('internal em comando não é reenviado automaticamente', () async {
    final functions = Functions(), https = Https();
    final gateway =
        FinanceiroCallableGateway(functions: functions, httpsClient: https);
    await expectLater(
        gateway.call('fecharCotacao', {'idCotacao': 'q', 'idFornecedor': 'f'}),
        throwsA(isA<FinanceiroCallableException>()
            .having((e) => e.code, 'código', 'internal')));
    expect(functions.chamadas, 1);
    expect(https.chamadas, 0);
  });
  test('Windows preserva o código HTTP sem passar pelo plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final functions = Functions(), https = Https();
    final gateway =
        FinanceiroCallableGateway(functions: functions, httpsClient: https);
    await expectLater(
        gateway.call('consultarJornadaAtendimentoFn'),
        throwsA(isA<FinanceiroCallableException>()
            .having((e) => e.code, 'código', 'not-found')));
    expect(functions.chamadas, 0);
    expect(https.chamadas, 1);
  });
}
