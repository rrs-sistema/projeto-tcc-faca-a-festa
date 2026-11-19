import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:app_faca_festa/app/middleware/papel_middleware.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/auditoria_repository.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/repositories/push_token_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_documentos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_carrinho_cotacao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_ciclo_sessao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_destino_rota.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_sessao_fornecedor.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_totp_sessao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_convite_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/login_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/totp_verify_screen.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

const _usuario = Usuario(
  idUsuario: 'organizador',
  nome: 'Organizador',
  email: 'organizador@example.test',
  tipo: 'O',
  mfaEmailAtivo: true,
  mfaMetodo: 'email',
  mfaLoginOpcional: true,
);

void main() {
  for (final voluntaria in [true, false]) {
    testWidgets('login do organizador com proteção opcional $voluntaria',
        (tester) async {
      Get.testMode = true;
      final auth = _Autenticacao();
      final perfil = _Perfil(_usuario.copyWith(mfaLoginOpcional: voluntaria));
      final auditoria = _Auditoria();
      final tema = EventThemeController();
      final app = Get.put(AppController(
        storage: _Storage(),
        autenticacaoRepository: auth,
        perfilUsuarioRepository: perfil,
        pushTokenRepository: _Push(),
        documentos: _Documentos(),
        fornecedores: _Fornecedores(),
        convite: _Convite(),
        eventoController: _Eventos(),
        orcamentoController: _Orcamentos(),
        cotacaoController: _Cotacoes(),
        fornecedorController: _Fornecedor(),
        tarefaController: _Tarefas(),
        avaliacaoController: _Avaliacoes(),
        servicoController: _Servicos(),
        themeController: tema,
      ));
      addTearDown(() async {
        Get.reset();
        Get.testMode = false;
        await auth.sessoes.close();
      });
      final login = LoginController(
        autenticacaoRepository: auth,
        perfilRepository: perfil,
        appController: app,
        gerenciarAuditoria: GerenciarAuditoria(auditoria),
      );
      final mfa = TotpMfaController(
        autenticacaoRepository: auth,
        appController: app,
      );
      var splashes = 0;

      await tester.pumpWidget(GetMaterialApp(
        initialRoute: '/login',
        builder: EasyLoading.init(),
        getPages: [
          GetPage(name: '/login', page: () => const Scaffold()),
          GetPage(
            name: '/splash',
            page: () {
              splashes++;
              return const Scaffold();
            },
          ),
          GetPage(
            name: '/loginTotp',
            page: () => TotpVerifyScreen(
              controller: Get.put(mfa),
              themeController: tema,
            ),
          ),
          GetPage(
            name: '/welcome',
            middlewares: [
              PapelMiddleware(tiposPermitidos: const ['O'])
            ],
            page: () => const Scaffold(body: Text('Sessão iniciada')),
          ),
        ],
      ));
      login.email.value = _usuario.email;
      login.senha.value = 'senha-exemplo';
      final entrada = login.login();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(auth.idUsuarioAtual, _usuario.idUsuario);
      expect(login.carregando.value, isTrue);
      expect(Get.currentRoute, '/login');
      expect(perfil.carregamentos, 0);

      perfil.busca.complete(perfil.usuario);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await entrada;

      if (!voluntaria) {
        expect(Get.currentRoute, '/welcome');
        expect(auth.codigosEnviados, 0);
        expect(app.usuarioLogado.value, perfil.usuario);
        expect(splashes, 0);
        auditoria.resposta.complete('registro-login');
        return;
      }

      expect(Get.currentRoute, '/loginTotp');
      expect(auth.codigosEnviados, 1);
      expect(app.usuarioLogado.value, isNull);
      expect(auditoria.registros.single.acao, 'LOGIN_REALIZADO');

      auditoria.resposta.complete('registro-login');
      auth.sessoes.add(auth.sessaoAtual);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(Get.currentRoute, '/loginTotp');
      expect(auth.codigosEnviados, 1);
      expect(splashes, 0);

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Código incorreto.'), findsOneWidget);
      expect(Get.currentRoute, '/loginTotp');
      expect(app.usuarioLogado.value, isNull);
      Get.closeAllSnackbars();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(auth.codigosValidados, ['000000', '123456']);
      expect(find.text('Sessão iniciada'), findsOneWidget);
      expect(app.usuarioLogado.value, perfil.usuario);
      expect(auth.codigosEnviados, 1);
      expect(splashes, 0);
    });
  }

  for (final tipo in ['F', 'A']) {
    for (final verificada in [true, false]) {
      testWidgets(
          'reabertura do perfil $tipo com sessão MFA válida=$verificada',
          (tester) async {
        Get.testMode = true;
        final auth = _Autenticacao()
          ..sessaoAtual = const SessaoUsuario(idUsuario: 'organizador')
          ..mfaVerificada = verificada;
        final perfil = _Perfil(_usuario.copyWith(tipo: tipo));
        addTearDown(() async {
          Get.reset();
          Get.testMode = false;
          await auth.sessoes.close();
        });
        await tester.pumpWidget(GetMaterialApp(
          initialRoute: '/login',
          getPages: [
            for (final rota in [
              '/login',
              '/loginTotp',
              '/fornecedor',
              '/admin'
            ])
              GetPage(name: rota, page: () => const Scaffold()),
          ],
        ));

        // Cada inicialização perde a memória local, mas restaura o mesmo login.
        for (var abertura = 0; abertura < 2; abertura++) {
          if (abertura > 0) {
            Get.offAllNamed('/login');
            await tester.pumpAndSettle();
          }
          final ciclo = AppCicloSessao(
            autenticacao: auth,
            perfil: perfil,
            convite: _Convite(),
            totp: AppTotpSessao(_Storage()),
            carrinho: AppCarrinhoCotacao(),
            sessaoFornecedor: _SessaoFornecedor(),
            eventos: _Eventos(),
            orcamentos: _Orcamentos(),
            cotacoes: _Cotacoes(),
            fornecedor: _Fornecedor(),
            tarefas: _Tarefas(),
            servicos: _Servicos(),
            theme: EventThemeController(),
          );
          final restauracao = ciclo.processar(auth.sessaoAtual);
          await tester.pump(const Duration(milliseconds: 300));
          await restauracao;
          await tester.pumpAndSettle();
          expect(
              Get.currentRoute,
              verificada
                  ? (tipo == 'A' ? '/admin' : '/fornecedor')
                  : '/loginTotp');
        }
        expect(auth.consultasMfa, 2);
        expect(auth.codigosValidados, isEmpty);
      });
    }
  }
}

class _Autenticacao extends Fake implements AutenticacaoRepository {
  final sessoes = StreamController<SessaoUsuario?>.broadcast();
  SessaoUsuario? sessaoAtual;
  var codigosEnviados = 0;
  var consultasMfa = 0;
  bool mfaVerificada = false;
  final codigosValidados = <String>[];

  @override
  Future<bool> sessaoMfaVerificada() async {
    consultasMfa++;
    return mfaVerificada;
  }

  @override
  String? get idUsuarioAtual => sessaoAtual?.idUsuario;

  @override
  String? get emailUsuarioAtual => sessaoAtual?.email;

  @override
  bool get sessaoAnonima => false;

  @override
  bool get sessaoVisitanteConvite => false;

  @override
  bool get contaAtualTemLoginComSenha => true;

  @override
  Stream<SessaoUsuario?> observarSessao() => sessoes.stream;

  @override
  Future<void> entrar({required String email, required String senha}) async {
    sessaoAtual = SessaoUsuario(idUsuario: _usuario.idUsuario, email: email);
    sessoes.add(sessaoAtual);
  }

  @override
  Future<CodigoEmailMfa> solicitarCodigoEmailMfa({String? autorizacao}) async {
    codigosEnviados++;
    return const CodigoEmailMfa(emailMascarado: 'or***@example.test');
  }

  @override
  Future<String> verificarEmailMfa(String codigo) async {
    codigosValidados.add(codigo);
    if (codigo != '123456') {
      throw const AutenticacaoException('permission-denied');
    }
    return '';
  }
}

class _Perfil extends Fake implements PerfilUsuarioRepository {
  _Perfil(this.usuario);
  final Usuario usuario;
  final busca = Completer<Usuario?>();
  var carregamentos = 0;

  @override
  Future<Usuario?> buscarUsuario(String idUsuario) => busca.future;

  @override
  Future<PerfilUsuario?> carregarPerfil(String idUsuario) async {
    carregamentos++;
    return PerfilUsuario(usuario: usuario, enderecos: []);
  }
}

class _Auditoria extends Fake implements AuditoriaRepository {
  final resposta = Completer<String>();
  final registros = <RegistroAuditoria>[];

  @override
  Future<String> registrar(RegistroAuditoria registro) {
    registros.add(registro);
    return resposta.future;
  }
}

class _Storage extends Fake implements GetStorage {
  final _valores = <String, dynamic>{};

  @override
  T? read<T>(String key) => _valores[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async {
    _valores[key] = value;
  }
}

class _Convite extends Fake implements AppConviteController {
  @override
  final acessoPorLink = false.obs;

  @override
  void capturarTokenInicial() {}

  @override
  String? tokenConviteAtual() => null;

  @override
  void vincular({
    required Future<Usuario?> Function(String id) obterUsuario,
    required RxBool carregando,
  }) {}
}

class _Eventos extends Fake implements EventoController {
  @override
  Evento? get eventoAtualEntidade => null;

  @override
  Future<void> carregarEventosDoUsuario(String idUsuario) async {}
}

class _Push extends Fake implements PushTokenRepository {}

class _Documentos extends Fake implements GerenciarDocumentos {}

class _Fornecedores extends Fake implements GerenciarFornecedores {}

class _Orcamentos extends Fake implements OrcamentoController {}

class _Cotacoes extends Fake implements CotacaoController {}

class _Fornecedor extends Fake implements FornecedorController {}

class _Tarefas extends Fake implements TarefaController {}

class _Avaliacoes extends Fake implements AvaliacaoServicoController {}

class _Servicos extends Fake implements ServicoProdutoController {
  @override
  Future<void> carregarServicosComDetalhesOtimizado(
      {String? idFornecedor}) async {}
}

class _SessaoFornecedor extends Fake implements AppSessaoFornecedor {
  @override
  Future<AppDestinoRota> resolverDestino(String idUsuario) async =>
      const AppDestinoRota('/fornecedor');
}
