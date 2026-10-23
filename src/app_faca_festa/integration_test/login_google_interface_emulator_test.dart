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

/// Google pela LoginScreen real. O seletor OAuth não roda no Windows+emulador;
/// o remote injeta cancelamento, falha e sucesso com sessão Auth real.
class _AuthRemoteGoogleQA extends Fake implements AutenticacaoRemoteDatasource {
  _AuthRemoteGoogleQA(this.auth,
      {required this.email, required this.senha});

  final FirebaseAuth auth;
  final String email;
  final String senha;
  var cancelar = false;
  String? falha;

  @override
  String? get idUsuarioAtual => auth.currentUser?.uid;
  @override
  String? get emailUsuarioAtual => auth.currentUser?.email;
  @override
  String? get nomeUsuarioAtual => auth.currentUser?.displayName;
  @override
  String? get fotoUsuarioAtual => auth.currentUser?.photoURL;
  @override
  bool get contaAtualTemLoginComSenha => false;

  @override
  Future<bool> entrarComGoogle() async {
    if (cancelar) return false;
    if (falha != null) throw AutenticacaoRemoteException(falha!);
    try {
      await auth.signInWithEmailAndPassword(email: email, password: senha);
      return true;
    } on FirebaseAuthException catch (e) {
      throw AutenticacaoRemoteException(e.code);
    }
  }

  @override
  Future<void> sair() async {
    await auth.signOut();
  }
}

class PerfilGoogleQA extends Fake implements PerfilUsuarioRepository {
  Usuario? salvo;
  @override
  Future<Usuario?> buscarUsuario(String idUsuario) async => salvo;
  @override
  Future<void> salvarUsuario(Usuario usuario) async {
    salvo = usuario;
  }

  @override
  Future<void> criarUsuarioAutomatico(
      {required String idUsuario, required String? email}) async {
    salvo = Usuario(
        idUsuario: idUsuario,
        nome: 'Organizador Google QA',
        email: email ?? '',
        tipo: 'O',
        ativo: true,
        dataCadastro: DateTime.now());
  }
}

class SessaoGoogleQA implements SessaoLoginPort {
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

class AppTelaGoogleQA extends Fake implements AppController {
  @override
  String? tokenConviteAtual() => null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const projeto = 'demo-google12';
  const email = 'google-owner@example.test';
  const senha = 'TesteLocal123!';

  testWidgets(
      'Entrar com Google: cancela, falha de configuração e autentica',
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

    final remote =
        _AuthRemoteGoogleQA(auth, email: email, senha: senha);
    final repo = AutenticacaoRepositoryImpl(remote);
    final perfil = PerfilGoogleQA();
    final sessao = SessaoGoogleQA();
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
                appController: AppTelaGoogleQA())),
        GetPage(
            name: '/splash',
            page: () {
              splash++;
              return const Scaffold(body: Text('Sessão Google'));
            }),
        GetPage(
            name: '/forgotPassword',
            page: () => const Scaffold(body: Text('Recuperar'))),
        GetPage(name: '/role', page: () => const Scaffold(body: Text('Papel'))),
      ]));
      await tester.pumpAndSettle();
    }

    Future<void> tocarGoogle() async {
      final botao = find.text('Entrar com Google');
      await tester.ensureVisible(botao);
      await tester.tap(botao);
      await tester.pumpAndSettle();
    }

    Future<void> fecharAviso() async {
      final tentar = find.text('Tentar de novo');
      for (var i = 0; i < 100 && tentar.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(tentar, findsOneWidget);
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      await tester.pumpAndSettle();
      expect(find.text('Tentar de novo'), findsNothing);
    }

    await abrir();
    expect(find.text('Entrar com Google').hitTestable(), findsOneWidget);

    remote.cancelar = true;
    await tocarGoogle();
    expect(auth.currentUser, isNull);
    expect(splash, 0);
    expect(sessao.marcaGoogle, 1);
    expect(find.text('Sessão Google'), findsNothing);

    remote.cancelar = false;
    remote.falha = 'clientConfigurationError';
    await tocarGoogle();
    await fecharAviso();
    expect(auth.currentUser, isNull);
    expect(splash, 0);
    expect(sessao.marcaGoogle, 2);
    expect(find.textContaining('Google'), findsWidgets);

    remote.falha = null;
    await tocarGoogle();
    for (var i = 0;
        i < 100 && find.text('Sessão Google').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.text('Sessão Google'), findsOneWidget);
    expect(auth.currentUser?.email, email);
    expect(sessao.marcaGoogle, 3);
    expect(sessao.marcaSenha, 0);
    expect(sessao.acessoPorLink.value, false);
    expect(splash, 1);
    expect(perfil.salvo?.email, email);
    expect(perfil.salvo?.tipo, 'O');
    expect(tester.takeException(), isNull);
  });
}
