import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/data/datasources/remote/autenticacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/autenticacao_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
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
  final recuperacoes = <String>[];
  var enviosPorEmail = 0;
  var geracoesRecuperacao = 0;
  var autorizacaoEmail = '';

  @override
  String get idUsuarioAtual => 'mfa-owner';

  @override
  Future<InicioTotpMfa> iniciarTotpMfa({String? autorizacao}) async =>
      const InicioTotpMfa(secret: secretFixo, otpauthUrl: otpauthFixo);

  @override
  Future<String> confirmarTotpMfa(String codigo, {String? autorizacao}) async {
    confirmacoes++;
    codigosConfirmados.add(codigo);
    if (codigo != '123456') {
      throw const AutenticacaoRemoteException('permission-denied');
    }
    return 'prova-qa';
  }

  @override
  Future<String> verificarTotpMfa(String codigo) async {
    verificacoes++;
    codigosVerificados.add(codigo);
    if (codigo != '654321') {
      throw const AutenticacaoRemoteException('permission-denied');
    }
    return '';
  }

  @override
  Future<CodigoEmailMfa> solicitarCodigoEmailMfa({String? autorizacao}) async {
    enviosPorEmail++;
    return const CodigoEmailMfa(emailMascarado: 'qa***@example.test');
  }

  @override
  Future<String> verificarEmailMfa(String codigo) async {
    expectSync(codigo, '135790');
    return autorizacaoEmail;
  }

  @override
  Future<String> verificarCodigoRecuperacaoMfa(String codigo) async {
    recuperacoes.add(codigo);
    return 'prova-qa';
  }

  @override
  Future<List<String>> gerarCodigosRecuperacaoMfa(String autorizacao) async {
    expectSync(autorizacao, 'prova-qa');
    geracoesRecuperacao++;
    return ['0123-4567-89AB-CDEF-0123-4567-89AB-CDEF'];
  }
}

class AppMfaQA extends Fake implements AppController {
  var totpVerificado = 0;

  @override
  Future<Usuario?> obterUsuario(String id) async => null;

  @override
  Future<void> concluirMfa(String? idUsuario) async {
    expectSync(idUsuario, 'mfa-owner');
    totpVerificado++;
  }

  @override
  Future<void> logout() async {}
}

Future<void> _assentar(WidgetTester tester) async {
  EasyLoading.dismiss();
  Get.closeAllSnackbars();
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
}

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
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

  Future<void> abrirDesafio(WidgetTester tester, TotpMfaArgs args) async {
    final tema = EventThemeController();
    await tester.pumpWidget(GetMaterialApp(
      builder: EasyLoading.init(),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const Scaffold()),
        GetPage(
          name: '/loginTotp',
          page: () => TotpVerifyScreen(
            controller: Get.put(TotpMfaController(
              autenticacaoRepository: repo,
              appController: app,
            )),
            themeController: tema,
          ),
        ),
      ],
    ));
    Get.offAllNamed('/loginTotp', arguments: args);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  testWidgets('setup TOTP: escolha, QR, código errado e confirmação',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setupCtrl =
        TotpMfaController(autenticacaoRepository: repo, appController: app);
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
              return const Scaffold();
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
    final confirmacao = setupCtrl.confirmarCadastro();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(app.totpVerificado, 0);
    await _tocar(tester, find.text('Concluir e entrar'));
    await confirmacao;
    expect(app.totpVerificado, 1);
    expect(remote.confirmacoes, 2);
    expect(remote.codigosConfirmados.last, '123456');
    expect(splash, 0);
    await _assentar(tester);
  });

  testWidgets('desafio TOTP: código errado e entrada', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final verifyCtrl =
        TotpMfaController(autenticacaoRepository: repo, appController: app);
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
              return const Scaffold();
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
    expect(splash, 0);
    await _assentar(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'troca o desafio pelo e-mail e entra com um código de recuperação',
      (tester) async {
    await abrirDesafio(
        tester, const TotpMfaArgs(totpAtivo: true, emailAtivo: true));

    expect(find.text('App autenticador'), findsOneWidget);
    expect(remote.enviosPorEmail, 0);
    final trocar = find.widgetWithText(TextButton, 'Usar outro método');
    await _tocar(tester, trocar);
    await _tocar(
        tester, find.widgetWithText(SimpleDialogOption, 'Código por e-mail'));
    expect(remote.enviosPorEmail, 1);
    expect(find.text('qa***@example.test'), findsOneWidget);

    await _tocar(tester, trocar);
    await _tocar(tester,
        find.widgetWithText(SimpleDialogOption, 'Código de recuperação'));
    const codigo = '89AB-CDEF-0123-4567-89AB-CDEF-0123-4567';
    await tester.enterText(find.byType(TextField), codigo);
    await _tocar(
        tester, find.widgetWithText(ElevatedButton, 'Confirmar e entrar'));
    expect(remote.recuperacoes, [codigo]);
    expect(remote.enviosPorEmail, 1);
    expect(find.text('Opções de segurança'), findsOneWidget);
    expect(find.text('Substituir app autenticador'), findsOneWidget);
    expect(app.totpVerificado, 0);

    await _tocar(tester, find.text('Gerar códigos de recuperação'));
    expect(find.text('Guarde seus códigos de recuperação'), findsOneWidget);
    await _tocar(tester, find.text('Já guardei, entrar'));
    expect(app.totpVerificado, 1);
    await _assentar(tester);
  });

  testWidgets('opções marcadas exibem os códigos antes de concluir o login',
      (tester) async {
    remote.autorizacaoEmail = 'prova-qa';
    await abrirDesafio(
        tester, const TotpMfaArgs(metodo: 'email', emailAtivo: true));
    await _tocar(tester, find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField), '135790');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(app.totpVerificado, 0);
    await _tocar(tester, find.text('Gerar códigos de recuperação'));
    expect(remote.geracoesRecuperacao, 1);
    final lista = find.text('Guarde seus códigos de recuperação');
    expect(lista, findsOneWidget);
    expect(ModalRoute.of(tester.element(lista))?.popDisposition,
        RoutePopDisposition.doNotPop);
    expect(app.totpVerificado, 0);

    await _tocar(tester, find.text('Já guardei, entrar'));
    expect(app.totpVerificado, 1);
    await _assentar(tester);
  });

  testWidgets('adiciona autenticador pelo diálogo com o mouse no desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    remote.autorizacaoEmail = 'prova-qa';
    await abrirDesafio(
        tester, const TotpMfaArgs(metodo: 'email', emailAtivo: true));
    await _tocar(tester, find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField), '135790');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    final adicionar = find.text('Adicionar app autenticador');
    final ponto = tester.getCenter(adicionar);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: ponto);
    await mouse.down(ponto);
    await mouse.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final qr = find.byType(QrImageView);
    expect(qr, findsOneWidget);
    expect(tester.getSize(qr), const Size.square(160));
    await mouse.moveTo(tester.getCenter(qr));
    await tester.pump();
    await mouse.removePointer();
    expect(tester.takeException(), isNull);

    final codigo = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(codigo, '123456');
    await _tocar(tester, find.text('Confirmar método'));
    expect(remote.codigosConfirmados, ['123456']);
    expect(find.text('App autenticador ativo'), findsOneWidget);
    await _tocar(tester, find.text('Concluir e entrar'));
    expect(app.totpVerificado, 1);
    await _assentar(tester);
  });

  testWidgets(
      'opções marcadas avisam quando o servidor antigo só valida o código',
      (tester) async {
    await abrirDesafio(
        tester, const TotpMfaArgs(metodo: 'email', emailAtivo: true));
    await _tocar(tester, find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField), '135790');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Opções de segurança indisponíveis'), findsOneWidget);
    expect(find.text('Gerar códigos de recuperação'), findsNothing);
    expect(app.totpVerificado, 0);
    await _tocar(tester, find.text('Entrar agora'));
    expect(app.totpVerificado, 1);
    await _assentar(tester);
  });
}
