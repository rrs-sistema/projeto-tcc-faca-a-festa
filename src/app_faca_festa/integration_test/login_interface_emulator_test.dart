import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_faca_festa/data/datasources/remote/autenticacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/autenticacao_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/login_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/login_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

/// Auth real do emulador; Functions/Google ficam fora deste roteiro.
class _AuthRemoteLoginQA extends Fake implements AutenticacaoRemoteDatasource {
  _AuthRemoteLoginQA(this.auth);
  final FirebaseAuth auth;
  @override
  String? get idUsuarioAtual => auth.currentUser?.uid;
  @override
  String? get emailUsuarioAtual => auth.currentUser?.email;
  @override
  String? get nomeUsuarioAtual => auth.currentUser?.displayName;
  @override
  String? get fotoUsuarioAtual => auth.currentUser?.photoURL;
  @override
  bool get contaAtualTemLoginComSenha => true;
  @override
  Future<void> entrar({required String email, required String senha}) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (e) {
      throw AutenticacaoRemoteException(e.code);
    }
  }

  @override
  Future<void> sair() async {
    await auth.signOut();
  }
}

class PerfilLoginQA extends Fake implements PerfilUsuarioRepository {
  Usuario? salvo;
  int criacoes = 0;
  @override
  Future<Usuario?> buscarUsuario(String idUsuario) async => salvo;
  @override
  Future<void> salvarUsuario(Usuario usuario) async {
    salvo = usuario;
  }

  @override
  Future<void> criarUsuarioAutomatico(
      {required String idUsuario, required String? email}) async {
    criacoes++;
    salvo = Usuario(
        idUsuario: idUsuario,
        nome: 'Organizador QA',
        email: email ?? '',
        tipo: 'O',
        ativo: true,
        dataCadastro: DateTime.now());
  }
}

class SessaoLoginQA implements SessaoLoginPort {
  var marcaSenha = 0, marcaGoogle = 0, tokens = <String>[];
  @override
  final acessoPorLink = false.obs;
  @override
  bool fluxoConviteAtivo = false;
  @override
  void marcarLoginComSenha() => marcaSenha++;
  @override
  void marcarLoginComGoogle() => marcaGoogle++;
  @override
  void guardarTokenConvite(String token) => tokens.add(token);
}

class AppTelaQA extends Fake implements AppController {
  @override
  String? tokenConviteAtual() => null;
}

/// Login pela LoginScreen real com Auth emulator. Sem Google e sem MFA.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const projeto = 'demo-login12';
  const email = 'login-owner@example.test';
  const senha = 'TesteLocal123!';

  testWidgets(
      'formulário real autentica, rejeita senha errada, sai e entra de novo',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Use o harness demo local.');
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: projeto));
    if (app.options.projectId != projeto) {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);

    final remote = _AuthRemoteLoginQA(auth);
    final repo = AutenticacaoRepositoryImpl(remote);
    final perfil = PerfilLoginQA();
    final sessao = SessaoLoginQA();
    final controller = LoginController(
        autenticacaoRepository: repo,
        perfilRepository: perfil,
        sessaoLogin: sessao);
    Get.testMode = true;
    var splash = 0;

    Future<void> abrir() async {
      await tester.pumpWidget(GetMaterialApp(initialRoute: '/login', getPages: [
        GetPage(
            name: '/login',
            page: () => LoginScreen(
                controller: controller,
                themeController: EventThemeController(),
                appController: AppTelaQA())),
        GetPage(
            name: '/splash',
            page: () {
              splash++;
              return const Scaffold(body: Text('Sessão iniciada'));
            }),
        GetPage(
            name: '/forgotPassword',
            page: () => const Scaffold(body: Text('Recuperar'))),
        GetPage(name: '/role', page: () => const Scaffold(body: Text('Papel'))),
      ]));
      await tester.pumpAndSettle();
    }

    Future<void> preencher(String e, String s) async {
      final campos = find.byType(TextFormField);
      expect(campos, findsNWidgets(2));
      await tester.ensureVisible(campos.at(0));
      await tester.enterText(campos.at(0), e);
      await tester.ensureVisible(campos.at(1));
      await tester.enterText(campos.at(1), s);
      await tester.pumpAndSettle();
    }

    await abrir();
    expect(find.textContaining('Entre e'), findsWidgets);
    expect(find.text('faça a festa'), findsOneWidget);
    expect(find.text('Entrar').hitTestable(), findsOneWidget);
    expect(find.textContaining('Google').hitTestable(), findsOneWidget);
    expect(find.text('Esqueci minha senha').hitTestable(), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await preencher('nao-e-email', '1');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
    expect(sessao.marcaSenha, 0);
    expect(splash, 0);

    Future<void> tocarEntrar() async {
      final botao = find.widgetWithText(ElevatedButton, 'Entrar');
      await tester.ensureVisible(botao);
      await tester.pumpAndSettle();
      await tester.tap(botao);
    }

    Future<void> fecharAviso() async {
      final tentar = find.text('Tentar de novo');
      for (var i = 0; i < 100 && tentar.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(tentar, findsOneWidget);
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      } else {
        await tester.ensureVisible(tentar);
        await tester.tap(tentar);
      }
      await tester.pumpAndSettle();
      expect(find.text('Tentar de novo'), findsNothing);
    }

    await preencher(email, 'SenhaErrada999!');
    await tocarEntrar();
    await fecharAviso();
    expect(auth.currentUser, isNull);
    expect(splash, 0);
    expect(sessao.marcaSenha, 1);
    expect(find.text('Tentar de novo'), findsNothing);

    await preencher(email, senha);
    await tocarEntrar();
    for (var i = 0;
        i < 100 && find.text('Sessão iniciada').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.text('Sessão iniciada'), findsOneWidget);
    expect(auth.currentUser?.email, email);
    expect(sessao.marcaSenha, 2);
    expect(sessao.acessoPorLink.value, false);
    expect(splash, 1);
    expect(perfil.salvo?.email, email);
    expect(perfil.salvo?.tipo, 'O');

    await repo.sair();
    expect(auth.currentUser, isNull);
    splash = 0;
    sessao.marcaSenha = 0;
    Get.offAllNamed('/login');
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await preencher(email, senha);
    await tocarEntrar();
    for (var i = 0;
        i < 100 && find.text('Sessão iniciada').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(auth.currentUser?.email, email);
    expect(splash, 1);
    expect(sessao.marcaSenha, 1);
    expect(tester.takeException(), isNull);
  });
}
