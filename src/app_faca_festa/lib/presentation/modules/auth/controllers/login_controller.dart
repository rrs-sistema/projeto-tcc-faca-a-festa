import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/app/bootstrap/auditoria_bootstrap.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';

class LoginController extends GetxController {
  LoginController({
    AutenticacaoRepository? autenticacaoRepository,
    PerfilUsuarioRepository? perfilRepository,
  })  : _autenticacaoRepository =
            autenticacaoRepository ?? Get.find<AutenticacaoRepository>(),
        _perfilRepository =
            perfilRepository ?? Get.find<PerfilUsuarioRepository>();

  final AutenticacaoRepository _autenticacaoRepository;
  final PerfilUsuarioRepository _perfilRepository;

  var email = ''.obs;
  var senha = ''.obs;
  var carregando = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<AppController>()) {
      _capturarTokenDosArgumentos(Get.find<AppController>());
    }
  }

  Future<void> login() async {
    final erroEmail = FormValidators.email(email.value);
    if (erroEmail != null) {
      EasyLoading.showError(erroEmail);
      return;
    }
    final erroSenha = FormValidators.senhaLogin(senha.value);
    if (erroSenha != null) {
      EasyLoading.showError(erroSenha);
      return;
    }

    try {
      carregando.value = true;
      final app = Get.find<AppController>();
      _capturarTokenDosArgumentos(app);
      app.marcarLoginComSenha();
      await _autenticacaoRepository.entrar(
        email: email.value.trim(),
        senha: senha.value.trim(),
      );

      await _garantirPerfilDoUsuario();
      await _registrarAcesso(
        acao: 'LOGIN_REALIZADO',
        resumo: 'Login com e-mail e senha realizado.',
        metodo: 'senha',
      );
      app.acessoPorLink.value = false;
      Get.offAllNamed('/splash');
    } on AutenticacaoException catch (e) {
      await _registrarFalhaLogin(codigo: e.codigo, metodo: 'senha');
      EasyLoading.showError(_traduzErro(e.codigo));
    } finally {
      carregando.value = false;
    }
  }

  Future<void> loginComGoogle() async {
    try {
      carregando.value = true;
      final app = Get.find<AppController>();
      _capturarTokenDosArgumentos(app);
      app.marcarLoginComGoogle();
      final autenticou = await _autenticacaoRepository.entrarComGoogle();
      if (!autenticou) {
        return;
      }
      await _garantirPerfilDoUsuario();
      await _registrarAcesso(
        acao: 'LOGIN_REALIZADO',
        resumo: 'Login com Google realizado.',
        metodo: 'google',
      );
      app.acessoPorLink.value = false;
      Get.offAllNamed('/splash');
    } on AutenticacaoException catch (e) {
      if (e.foiCancelada) {
        return;
      }
      await _registrarFalhaLogin(codigo: e.codigo, metodo: 'google');
      EasyLoading.showError(_traduzErro(e.codigo));
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _garantirPerfilDoUsuario() async {
    final idUsuario = _autenticacaoRepository.idUsuarioAtual;
    if (idUsuario == null) return;

    final usuario = await _perfilRepository.buscarUsuario(idUsuario);
    if (usuario != null) return;

    final nome = _autenticacaoRepository.nomeUsuarioAtual?.trim() ?? '';
    final email = _autenticacaoRepository.emailUsuarioAtual ?? '';

    final tipo = _tipoPerfilInicial();
    if (nome.isNotEmpty || tipo == 'C') {
      await _perfilRepository.salvarUsuario(
        Usuario(
          idUsuario: idUsuario,
          nome: nome.isNotEmpty ? nome : 'Convidado',
          email: email,
          tipo: tipo,
          fotoPerfilUrl: _autenticacaoRepository.fotoUsuarioAtual,
          ativo: true,
          dataCadastro: DateTime.now(),
        ),
      );
      return;
    }

    await _perfilRepository.criarUsuarioAutomatico(
      idUsuario: idUsuario,
      email: _autenticacaoRepository.emailUsuarioAtual,
    );
  }

  /// Conta nova no fluxo de convite é tipo C. Sem token, Google não vira O
  /// só porque o login não passou por `/register`.
  String _tipoPerfilInicial() {
    final app = Get.find<AppController>();
    if (app.fluxoConviteAtivo) return 'C';
    return 'O';
  }

  void _capturarTokenDosArgumentos(AppController app) {
    final args = Get.arguments;
    if (args is! Map) return;
    final raw = args['conviteToken'] ??
        args['tokenConvite'] ??
        args['token'] ??
        args['convite_token'];
    app.guardarTokenConvite(raw?.toString() ?? '');
  }

  Future<void> _registrarAcesso({
    required String acao,
    required String resumo,
    required String metodo,
  }) async {
    try {
      AuditoriaBootstrap.register();
      await Get.find<GerenciarAuditoria>().registrar(
        RegistroAuditoria(
          acao: acao,
          resumo: resumo,
          entidadeTipo: 'sessao',
          entidadeId: _autenticacaoRepository.idUsuarioAtual,
          entidadeNome: _autenticacaoRepository.emailUsuarioAtual,
          detalhe: {
            'metodo': metodo,
            'email': _autenticacaoRepository.emailUsuarioAtual,
          },
          rota: Get.currentRoute,
        ),
      );
    } catch (_) {
      // Auditoria de acesso não pode bloquear autenticação do usuário.
    }
  }

  Future<void> _registrarFalhaLogin({
    required String codigo,
    required String metodo,
  }) async {
    try {
      AuditoriaBootstrap.register();
      await Get.find<GerenciarAuditoria>().registrarFalhaLogin(
        RegistroFalhaLogin(
          email: email.value.trim(),
          codigo: codigo,
          metodo: metodo,
          rota: Get.currentRoute,
        ),
      );
    } catch (_) {
      // Falha ao auditar tentativa recusada não pode mascarar o erro de login.
    }
  }

  String _traduzErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-email':
        return 'Email inválido';
      case 'account-exists-with-different-credential':
        return 'Este e-mail já está cadastrado com outro método de login';
      case 'canceled':
      case 'web-context-canceled':
      case 'ERROR_WEB_CONTEXT_CANCELED':
      case 'popup-closed-by-user':
        return 'Login com Google cancelado';
      case 'interrupted':
        return 'O Google interrompeu o login. Tente novamente.';
      case 'clientConfigurationError':
      case 'providerConfigurationError':
        return 'Google não configurado corretamente no Firebase';
      case 'google-token-not-found':
      case 'google-sign-in-unsupported':
      case 'google-unexpected-error':
        return 'Login com Google indisponível neste dispositivo';
      default:
        return 'Erro ao fazer login. Tente novamente.';
    }
  }
}
