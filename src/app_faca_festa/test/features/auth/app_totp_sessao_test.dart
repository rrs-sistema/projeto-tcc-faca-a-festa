import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_totp_sessao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetStorage storage;
  late AppTotpSessao totp;
  var temSenha = true;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  setUp(() async {
    await GetStorage.init('totp_sessao_qa');
    storage = GetStorage('totp_sessao_qa');
    await storage.erase();
    temSenha = true;
    totp = AppTotpSessao(storage, contaTemLoginComSenha: () => temSenha);
  });

  test('login com senha exige MFA até marcar verificado', () {
    totp.marcarLoginComSenha();
    expect(totp.deveExigir(), isTrue);
    totp.marcarVerificado();
    expect(totp.deveExigir(), isFalse);
  });

  test('login com Google não exige MFA nesta sessão', () {
    totp.marcarLoginComGoogle();
    expect(totp.deveExigir(), isFalse);
    totp.limpar();
    totp.marcarLoginComSenha();
    expect(totp.deveExigir(), isTrue);
  });

  test('conta sem provedor de senha não exige MFA', () {
    temSenha = false;
    totp.marcarLoginComSenha();
    expect(totp.deveExigir(), isFalse);
  });
}
