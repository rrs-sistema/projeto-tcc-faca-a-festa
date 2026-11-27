import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/data/datasources/remote/autenticacao_remote_datasource.dart';
import 'package:app_faca_festa/data/local/marca_mfa_local.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Usuario extends Fake implements User {
  @override
  String get uid => 'org';
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _Usuario();
}

class _Marca extends MarcaMfaLocal {
  _Marca(this.valida);
  bool valida;
  var gravacoes = 0;
  var limpezas = 0;
  @override
  bool confere(User? usuario) => valida;
  @override
  void gravar(User? usuario) {
    gravacoes++;
    valida = true;
  }

  @override
  void limpar() {
    limpezas++;
    valida = false;
  }
}

class _Resultado<T> extends Fake implements HttpsCallableResult<T> {
  _Resultado(this.data);
  @override
  final T data;
}

class _Callable extends Fake implements HttpsCallable {
  _Callable(this._f);
  final _Functions _f;
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    _f.chamadas++;
    final erro = _f.erro;
    if (erro != null) throw erro;
    return _Resultado<T>({'verificada': _f.verificada} as T);
  }
}

class _Functions extends Fake implements FirebaseFunctions {
  var chamadas = 0;
  var verificada = true;
  Object? erro;
  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _Callable(this);
}

Future<void> _rede(bool online) async {
  final servico = Get.put(ConectividadeService(
    mudancasRede: const Stream.empty(),
    redeAtual: () async =>
        [online ? ConnectivityResult.wifi : ConnectivityResult.none],
    sonda: () async => online,
    intervaloOffline: const Duration(hours: 1),
    intervaloOnline: const Duration(hours: 1),
  ));
  await servico.iniciar();
}

void main() {
  late _Functions functions;

  FirebaseAutenticacaoRemoteDatasource ds(_Marca marca) {
    final auth = _Auth();
    return FirebaseAutenticacaoRemoteDatasource(auth,
        functions: functions,
        httpsClient: CallableHttpsClient(auth: auth),
        marcaMfa: marca);
  }

  setUp(() {
    Get.reset();
    functions = _Functions();
  });
  tearDown(Get.reset);

  test('sem internet, o login com MFA já confirmado abre o app', () async {
    await _rede(false);
    expect(await ds(_Marca(true)).sessaoMfaVerificada(), isTrue);
    expect(functions.chamadas, 0);
  });

  test('sem internet e sem confirmação anterior, continua bloqueado',
      () async {
    await _rede(false);
    expect(await ds(_Marca(false)).sessaoMfaVerificada(), isFalse);
  });

  test('online, a resposta do servidor grava ou limpa a marca', () async {
    await _rede(true);
    final marca = _Marca(false);
    expect(await ds(marca).sessaoMfaVerificada(), isTrue);
    expect(marca.gravacoes, 1);

    functions.verificada = false;
    expect(await ds(marca).sessaoMfaVerificada(), isFalse);
    expect(marca.limpezas, 1);
  });

  test('falha de rede na consulta usa a marca do aparelho', () async {
    await _rede(true);
    functions.erro = FirebaseFunctionsException(
        code: 'unavailable', message: 'Failed host lookup');
    expect(await ds(_Marca(true)).sessaoMfaVerificada(), isTrue);
  });

  test('recusa real do servidor não é mascarada pela marca', () async {
    await _rede(true);
    functions.erro = FirebaseFunctionsException(
        code: 'permission-denied', message: 'Sessão inválida');
    expect(() => ds(_Marca(true)).sessaoMfaVerificada(),
        throwsA(isA<AutenticacaoRemoteException>()));
  });
}
