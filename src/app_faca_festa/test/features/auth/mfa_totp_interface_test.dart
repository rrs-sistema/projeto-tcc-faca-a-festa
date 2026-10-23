import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/datasources/remote/autenticacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/autenticacao_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/totp_setup_screen.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/totp_verify_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _AuthRemoteMfaQA extends Fake implements AutenticacaoRemoteDatasource {
  static const secretFixo = 'JBSWY3DPEHPK3PXP';
  static const otpauthFixo =
      'otpauth://totp/Faca%20a%20Festa:mfa-owner%40example.test'
      '?secret=JBSWY3DPEHPK3PXP&issuer=Faca%20a%20Festa'
      '&algorithm=SHA1&digits=6&period=30';

  var confirmacoes = 0;
  var verificacoes = 0;
  final codigosConfirmados = <String>[];
  final codigosVerificados = <String>[];

  @override
  Future<InicioTotpMfa> iniciarTotpMfa() async =>
      const InicioTotpMfa(secret: secretFixo, otpauthUrl: otpauthFixo);

  @override
  Future<void> confirmarTotpMfa(String codigo) async {
    confirmacoes++;
    codigosConfirmados.add(codigo);
    if (codigo != '123456') {
      throw const AutenticacaoRemoteException('permission-denied');
    }
  }

  @override
  Future<void> verificarTotpMfa(String codigo) async {
    verificacoes++;
    codigosVerificados.add(codigo);
    if (codigo != '654321') {
      throw const AutenticacaoRemoteException('permission-denied');
    }
  }
}

class AppMfaQA extends Fake implements AppController {
  var totpVerificado = 0;

  @override
  void marcarTotpVerificado() => totpVerificado++;

  @override
  Future<void> logout() async {}
}

Future<void> _assentar(WidgetTester tester) async {
  EasyLoading.dismiss();
  Get.closeAllSnackbars();
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AuthRemoteMfaQA remote;
  late AutenticacaoRepositoryImpl repo;
  late AppMfaQA app;

  setUp(() {
    remote = _AuthRemoteMfaQA();
    repo = AutenticacaoRepositoryImpl(remote);
    app = AppMfaQA();
    Get.reset();
    Get.testMode = true;
  });

  testWidgets('setup TOTP: escolha, QR, código errado e confirmação',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setupCtrl = TotpMfaController(
        autenticacaoRepository: repo, appController: app);
    var splash = 0;

    await tester.pumpWidget(GetMaterialApp(
      builder: EasyLoading.init(),
      initialRoute: '/loginTotpSetup',
      getPages: [
        GetPage(
            name: '/loginTotpSetup',
            page: () => TotpSetupScreen(
                controller: setupCtrl,
                themeController: EventThemeController())),
        GetPage(
            name: '/splash',
            page: () {
              splash++;
              return const Scaffold(body: Text('Sessão MFA'));
            }),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Verificação em duas etapas'), findsOneWidget);
    expect(find.text('App autenticador'), findsOneWidget);
    expect(find.text('Código por e-mail'), findsOneWidget);

    await tester.tap(find.text('App autenticador'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('JBSWY3DPEHPK3PXP'), findsWidgets);
    expect(find.text('Confirmar autenticador'), findsOneWidget);

    setupCtrl.codigo.value = '000000';
    await setupCtrl.confirmarCadastro();
    await tester.pump();
    expect(find.text('Código incorreto.'), findsWidgets);
    expect(splash, 0);
    expect(app.totpVerificado, 0);
    expect(remote.confirmacoes, 1);
    await _assentar(tester);

    setupCtrl.codigo.value = '123456';
    await setupCtrl.confirmarCadastro();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(app.totpVerificado, 1);
    expect(remote.confirmacoes, 2);
    expect(remote.codigosConfirmados.last, '123456');
    expect(splash, 1);
    expect(find.text('Sessão MFA'), findsOneWidget);
    await _assentar(tester);
  });

  testWidgets('desafio TOTP: código errado e entrada', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final verifyCtrl = TotpMfaController(
        autenticacaoRepository: repo, appController: app);
    var splash = 0;

    await tester.pumpWidget(GetMaterialApp(
      builder: EasyLoading.init(),
      getPages: [
        GetPage(
            name: '/loginTotp',
            page: () => TotpVerifyScreen(
                controller: verifyCtrl,
                themeController: EventThemeController())),
        GetPage(
            name: '/splash',
            page: () {
              splash++;
              return const Scaffold(body: Text('Sessão MFA'));
            }),
      ],
      initialRoute: '/loginTotp',
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Confirmar e entrar'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    verifyCtrl.codigo.value = '111111';
    await verifyCtrl.verificarLogin();
    await tester.pump();
    expect(find.text('Código incorreto.'), findsWidgets);
    expect(splash, 0);
    expect(remote.verificacoes, 1);
    await _assentar(tester);

    verifyCtrl.codigo.value = '654321';
    await verifyCtrl.verificarLogin();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(app.totpVerificado, 1);
    expect(remote.verificacoes, 2);
    expect(remote.codigosVerificados.last, '654321');
    expect(splash, 1);
    expect(find.text('Sessão MFA'), findsOneWidget);
    await _assentar(tester);
    expect(tester.takeException(), isNull);
  });
}
