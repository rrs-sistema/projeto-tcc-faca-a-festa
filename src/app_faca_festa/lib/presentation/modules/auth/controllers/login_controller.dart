import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_erro_login_sheet.dart';

/// Contrato mínimo da sessão após o formulário de login autenticar.
abstract class SessaoLoginPort {
  void marcarLoginComSenha();
  void marcarLoginComGoogle();
  bool get fluxoConviteAtivo;
  RxBool get acessoPorLink;
  void guardarTokenConvite(String token);
}

class AppControllerSessaoLogin implements SessaoLoginPort {
  AppControllerSessaoLogin(this._app);
  final AppController _app;
  @override
  void marcarLoginComSenha() => _app.marcarLoginComSenha();
  @override
  void marcarLoginComGoogle() => _app.marcarLoginComGoogle();
  @override
  bool get fluxoConviteAtivo => _app.fluxoConviteAtivo;
  @override
  RxBool get acessoPorLink => _app.acessoPorLink;
  @override
  void guardarTokenConvite(String token) => _app.guardarTokenConvite(token);
}

class LoginController extends GetxController {
  LoginController({
    required AutenticacaoRepository autenticacaoRepository,
    required PerfilUsuarioRepository perfilRepository,
    AppController? appController,
    AppController? Function()? appControllerResolver,
    SessaoLoginPort? sessaoLogin,
    GerenciarAuditoria? gerenciarAuditoria,
    GerenciarAuditoria? Function()? gerenciarAuditoriaResolver,
  })  : _autenticacaoRepository = autenticacaoRepository,
        _perfilRepository = perfilRepository,
        _appController = appController,
        _appControllerResolver = appControllerResolver,
        _sessaoLogin = sessaoLogin,
        _gerenciarAuditoria = gerenciarAuditoria,
        _gerenciarAuditoriaResolver = gerenciarAuditoriaResolver;

  final AutenticacaoRepository _autenticacaoRepository;
  final PerfilUsuarioRepository _perfilRepository;
  final AppController? _appController;
  final AppController? Function()? _appControllerResolver;
  final SessaoLoginPort? _sessaoLogin;
  final GerenciarAuditoria? _gerenciarAuditoria;
  final GerenciarAuditoria? Function()? _gerenciarAuditoriaResolver;

  var email = ''.obs;
  var senha = ''.obs;
  var carregando = false.obs;

  @override
  void onInit() {
    super.onInit();
    final sessao = _resolverSessaoOrNull();
    if (sessao != null) {
      _capturarTokenDosArgumentos(sessao);
    }
  }

  Future<void> login() async {
    final erroEmail = FormValidators.email(email.value);
    if (erroEmail != null) {
      _mostrarErro(mensagem: erroEmail, titulo: 'Confira o e-mail');
      return;
    }
    final erroSenha = FormValidators.senhaLogin(senha.value);
    if (erroSenha != null) {
      _mostrarErro(mensagem: erroSenha, titulo: 'Confira a senha');
      return;
    }

    try {
      carregando.value = true;
      final sessao = _resolverSessao();
      _capturarTokenDosArgumentos(sessao);
      sessao.marcarLoginComSenha();
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
      sessao.acessoPorLink.value = false;
      Get.offAllNamed('/splash');
    } on AutenticacaoException catch (e) {
      await _registrarFalhaLogin(codigo: e.codigo, metodo: 'senha');
      _mostrarErro(codigo: e.codigo);
    } finally {
      carregando.value = false;
    }
  }

  Future<void> loginComGoogle() async {
    try {
      carregando.value = true;
      final sessao = _resolverSessao();
      _capturarTokenDosArgumentos(sessao);
      sessao.marcarLoginComGoogle();
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
      sessao.acessoPorLink.value = false;
      Get.offAllNamed('/splash');
    } on AutenticacaoException catch (e) {
      if (e.foiCancelada) {
        return;
      }
      await _registrarFalhaLogin(codigo: e.codigo, metodo: 'google');
      _mostrarErro(codigo: e.codigo);
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
    if (_resolverSessao().fluxoConviteAtivo) return 'C';
    return 'O';
  }

  void _capturarTokenDosArgumentos(SessaoLoginPort sessao) {
    final args = AuthFluxoArgs.maybeOf(Get.arguments);
    if (args != null) {
      sessao.guardarTokenConvite(args.conviteToken);
    }
  }

  Future<void> _registrarAcesso({
    required String acao,
    required String resumo,
    required String metodo,
  }) async {
    try {
      final auditoria = _resolverGerenciarAuditoria();
      if (auditoria == null) return;
      await auditoria.registrar(
        RegistroAuditoria(
          acao: acao,
          resumo: resumo,
          entidadeTipo: 'sessao',
          entidadeId: _autenticacaoRepository.idUsuarioAtual,
          entidadeNome: _autenticacaoRepository.emailUsuarioAtual,
          detalhe: AuditoriaDetalhe(
            metodo: metodo,
            email: _autenticacaoRepository.emailUsuarioAtual,
          ),
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
      final auditoria = _resolverGerenciarAuditoria();
      if (auditoria == null) return;
      await auditoria.registrarFalhaLogin(
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

  SessaoLoginPort _resolverSessao() {
    final sessao = _resolverSessaoOrNull();
    if (sessao == null) {
      throw StateError('Sessão de login não configurada.');
    }
    return sessao;
  }

  SessaoLoginPort? _resolverSessaoOrNull() {
    if (_sessaoLogin != null) return _sessaoLogin;
    final app = _appController ?? _appControllerResolver?.call();
    if (app == null) return null;
    return AppControllerSessaoLogin(app);
  }

  GerenciarAuditoria? _resolverGerenciarAuditoria() {
    return _gerenciarAuditoria ?? _gerenciarAuditoriaResolver?.call();
  }

  void _mostrarErro({String? codigo, String? titulo, String? mensagem}) {
    mostrarErroLoginSheet(
      codigo: codigo,
      titulo: titulo,
      mensagem: mensagem,
    );
  }
}
