import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/data/models/usuario/usuario_model.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_totp_sessao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetStorage storage;
  late AppTotpSessao totp;
  const base =
      Usuario(idUsuario: 'usuario', nome: 'Usuário', email: 'qa@example.test');

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
    totp = AppTotpSessao(storage);
  });

  for (final tipo in ['O', 'C', 'F', 'A']) {
    for (final google in [false, true]) {
      test('perfil $tipo, Google=$google aplica a política de MFA', () {
        if (google) {
          totp.marcarLoginComGoogle();
        } else {
          totp.marcarLoginComSenha();
        }
        final usuario = base.copyWith(tipo: tipo);
        expect(totp.deveExigir(usuario), tipo == 'F' || tipo == 'A');
        totp.marcarVerificado(usuario.idUsuario);
        expect(totp.deveExigir(usuario), isFalse);
      });
    }
  }

  test('métodos antigos não ativam a preferência opcional', () {
    final legado = UsuarioModel.fromMap({
      'id_usuario': 'legado',
      'nome': 'Legado',
      'email': base.email,
      'tipo': 'O',
      'mfa_email_ativo': true,
      'mfa_totp_ativo': true,
    });
    expect(legado.mfaLoginOpcional, isFalse);
    expect(totp.deveExigir(legado), isFalse);
  });

  test('opção voluntária exige MFA, inclusive pelo Google', () {
    totp.marcarLoginComGoogle();
    final usuario = base.copyWith(tipo: 'O', mfaLoginOpcional: true);
    expect(totp.deveExigir(usuario), isTrue);
    totp.marcarVerificado(usuario.idUsuario);
    expect(totp.deveExigir(usuario), isFalse);
    expect(totp.deveExigir(usuario.copyWith(idUsuario: 'outro')), isTrue);
    totp.limpar();
    expect(totp.deveExigir(usuario), isTrue);
  });
}
