import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/data/local/cache_offline_store.dart';
import 'package:app_faca_festa/data/services/convite/abrir_convite_por_token_service.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/domain/services/abrir_convite_por_token.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Usuario extends Fake implements User {
  _Usuario(this.uid);
  @override
  final String uid;
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'token';
}

class _Credencial extends Fake implements UserCredential {}

class _Auth extends Fake implements FirebaseAuth {
  User? usuario;
  @override
  User? get currentUser => usuario;
  @override
  Future<UserCredential> signInWithCustomToken(String token) async {
    usuario = _Usuario('c_convidado');
    return _Credencial();
  }
}

class _Resultado<T> extends Fake implements HttpsCallableResult<T> {
  _Resultado(this.data);
  @override
  final T data;
}

class _Callable extends Fake implements HttpsCallable {
  _Callable(this._functions);
  final _Functions _functions;
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    _functions.chamadas++;
    final erro = _functions.erro;
    if (erro != null) throw erro;
    return _Resultado<T>(_functions.resposta as T);
  }
}

class _Functions extends Fake implements FirebaseFunctions {
  Object? erro;
  var chamadas = 0;
  final resposta = <String, dynamic>{
    'tokenSessao': 'sessao-qa',
    'convidado': {
      'id_convidado': 'conv-1',
      'id_evento': 'evt-1',
      'nome': 'Ana',
    },
    'evento': {
      'id_evento': 'evt-1',
      'nome_evento': 'Aniversário',
      'id_usuario': 'org',
    },
  };
  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _Callable(this);
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
  late _Functions functions;
  late MemoriaCacheOffline cache;
  late AbrirConvitePorTokenService servico;

  setUp(() {
    Get.reset();
    auth = _Auth();
    functions = _Functions();
    cache = MemoriaCacheOffline();
    servico = AbrirConvitePorTokenService(
      functions: functions,
      auth: auth,
      httpsClient: CallableHttpsClient(auth: auth),
      cache: cache,
    );
  });

  tearDown(Get.reset);

  test('convite aberto com internet reabre sem internet', () async {
    final online = await servico.abrir('TOKEN-1');
    expect(online.convidado.idConvidado, 'conv-1');
    expect(cache.valores.values.single, isNot(contains('sessao-qa')),
        reason: 'o token de sessão não fica no aparelho');

    final rede = await _rede(false);
    expect(rede.offline, isTrue);
    final offline = await servico.abrir('TOKEN-1');
    expect(offline.evento.idEvento, 'evt-1');
    expect(functions.chamadas, 1, reason: 'offline não chama o servidor');
  });

  test('falha de rede online também usa a cópia do aparelho', () async {
    await servico.abrir('TOKEN-1');
    functions.erro = FirebaseFunctionsException(
        code: 'unavailable', message: 'Failed host lookup');
    final res = await servico.abrir('TOKEN-1');
    expect(res.convidado.nome, 'Ana');
  });

  test('outra sessão no aparelho não abre o convite guardado', () async {
    await servico.abrir('TOKEN-1');
    auth.usuario = _Usuario('outra-pessoa');
    await _rede(false);
    expect(
      () => servico.abrir('TOKEN-1'),
      throwsA(isA<AbrirConvitePorTokenException>()
          .having((e) => e.codigo, 'codigo', 'unavailable')),
    );
  });

  test('sem cópia e sem internet o aviso diz para abrir uma vez online',
      () async {
    auth.usuario = _Usuario('c_convidado');
    await _rede(false);
    expect(
      () => servico.abrir('TOKEN-NUNCA-ABERTO'),
      throwsA(isA<AbrirConvitePorTokenException>().having((e) => e.mensagem,
          'mensagem', AbrirConvitePorTokenService.mensagemSemCache)),
    );
  });

  test('convite inválido continua sendo recusado, sem cair no cache',
      () async {
    await servico.abrir('TOKEN-1');
    functions.erro = FirebaseFunctionsException(
        code: 'not-found', message: 'Convite não encontrado');
    expect(
      () => servico.abrir('TOKEN-1'),
      throwsA(isA<AbrirConvitePorTokenException>()
          .having((e) => e.codigo, 'codigo', 'not-found')),
    );
  });
}
