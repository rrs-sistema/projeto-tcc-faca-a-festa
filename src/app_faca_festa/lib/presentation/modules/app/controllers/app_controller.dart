import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/servico_cotado.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/repositories/push_token_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_documentos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_carrinho_cotacao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_convite_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_destino_rota.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_rotas_sessao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_totp_sessao.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';

class AppController extends GetxController {
  AppController({
    GetStorage? storage,
    required this.autenticacaoRepository,
    required this.perfilUsuarioRepository,
    required this.pushTokenRepository,
    required this.documentos,
    required this.fornecedores,
    required this.convite,
    required this.eventoController,
    required this.orcamentoController,
    required this.cotacaoController,
    required this.fornecedorController,
    required this.tarefaController,
    required this.avaliacaoController,
    required this.servicoController,
    required this.themeController,
    GerenciarAuditoria? auditoria,
    GerenciarAuditoria? Function()? auditoriaResolver,
    OrcamentoGastoController? orcamentoGastoController,
    OrcamentoGastoController? Function()? orcamentoGastoControllerResolver,
    FornecedorLocalizacaoController? fornecedorLocalizacaoController,
    FornecedorLocalizacaoController? Function()?
        fornecedorLocalizacaoControllerResolver,
    InspiracaoController? inspiracaoController,
    InspiracaoController? Function()? inspiracaoControllerResolver,
    UsuarioController? usuarioController,
    UsuarioController? Function()? usuarioControllerResolver,
  })  : totp = AppTotpSessao(
          storage ?? GetStorage(),
          contaTemLoginComSenha: () =>
              autenticacaoRepository.contaAtualTemLoginComSenha,
        ),
        carrinho = AppCarrinhoCotacao(),
        _auditoria = auditoria,
        _auditoriaResolver = auditoriaResolver,
        _orcamentoGastoController = orcamentoGastoController,
        _orcamentoGastoControllerResolver = orcamentoGastoControllerResolver,
        _fornecedorLocalizacaoController = fornecedorLocalizacaoController,
        _fornecedorLocalizacaoControllerResolver =
            fornecedorLocalizacaoControllerResolver,
        _inspiracaoController = inspiracaoController,
        _inspiracaoControllerResolver = inspiracaoControllerResolver,
        _usuarioController = usuarioController,
        _usuarioControllerResolver = usuarioControllerResolver {
    convite.vincular(
      obterUsuario: obterUsuario,
      carregando: carregando,
    );
  }

  // Estado reativo do usuário
  final Rx<Usuario?> usuarioLogado = Rx<Usuario?>(null);
  final Rx<EnderecoUsuario?> enderecoPrincipal = Rx<EnderecoUsuario?>(null);
  final RxList<EnderecoUsuario> enderecosUsuario = <EnderecoUsuario>[].obs;

  /// 🔹 Lista global de serviços selecionados para cotação
  RxList<ServicoCotado> get servicosSelecionados => carrinho.servicos;

  final RxBool contaIncompleta = false.obs;
  final RxBool carregando = false.obs;
  final RxBool encerrandoSessao = false.obs;
  StreamSubscription<SessaoUsuario?>? _sessaoSub;
  StreamSubscription<String>? _fcmTokenSub;
  bool _processandoSessao = false;
  bool _sessaoPendente = false;
  bool devMode = true;

  static const String _logTag = '[AppController]';
  final AutenticacaoRepository autenticacaoRepository;
  final PerfilUsuarioRepository perfilUsuarioRepository;
  final PushTokenRepository pushTokenRepository;
  final GerenciarDocumentos documentos;
  final GerenciarFornecedores fornecedores;
  final AppConviteController convite;
  final AppTotpSessao totp;
  final AppCarrinhoCotacao carrinho;

  // ✅ Injeção de controladores auxiliares
  final EventoController eventoController;
  final OrcamentoController orcamentoController;
  final CotacaoController cotacaoController;
  final FornecedorController fornecedorController;
  final TarefaController tarefaController;
  final AvaliacaoServicoController avaliacaoController;
  final ServicoProdutoController servicoController;
  final EventThemeController themeController;
  final GerenciarAuditoria? _auditoria;
  final GerenciarAuditoria? Function()? _auditoriaResolver;
  final OrcamentoGastoController? _orcamentoGastoController;
  final OrcamentoGastoController? Function()? _orcamentoGastoControllerResolver;
  final FornecedorLocalizacaoController? _fornecedorLocalizacaoController;
  final FornecedorLocalizacaoController? Function()?
      _fornecedorLocalizacaoControllerResolver;
  final InspiracaoController? _inspiracaoController;
  final InspiracaoController? Function()? _inspiracaoControllerResolver;
  final UsuarioController? _usuarioController;
  final UsuarioController? Function()? _usuarioControllerResolver;

  @override
  void onInit() {
    super.onInit();

    // O token do link é a credencial. Auth anônimo + callable abrem a área
    // sem cadastro; id_usuario só é gravado depois de conta real.
    convite.capturarTokenInicial();

    _monitorarSessao();
  }

  // ------------------------------------------------------------
  // 🔹 Carrega usuário logado e endereço principal
  // ------------------------------------------------------------
  Future<Usuario?> prepararUsuarioComEndereco() async {
    try {
      final idUsuario = autenticacaoRepository.idUsuarioAtual;
      if (idUsuario == null) return null;

      carregando.value = true;

      // 🔹 1️⃣ Busca o documento do usuário
      final usuario = await perfilUsuarioRepository.buscarUsuario(idUsuario);
      if (usuario == null) {
        debugPrint('⚠️ Usuário não encontrado no Firestore.');
        carregando.value = false;
        return null;
      }

      // 🔹 2️⃣ Busca subcoleção de endereços
      final enderecos =
          await perfilUsuarioRepository.listarEnderecos(idUsuario);
      _aplicarPerfil(PerfilUsuario(usuario: usuario, enderecos: enderecos));

      carregando.value = false;
      return usuarioLogado.value;
    } catch (e, s) {
      carregando.value = false;
      debugPrint('❌ Erro ao preparar usuário: $e');
      debugPrintStack(stackTrace: s);
      return null;
    }
  }

  Future<void> buscarUltimoEvento(String idUsuario) async {
    await eventoController.buscarUltimoEvento(idUsuario);
  }

  Future<void> ativarEventoOrganizador(Evento evento) async {
    await eventoController.selecionarEvento(evento);
    unawaited(eventoController.carregarEventosDoUsuario(evento.idUsuario));
  }

  /// Home do evento sem passar pelo splash (evita corrida de sessão).
  void abrirHomeOrganizador() {
    carregando.value = false;
    if (Get.currentRoute == '/HomeEventScreen') return;
    _validarDependenciasHomeEvent();
    Get.offAllNamed('/HomeEventScreen');
  }

  void iniciarSessao() {
    if (_sessaoSub == null) {
      _monitorarSessao();
      return;
    }

    // Auth já está sendo observado e não emite de novo só porque
    // voltamos ao splash (ex.: após cadastrar um evento).
    final idUsuario = autenticacaoRepository.idUsuarioAtual;
    if (idUsuario == null) {
      unawaited(_processarSessao(null));
      return;
    }

    unawaited(_processarSessao(SessaoUsuario(
      idUsuario: idUsuario,
      email: autenticacaoRepository.emailUsuarioAtual,
    )));
  }

  // ------------------------------------------------------------
  // 🔹 Monitora sessão do Firebase Auth e redireciona o usuário
  // ------------------------------------------------------------
  void _monitorarSessao() {
    _sessaoSub?.cancel();
    _sessaoSub = autenticacaoRepository.observarSessao().listen((user) {
      unawaited(_processarSessao(user));
    });
  }

  Future<void> _processarSessao(SessaoUsuario? user) async {
    if (_processandoSessao) {
      _sessaoPendente = true;
      debugPrint(
        '$_logTag Validação de sessão já em andamento. Nova tentativa será reprocessada.',
      );
      return;
    }
    _processandoSessao = true;

    try {
      await Future.delayed(
          const Duration(milliseconds: 300)); // ✅ pequeno delay
      final token = convite.tokenConviteAtual();

      if (convite.acessoPorLink.value &&
          (user == null ||
              autenticacaoRepository.sessaoAnonima ||
              autenticacaoRepository.sessaoVisitanteConvite)) {
        debugPrint(
            '$_logTag Visita por convite em andamento. Sem redirecionar.');
        return;
      }

      if (convite.acessoPorLink.value &&
          user != null &&
          !autenticacaoRepository.sessaoAnonima &&
          !autenticacaoRepository.sessaoVisitanteConvite) {
        convite.acessoPorLink.value = false;
      }

      if (user == null) {
        totp.limpar();
        if (token != null && token.isNotEmpty) {
          convite.guardarTokenConvite(token);
          debugPrint(
              '$_logTag Token de convite pendente; a tela de convite conduz: $token');
          return;
        }

        usuarioLogado.value = null;
        enderecoPrincipal.value = null;
        eventoController.limparSessaoAtual();

        if (Get.currentRoute != '/role') Get.offAllNamed('/role');
        return;
      }

      if (autenticacaoRepository.sessaoAnonima ||
          autenticacaoRepository.sessaoVisitanteConvite) {
        debugPrint('$_logTag Sessão de convite; aguardando área do convidado.');
        return;
      }

      final rotaAtual = Get.currentRoute;
      final noConvite = rotaAtual.startsWith('/convite');
      if (!noConvite &&
          !AppRotasSessao.ehTotp(rotaAtual) &&
          !AppRotasSessao.destinoEstavel(rotaAtual) &&
          !AppRotasSessao.usuarioJaNavegando(
            rotaAtual,
            temUsuario: usuarioLogado.value != null,
          ) &&
          (rotaAtual.isEmpty || rotaAtual != '/splash')) {
        Future.microtask(() {
          if (AppRotasSessao.ehTotp(Get.currentRoute)) return;
          if (Get.currentRoute.startsWith('/convite')) return;
          if (AppRotasSessao.destinoEstavel(Get.currentRoute)) return;
          if (AppRotasSessao.usuarioJaNavegando(
            Get.currentRoute,
            temUsuario: usuarioLogado.value != null,
          )) {
            return;
          }
          Get.offAllNamed('/splash');
        });
      }

      carregando.value = true;

      try {
        // Busca usuário + endereços
        final perfil = await _carregarPerfilComTentativas(user.idUsuario);

        if (perfil == null) {
          throw Exception('Usuário não encontrado no Firestore.');
        }

        final usuarioTotp = perfil.usuario;
        if (usuarioTotp.ativo == false) {
          carregando.value = false;
          Get.snackbar(
            'Conta desativada',
            'Entre em contato com o suporte para reativar o acesso.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          await autenticacaoRepository.sair();
          usuarioLogado.value = null;
          eventoController.limparSessaoAtual();
          Get.offAllNamed('/role');
          return;
        }

        if (totp.deveExigir()) {
          carregando.value = false;
          final metodoEmail = usuarioTotp.mfaMetodo == 'email' ||
              (usuarioTotp.mfaEmailAtivo && !usuarioTotp.mfaTotpAtivo);
          final rota = (usuarioTotp.mfaTotpAtivo || usuarioTotp.mfaEmailAtivo)
              ? '/loginTotp'
              : '/loginTotpSetup';
          if (Get.currentRoute != rota) {
            Get.offAllNamed(
              rota,
              arguments: metodoEmail ? {'metodo': 'email'} : {'metodo': 'totp'},
            );
          }
          return;
        }

        final usuario = _aplicarPerfil(perfil);
        themeController.definirPapelSessao(usuario.tipo);

        AppDestinoRota destino;

        // ----------------------------------------------------------
        // 🔹 Lógica de roteamento por tipo de usuário
        // ----------------------------------------------------------
        switch (usuario.tipo) {
          case 'F': // 🧑‍🔧 Fornecedor
            destino = await _resolverDestinoFornecedor(usuario.idUsuario);
            break;

          case 'C': // 🎁 Convidado
            destino = await convite.resolverDestinoConvidado(usuario, token: token);
            break;

          case 'A': // 🛠️ Administrador
            themeController.aplicarTemaProduto();
            servicoController.carregarServicosComDetalhesOtimizado();
            _validarDependenciasAdminDashboard();
            destino = const AppDestinoRota('/admin');
            break;

          default: // 🎉 Organizador
            await eventoController.carregarEventosDoUsuario(usuario.idUsuario);
            final evento = eventoController.eventoAtualEntidade;

            if (evento != null) {
              debugPrint(
                  '🔹 Evento ativo: ${evento.nomeEvento} (${evento.idEvento})');
              cotacaoController.ouvirMinhasCotacoes();
              _validarDependenciasHomeEvent();
              destino = const AppDestinoRota('/HomeEventScreen');
            } else {
              contaIncompleta.value = true;
              if (Get.currentRoute == '/welcome') {
                carregando.value = false;
                return;
              }
              destino = const AppDestinoRota('/welcome');
            }
            break;
        }

        carregando.value = false;
        final rotaDepois = Get.currentRoute;
        if (AppRotasSessao.destinoEstavel(rotaDepois) ||
            AppRotasSessao.usuarioJaNavegando(
              rotaDepois,
              temUsuario: usuarioLogado.value != null,
            )) {
          return;
        }
        Get.offAllNamed(destino.nome, arguments: destino.argumentos);
      } catch (e, s) {
        carregando.value = false;
        debugPrint('❌ Erro ao validar sessão: $e\n$s');
        Get.snackbar(
          'Erro de sessão',
          'Não foi possível validar sua conta. Tente novamente.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        Get.offAllNamed('/role');
      }
    } finally {
      _processandoSessao = false;
      if (_sessaoPendente) {
        _sessaoPendente = false;
        final idUsuario = autenticacaoRepository.idUsuarioAtual;
        unawaited(_processarSessao(idUsuario == null
            ? null
            : SessaoUsuario(
                idUsuario: idUsuario,
                email: autenticacaoRepository.emailUsuarioAtual,
              )));
      }
    }
  }

  Future<PerfilUsuario?> _carregarPerfilComTentativas(String idUsuario) async {
    for (var tentativa = 1; tentativa <= 8; tentativa++) {
      final perfil = await perfilUsuarioRepository.carregarPerfil(idUsuario);
      if (perfil != null) return perfil;

      debugPrint(
        '$_logTag Perfil $idUsuario ainda não disponível no Firestore. '
        'Tentativa $tentativa/8.',
      );
      await Future.delayed(const Duration(milliseconds: 350));
    }

    return null;
  }

  RxString get conviteToken => convite.conviteToken;
  RxBool get acessoPorLink => convite.acessoPorLink;
  bool get fluxoConviteAtivo => convite.fluxoConviteAtivo;

  String? obterTokenConvite() => convite.obterTokenConvite();

  String? tokenConviteAtual() => convite.tokenConviteAtual();

  void guardarTokenConvite(String token) =>
      convite.guardarTokenConvite(token);

  Future<void> abrirConvite(String token) => convite.abrirConvite(token);

  Future<void> redirecionarConvidadoAposLogin(
    Usuario usuario, {
    String? token,
  }) =>
      convite.redirecionarConvidadoAposLogin(usuario, token: token);

  Future<AppDestinoRota> _resolverDestinoFornecedor(String idUsuario) async {
    final fornecedor = await fornecedores.buscarPorUsuario(idUsuario);

    if (fornecedor == null) {
      fornecedorController.fornecedor.value = null;
      fornecedorController.aptoParaOperar.value = false;
      return const AppDestinoRota('/fornecedor');
    }

    fornecedorController.fornecedor.value = fornecedor;
    fornecedorController.aptoParaOperar.value = fornecedor.aptoParaOperar;

    if (!fornecedor.aptoParaOperar) {
      return const AppDestinoRota('/fornecedor');
    }

    await _iniciarPainelOperacionalFornecedor(fornecedor);
    themeController.aplicarTemaProduto();
    return const AppDestinoRota('/fornecedor');
  }

  Future<void> _iniciarPainelOperacionalFornecedor(
    Fornecedor fornecedor,
  ) async {
    await atualizarFcmTokenFornecedor(fornecedor.idUsuario);

    fornecedorController.ouvirMensagensNaoLidas(fornecedor.idUsuario);
    fornecedorController.iniciarListenerFornecedor(fornecedor.idUsuario);
    fornecedorController.escutarSolicitacoesPendentes(fornecedor.idUsuario);

    orcamentoController.escutarOrcamentos(fornecedor.idUsuario);
    avaliacaoController.carregarAvaliacoesFornecedor(fornecedor.idUsuario);
    servicoController.carregarServicosComDetalhesOtimizado(
      idFornecedor: fornecedor.idUsuario,
    );
  }

  /// Recarrega o cadastro do fornecedor logado. Se o admin já aprovou
  /// (`apto_para_operar`), abre a home operacional nesta sessão.
  Future<void> verificarAprovacaoFornecedorPendente() async {
    final usuario = usuarioLogado.value;
    if (usuario == null || usuario.tipo != 'F') return;
    if (carregando.value) return;

    carregando.value = true;
    try {
      final destino = await _resolverDestinoFornecedor(usuario.idUsuario);
      if (fornecedorController.aptoParaOperar.value) {
        Get.offAllNamed(destino.nome, arguments: destino.argumentos);
        return;
      }

      Get.snackbar(
        'Em análise',
        'Seu cadastro ainda não foi aprovado pelo administrador.',
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      carregando.value = false;
    }
  }

  // ------------------------------------------------------------
  // 🔹 Logout
  // ------------------------------------------------------------

  Future<void> logout() async {
    await _encerrarSessao();
  }

  Future<void> logoutFornecedor() async {
    await _encerrarSessao(limparFornecedorAntes: true);
  }

  Future<void> _encerrarSessao({bool limparFornecedorAntes = false}) async {
    if (encerrandoSessao.value) return;
    encerrandoSessao.value = true;
    try {
      if (limparFornecedorAntes) {
        fornecedorController.logoutFornecedor();
      }

      await _sessaoSub?.cancel();
      _sessaoSub = null;

      await _pararEscutasDaSessao();
      await _registrarLogoutAuditoria();

      await autenticacaoRepository.sair();
      usuarioLogado.value = null;
      enderecoPrincipal.value = null;
      enderecosUsuario.clear();
      carrinho.limpar();
      convite.limpar();
      totp.limpar();
      themeController.definirPapelSessao(null);
      themeController.aplicarTemaProduto();
      Get.offAllNamed('/role');
      _monitorarSessao();
    } finally {
      encerrandoSessao.value = false;
    }
  }

  Future<void> _registrarLogoutAuditoria() async {
    try {
      final auditoria = _auditoria ?? _auditoriaResolver?.call();
      if (auditoria == null) return;

      final usuario = usuarioLogado.value;
      await auditoria.registrar(
        RegistroAuditoria(
          acao: 'LOGOUT_REALIZADO',
          resumo: 'Logout realizado pelo usuário.',
          entidadeTipo: 'sessao',
          entidadeId: autenticacaoRepository.idUsuarioAtual,
          entidadeNome:
              usuario?.email ?? autenticacaoRepository.emailUsuarioAtual,
          detalhe: {
            'tipo': usuario?.tipo,
            'email': usuario?.email ?? autenticacaoRepository.emailUsuarioAtual,
          },
          rota: Get.currentRoute,
        ),
      );
    } catch (_) {
      // Auditoria de logout não pode impedir o encerramento da sessão.
    }
  }

  Future<void> _pararEscutasDaSessao() async {
    await eventoController.encerrarEscutas();
    await orcamentoController.encerrarEscutas();
    await tarefaController.encerrarEscutas();
    await cotacaoController.encerrarEscutas();
    fornecedorController.logoutFornecedor();

    await _resolverOrcamentoGastoController()?.encerrarEscutas();
    await _resolverFornecedorLocalizacaoController()?.encerrarEscutas();
    await _resolverInspiracaoController()?.encerrarEscutas();
  }

  // ------------------------------------------------------------
  // 🔹 Usuários (CRUD básico)
  // ------------------------------------------------------------
  Future<void> salvarUsuario(Usuario usuario) async {
    await perfilUsuarioRepository.salvarUsuario(usuario);
    usuarioLogado.value = usuario;
  }

  Future<Usuario?> obterUsuario(String id) async {
    return perfilUsuarioRepository.buscarUsuario(id);
  }

  Usuario _aplicarPerfil(PerfilUsuario perfil) {
    final usuario = perfil.usuario;
    final enderecos = perfil.enderecos;

    enderecosUsuario.assignAll(enderecos);
    if (enderecos.isEmpty) {
      enderecoPrincipal.value = null;
      usuarioLogado.value = usuario;
      _sincronizarUsuarioController(usuario);
      return usuario;
    }

    final principal = enderecos.firstWhere(
      (endereco) => endereco.principal,
      orElse: () => enderecos.first,
    );
    enderecoPrincipal.value = principal;
    final usuarioComEndereco = usuario.copyWith(
      cidade: principal.nomeCidade,
      uf: principal.uf,
    );
    usuarioLogado.value = usuarioComEndereco;
    _sincronizarUsuarioController(usuarioComEndereco);
    return usuarioComEndereco;
  }

  void marcarLoginComSenha() => totp.marcarLoginComSenha();

  void marcarLoginComGoogle() => totp.marcarLoginComGoogle();

  void marcarTotpVerificado() => totp.marcarVerificado();

  void _sincronizarUsuarioController(Usuario usuario) {
    final controller = _resolverUsuarioController();
    if (controller == null) return;
    controller.usuario.value = usuario;
  }

  OrcamentoGastoController? _resolverOrcamentoGastoController() {
    if (_orcamentoGastoController != null) return _orcamentoGastoController;
    return _orcamentoGastoControllerResolver?.call();
  }

  void _validarDependenciasHomeEvent() {
    final fornecedorLocalizacao = _resolverFornecedorLocalizacaoController();
    if (fornecedorLocalizacao == null) {
      throw StateError('FornecedorLocalizacaoController não configurado.');
    }
    final inspiracao = _resolverInspiracaoController();
    if (inspiracao == null) {
      throw StateError('InspiracaoController não configurado.');
    }
    final usuario = _resolverUsuarioController();
    if (usuario == null) {
      throw StateError('UsuarioController não configurado.');
    }
  }

  void _validarDependenciasAdminDashboard() {
    final fornecedorLocalizacao = _resolverFornecedorLocalizacaoController();
    if (fornecedorLocalizacao == null) {
      throw StateError('FornecedorLocalizacaoController não configurado.');
    }
    final usuario = _resolverUsuarioController();
    if (usuario == null) {
      throw StateError('UsuarioController não configurado.');
    }
  }

  FornecedorLocalizacaoController? _resolverFornecedorLocalizacaoController() {
    if (_fornecedorLocalizacaoController != null) {
      return _fornecedorLocalizacaoController;
    }
    return _fornecedorLocalizacaoControllerResolver?.call();
  }

  InspiracaoController? _resolverInspiracaoController() {
    if (_inspiracaoController != null) return _inspiracaoController;
    return _inspiracaoControllerResolver?.call();
  }

  UsuarioController? _resolverUsuarioController() {
    if (_usuarioController != null) return _usuarioController;
    return _usuarioControllerResolver?.call();
  }

  Future<void> atualizarFcmTokenFornecedor(String idFornecedor) async {
    if (!pushTokenRepository.suportaTokenPush) {
      if (kDebugMode) {
        print('ℹ️ FCM não suportado nesta plataforma para fornecedor.');
      }
      return;
    }

    try {
      await pushTokenRepository.solicitarPermissao();

      final token = await pushTokenRepository.obterTokenAtual();
      if (token == null || token.isEmpty) return;

      await fornecedores.atualizarFcmToken(
        idFornecedor: idFornecedor,
        token: token,
      );

      await _fcmTokenSub?.cancel();
      _fcmTokenSub = pushTokenRepository.observarAtualizacoesToken().listen((
        newToken,
      ) async {
        if (newToken.isEmpty) return;

        await fornecedores.atualizarFcmToken(
          idFornecedor: idFornecedor,
          token: newToken,
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar FCM token do fornecedor: $e');
      }
    }
  }

  // ------------------------------------------------------------
  // 🔹 Utilitário genérico
  // ------------------------------------------------------------
  Future<void> excluirDocumento(String colecao, String idDocumento) async {
    await documentos.excluirDocumento(
      colecao: colecao,
      idDocumento: idDocumento,
    );
  }

  /// 🔹 Adiciona serviço à lista (evita duplicatas)
  void adicionarServico(ServicoCotado servico) => carrinho.adicionar(servico);

  /// 🔹 Remove serviço da lista
  void removerServico(String idProduto) => carrinho.remover(idProduto);

  /// 🔹 Limpa todos os serviços selecionados
  void limparServicosSelecionados() => carrinho.limpar();

  /// 🔹 Verifica se um serviço está selecionado
  bool isServicoSelecionado(String idProduto) => carrinho.contem(idProduto);

  @override
  void onClose() {
    _sessaoSub?.cancel();
    _fcmTokenSub?.cancel();
    super.onClose();
  }
}
