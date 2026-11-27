import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/data/local/cache_offline_store.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Usuario extends Fake implements User {
  _Usuario(this.uid);
  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  User? usuario = _Usuario('forn');
  @override
  User? get currentUser => usuario;
}

class _Functions extends Fake implements FirebaseFunctions {}

class _Servidor extends FinanceiroCallableGateway {
  _Servidor() : super(functions: _Functions());
  final chamadas = <String>[];
  Object? erro;

  @override
  Future<Map<String, dynamic>> call(String nome,
      [Map<String, dynamic>? data,
      Duration timeout = const Duration(seconds: 90)]) async {
    chamadas.add(nome);
    final e = erro;
    if (e != null) throw e;
    return {'geradoEm': '2026-11-20T10:00:00Z', 'pendencias': 3};
  }
}

Future<ConectividadeService> _rede(bool online) async {
  final servico = Get.put(ConectividadeService(
    mudancasRede: const Stream.empty(),
    redeAtual: () async =>
        [online ? ConnectivityResult.wifi : ConnectivityResult.none],
    sonda: () async => online,
    intervaloOffline: const Duration(hours: 1),
    intervaloOnline: const Duration(hours: 1),
  ));
  await servico.iniciar();
  return servico;
}

void main() {
  late _Auth auth;
  late _Servidor servidor;
  late MemoriaCacheOffline cache;
  late FirebaseCallableSessaoGateway gateway;

  setUp(() {
    Get.reset();
    auth = _Auth();
    servidor = _Servidor();
    cache = MemoriaCacheOffline();
    gateway = FirebaseCallableSessaoGateway(
        auth: auth, gateway: servidor, cache: cache);
  });

  tearDown(Get.reset);

  test('painel consultado online reabre offline com a data da consulta',
      () async {
    final online = await gateway.chamar('consultarPainelFornecedorFn', {});
    expect(online.containsKey(FirebaseCallableSessaoGateway.chaveAtualizadoEm),
        isFalse);

    await _rede(false);
    final offline = await gateway.chamar('consultarPainelFornecedorFn', {});
    expect(offline['pendencias'], 3);
    expect(offline[FirebaseCallableSessaoGateway.chaveAtualizadoEm], isNotNull);
    expect(servidor.chamadas, hasLength(1));
  });

  test('falha de rede online cai na última consulta', () async {
    await gateway.chamar('consultarAgendaFornecedorFn', {'dias': 7});
    servidor.erro = const FinanceiroCallableException(
        'unavailable', 'SocketException: Failed host lookup');
    final r = await gateway.chamar('consultarAgendaFornecedorFn', {'dias': 7});
    expect(r['pendencias'], 3);
  });

  test('parâmetros diferentes não reaproveitam a resposta', () async {
    await gateway.chamar('consultarAgendaFornecedorFn', {'dias': 7});
    await _rede(false);
    expect(
      () => gateway.chamar('consultarAgendaFornecedorFn', {'dias': 30}),
      throwsA(isA<FirebaseFunctionsException>()
          .having((e) => e.code, 'code', 'unavailable')),
    );
  });

  test('outro usuário no aparelho não vê o painel guardado', () async {
    await gateway.chamar('consultarPainelFornecedorFn', {});
    auth.usuario = _Usuario('outro-fornecedor');
    await _rede(false);
    expect(
      () => gateway.chamar('consultarPainelFornecedorFn', {}),
      throwsA(isA<FirebaseFunctionsException>()),
    );
  });

  test('ação que muda dados falha na hora sem internet', () async {
    await _rede(false);
    final relogio = Stopwatch()..start();
    await expectLater(
      gateway.chamar('registrarMedidaFornecedorFn', {'x': 1}),
      throwsA(isA<FirebaseFunctionsException>().having(
          (e) => e.message, 'mensagem', contains('precisa de internet'))),
    );
    expect(relogio.elapsedMilliseconds, lessThan(200));
    expect(servidor.chamadas, isEmpty);
  });

  test('recusa do servidor não é mascarada pelo cache', () async {
    await gateway.chamar('consultarPainelFornecedorFn', {});
    servidor.erro =
        const FinanceiroCallableException('permission-denied', 'Sem acesso');
    expect(
      () => gateway.chamar('consultarPainelFornecedorFn', {}),
      throwsA(isA<FirebaseFunctionsException>()
          .having((e) => e.code, 'code', 'permission-denied')),
    );
  });
}
