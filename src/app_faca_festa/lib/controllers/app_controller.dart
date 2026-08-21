import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './../presentation/pages/convidado/convite_nao_encontrado_screen.dart';
import './../presentation/pages/fornecedor/fornecedor_aguardando_aprovacao_screen.dart';
import './../presentation/pages/fornecedor/fornecedor_home_screen.dart';
import './../presentation/pages/admin/admin_dashboard_screen.dart';
import './../presentation/pages/welcome/welcome_event_screen.dart';
import './../presentation/pages/home_event_screen.dart';
import './avaliacao/avaliacao_servico_controller.dart';
import './../data/models/DTO/servico_cotado_dto.dart';
import './convidado/convidado_controller.dart';
import './contacao/cotacao_controller.dart';
import 'servico/servico_produto_controller.dart';
import 'fornecedor/fornecedor_controller.dart';
import './orcamento_controller.dart';
import './../data/models/model.dart';
import './../core/utils/convite_link.dart';
import './../data/services/convite/abrir_convite_por_token_service.dart';
import './../domain/repositories/convite_convidado_repository.dart';
import './../domain/repositories/autenticacao_repository.dart';
import './../domain/repositories/perfil_usuario_repository.dart';
import './evento_controller.dart';
import './tarefa_controller.dart';
import './usuario/usuario_controller.dart';
import './orcamento_gasto_controller.dart';
import './inspiracao/inspiracao_controller.dart';
import 'fornecedor/fornecedor_localizacao_controller.dart';
import 'tema/event_theme_controller.dart';

class AppController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Estado reativo do usuário
  final Rx<UsuarioModel?> usuarioLogado = Rx<UsuarioModel?>(null);
  final Rx<EnderecoUsuarioModel?> enderecoPrincipal =
      Rx<EnderecoUsuarioModel?>(null);
  final RxList<EnderecoUsuarioModel> enderecosUsuario =
      <EnderecoUsuarioModel>[].obs;

  /// 🔹 Lista global de serviços selecionados para cotação
  final RxList<ServicoCotadoDto> servicosSelecionados =
      <ServicoCotadoDto>[].obs;

  final RxBool contaIncompleta = false.obs;
  bool conviteProcessado = false;
  String conviteTokenProcessado = '';
  RxString conviteToken = ''.obs;
  final RxBool acessoPorLink = false.obs;
  final RxBool carregando = false.obs;
  final RxBool encerrandoSessao = false.obs;
  StreamSubscription<SessaoUsuario?>? _sessaoSub;
  bool _processandoSessao = false;
  bool _sessaoPendente = false;
  bool totpVerificadoNestaSessao = false;
  bool devMode = true;

  static const String _logTag = '[AppController]';
  static const String _chaveLoginMetodo = 'login_metodo';
  static const String _metodoSenha = 'senha';
  static const String _metodoGoogle = 'google';
  final GetStorage _storage = GetStorage();
  final conviteConvidadoRepository = Get.find<ConviteConvidadoRepository>();
  final autenticacaoRepository = Get.find<AutenticacaoRepository>();
  final perfilUsuarioRepository = Get.find<PerfilUsuarioRepository>();
  final _abrirConvitePorTokenService = AbrirConvitePorTokenService();

  // ✅ Injeção de controladores auxiliares
  final convidadoController = Get.find<ConvidadoController>();
  final eventoController = Get.find<EventoController>();
  final orcamentoController = Get.put(OrcamentoController());
  final cotacaoController = Get.put(CotacaoController());
  final fornecedorController = Get.put(FornecedorController());
  final tarefaController = Get.find<TarefaController>();
  final avaliacaoController = Get.put(AvaliacaoServicoController());
  final servicoController = Get.put(ServicoProdutoController());
  final themeController = Get.put(EventThemeController());

  @override
  void onInit() {
    super.onInit();

    // O token do link é a credencial. Auth anônimo + callable abrem a área
    // sem cadastro; id_usuario só é gravado depois de conta real.
    final token = obterTokenConvite();
    if (token != null && token.isNotEmpty) {
      conviteToken.value = token;
      debugPrint('$_logTag Token de convite capturado no onInit: $token');
    }

    _monitorarSessao();
  }

  // ------------------------------------------------------------
  // 🔹 Carrega usuário logado e endereço principal
  // ------------------------------------------------------------
  Future<UsuarioModel?> prepararUsuarioComEndereco() async {
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
    Get.offAll(
      () => const HomeEventScreen(),
      routeName: '/HomeEventScreen',
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 450),
    );
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
      final token = _tokenConviteAtual();

      if (acessoPorLink.value &&
          (user == null ||
              autenticacaoRepository.sessaoAnonima ||
              autenticacaoRepository.sessaoVisitanteConvite)) {
        debugPrint(
            '$_logTag Visita por convite em andamento. Sem redirecionar.');
        return;
      }

      if (acessoPorLink.value &&
          user != null &&
          !autenticacaoRepository.sessaoAnonima &&
          !autenticacaoRepository.sessaoVisitanteConvite) {
        acessoPorLink.value = false;
      }

      if (user == null) {
        _limparEstadoTotp();
        if (token != null && token.isNotEmpty) {
          conviteToken.value = token;
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
          !_rotaTotp(rotaAtual) &&
          !_rotaDestinoEstavel(rotaAtual) &&
          !_usuarioJaNavegandoNaApp(rotaAtual) &&
          (rotaAtual.isEmpty || rotaAtual != '/splash')) {
        Future.microtask(() {
          if (_rotaTotp(Get.currentRoute)) return;
          if (Get.currentRoute.startsWith('/convite')) return;
          if (_rotaDestinoEstavel(Get.currentRoute)) return;
          if (_usuarioJaNavegandoNaApp(Get.currentRoute)) return;
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

        final usuarioTotp = UsuarioModel.fromEntity(perfil.usuario);
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

        if (_deveExigirTotp()) {
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

        Widget destino;

        // ----------------------------------------------------------
        // 🔹 Lógica de roteamento por tipo de usuário
        // ----------------------------------------------------------
        switch (usuario.tipo) {
          case 'F': // 🧑‍🔧 Fornecedor
            destino = await _resolverDestinoFornecedor(usuario.idUsuario);
            break;

          case 'C': // 🎁 Convidado
            destino = await _resolverDestinoConvidado(usuario, token: token);
            break;

          case 'A': // 🛠️ Administrador
            themeController.aplicarTemaProduto();
            servicoController.carregarServicosComDetalhesOtimizado();
            destino = const AdminDashboardScreen();
            break;

          default: // 🎉 Organizador
            await eventoController.carregarEventosDoUsuario(usuario.idUsuario);
            final evento = eventoController.eventoAtualEntidade;

            if (evento != null) {
              debugPrint(
                  '🔹 Evento ativo: ${evento.nomeEvento} (${evento.idEvento})');
              cotacaoController.ouvirMinhasCotacoes();
              destino = HomeEventScreen();
            } else {
              contaIncompleta.value = true;
              if (Get.currentRoute == '/welcome') {
                carregando.value = false;
                return;
              }
              destino = const WelcomeEventScreen();
            }
            break;
        }

        carregando.value = false;
        final rotaDepois = Get.currentRoute;
        if (_rotaDestinoEstavel(rotaDepois) ||
            _usuarioJaNavegandoNaApp(rotaDepois)) {
          return;
        }
        Get.offAll(
          () => destino,
          routeName: _nomeRotaDestino(destino),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 550),
        );
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

  String? obterTokenConvite() {
    return ConviteLink.tokenDaUrl();
  }

  /// Token do link `/convite/:token` (URL ou memória). Credencial do convidado.
  String? tokenConviteAtual() => _tokenConviteAtual();

  /// Há convite pendente: o login/cadastro Google deve criar tipo C, não O.
  bool get fluxoConviteAtivo {
    final token = _tokenConviteAtual();
    return token != null && token.isNotEmpty;
  }

  void guardarTokenConvite(String token) {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return;
    conviteToken.value = tokenLimpo;
  }

  String? _tokenConviteAtual() {
    final tokenUrl = obterTokenConvite();
    if (tokenUrl != null && tokenUrl.isNotEmpty) {
      conviteToken.value = tokenUrl;
      return tokenUrl;
    }

    final tokenMemoria = conviteToken.value.trim();
    return tokenMemoria.isEmpty ? null : tokenMemoria;
  }

  /// Abre o convite. Sem conta real, entra como visitante (auth anônimo).
  /// Conta tipo C vincula o token ao UID. Outros papéis são recusados.
  Future<void> abrirConvite(String token) async {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return;

    conviteToken.value = tokenLimpo;
    conviteProcessado = false;
    conviteTokenProcessado = '';

    final idUsuario = autenticacaoRepository.idUsuarioAtual;
    final anonimo = autenticacaoRepository.sessaoAnonima;

    if (idUsuario != null && !anonimo) {
      final usuario = await obterUsuario(idUsuario);
      if (usuario == null) {
        await _abrirConviteComoVisitante(tokenLimpo);
        return;
      }

      if (usuario.tipo != 'C') {
        Get.snackbar(
          'Convite de convidado',
          'Este link deve ser acessado por uma conta de convidado.',
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
        );
        return;
      }

      acessoPorLink.value = false;
      await redirecionarConvidadoAposLogin(usuario, token: tokenLimpo);
      return;
    }

    await _abrirConviteComoVisitante(tokenLimpo);
  }

  Future<void> _abrirConviteComoVisitante(String token) async {
    acessoPorLink.value = true;
    try {
      if (autenticacaoRepository.idUsuarioAtual == null) {
        await autenticacaoRepository.entrarAnonimamente();
      }

      final resultado = await _abrirConvitePorTokenService.abrir(token);
      final convidado = ConvidadoModel.fromMap(resultado.convidado);
      final evento = EventoModel.fromMap(resultado.evento);
      if (convidado.idConvidado.isEmpty || evento.idEvento.isEmpty) {
        throw const AbrirConvitePorTokenException('not-found');
      }

      eventoController.eventoAtual.value = evento;
      await eventoController.buscarTipoEvento(evento.idTipoEvento);
      await themeController.aplicarParaEvento(
        evento,
        fallbackNomeTipo: eventoController.tipoEventoAtualEntidade?.nome,
      );

      conviteProcessado = true;
      conviteTokenProcessado = token;
      convidadoController.convidadoAtual.value = convidado;

      Get.offAll(
        () => AreaConvidadoHomeScreen(convidado: convidado, evento: evento),
        routeName: '/areaconvidado',
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 550),
      );
    } on AutenticacaoException catch (e) {
      acessoPorLink.value = false;
      debugPrint('$_logTag Auth ao abrir convite: ${e.codigo}');
      Get.snackbar(
        'Convite',
        e.codigo == 'operation-not-allowed' ||
                e.codigo == 'admin-restricted-operation'
            ? 'Acesso pelo link está temporariamente indisponível.'
            : 'Não foi possível abrir o convite. Tente novamente.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      Get.offAllNamed('/conviteNaoEncontrado');
    } catch (e, s) {
      acessoPorLink.value = false;
      debugPrint('$_logTag Erro ao abrir convite como visitante: $e\n$s');
      Get.offAllNamed('/conviteNaoEncontrado');
    }
  }

  /// Usado também pelo cadastro: depois de criar uma conta do tipo convidado,
  /// vincula convites pendentes pelo token e/ou pelo e-mail do usuário.
  Future<void> redirecionarConvidadoAposLogin(UsuarioModel usuario,
      {String? token}) async {
    carregando.value = true;
    try {
      final destino = await _resolverDestinoConvidado(usuario, token: token);
      carregando.value = false;
      Get.offAll(
        () => destino,
        routeName: _nomeRotaDestino(destino),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 550),
      );
    } catch (e, s) {
      carregando.value = false;
      debugPrint('$_logTag Erro ao redirecionar convidado: $e\n$s');
      Get.offAllNamed('/conviteNaoEncontrado');
    }
  }

  Future<Widget> _resolverDestinoConvidado(UsuarioModel usuario,
      {String? token}) async {
    final tokenLimpo = (token ?? _tokenConviteAtual() ?? '').trim();
    final email = usuario.email.trim();

    debugPrint(
      '$_logTag Resolvendo destino do convidado | uid=${usuario.idUsuario} | '
      "email=$email | token=${tokenLimpo.isEmpty ? 'sem token' : tokenLimpo}",
    );

    Convidado? convidado;

    if (tokenLimpo.isNotEmpty && conviteTokenProcessado != tokenLimpo) {
      convidado = await _vincularConvitePorToken(
        token: tokenLimpo,
        uid: usuario.idUsuario,
        email: email,
      );
      conviteProcessado = convidado != null;
      if (convidado != null) conviteTokenProcessado = tokenLimpo;
    }

    convidado ??= await _buscarOuVincularConvitePorUsuario(
      uid: usuario.idUsuario,
      email: email,
    );

    if (convidado == null) {
      debugPrint('$_logTag Nenhum convite encontrado para ${usuario.email}.');
      return const ConviteNaoEncontradoScreen();
    }

    final evento =
        await eventoController.buscarEventoPeloIdEvento(convidado.idEvento);
    if (evento == null) {
      debugPrint(
          '$_logTag Convite encontrado, mas evento não existe: ${convidado.idEvento}.');
      return const ConviteNaoEncontradoScreen();
    }

    eventoController.eventoAtual.value = evento;
    await eventoController.buscarTipoEvento(evento.idTipoEvento);
    await themeController.aplicarParaEvento(
      evento,
      fallbackNomeTipo: eventoController.tipoEventoAtualEntidade?.nome,
    );

    return AreaConvidadoHomeScreen(convidado: convidado, evento: evento);
  }

  Future<Convidado?> _vincularConvitePorToken({
    required String token,
    required String uid,
    required String email,
  }) async {
    try {
      return await conviteConvidadoRepository.vincularPorToken(
        token: token,
        uid: uid,
        email: email,
      );
    } on ConviteJaVinculadoException {
      _mostrarConviteJaVinculado();
      return null;
    } catch (e, s) {
      debugPrint('$_logTag Erro ao vincular convite por token: $e\n$s');
      return null;
    }
  }

  Future<Convidado?> _buscarOuVincularConvitePorUsuario({
    required String uid,
    required String email,
  }) async {
    try {
      return await conviteConvidadoRepository.buscarOuVincularPorUsuario(
        uid: uid,
        email: email,
      );
    } on ConviteJaVinculadoException {
      _mostrarConviteJaVinculado();
      return null;
    } catch (e, s) {
      debugPrint(
          '$_logTag Erro ao buscar/vincular convite por usuário: $e\n$s');
      return null;
    }
  }

  void _mostrarConviteJaVinculado() {
    Get.snackbar(
      'Convite já vinculado',
      'Este convite já está associado a outra conta.',
      backgroundColor: Colors.orange.shade600,
      colorText: Colors.white,
    );
  }

  Future<Widget> _resolverDestinoFornecedor(String idUsuario) async {
    final fornecedorDoc =
        await _db.collection('fornecedor').doc(idUsuario).get();

    if (!fornecedorDoc.exists || fornecedorDoc.data() == null) {
      fornecedorController.fornecedor.value = null;
      fornecedorController.aptoParaOperar.value = false;
      return const FornecedorAguardandoAprovacaoScreen();
    }

    final fornecedor = FornecedorModel.fromMap(
      fornecedorDoc.data()!,
      documentId: fornecedorDoc.id,
    );
    fornecedorController.fornecedor.value = fornecedor;
    fornecedorController.aptoParaOperar.value = fornecedor.aptoParaOperar;

    if (!fornecedor.aptoParaOperar) {
      return const FornecedorAguardandoAprovacaoScreen();
    }

    await _iniciarPainelOperacionalFornecedor(fornecedor);
    themeController.aplicarTemaProduto();
    return const FornecedorHomeScreen();
  }

  Future<void> _iniciarPainelOperacionalFornecedor(
    FornecedorModel fornecedor,
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
        Get.offAll(
          () => destino,
          routeName: _nomeRotaDestino(destino),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 450),
        );
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

      await autenticacaoRepository.sair();
      usuarioLogado.value = null;
      enderecoPrincipal.value = null;
      enderecosUsuario.clear();
      servicosSelecionados.clear();
      conviteProcessado = false;
      conviteTokenProcessado = '';
      conviteToken.value = '';
      acessoPorLink.value = false;
      _limparEstadoTotp();
      themeController.definirPapelSessao(null);
      themeController.aplicarTemaProduto();
      Get.offAllNamed('/role');
      _monitorarSessao();
    } finally {
      encerrandoSessao.value = false;
    }
  }

  Future<void> _pararEscutasDaSessao() async {
    await eventoController.encerrarEscutas();
    await orcamentoController.encerrarEscutas();
    await tarefaController.encerrarEscutas();
    await cotacaoController.encerrarEscutas();
    fornecedorController.logoutFornecedor();

    if (Get.isRegistered<OrcamentoGastoController>()) {
      await Get.find<OrcamentoGastoController>().encerrarEscutas();
    }
    if (Get.isRegistered<FornecedorLocalizacaoController>()) {
      await Get.find<FornecedorLocalizacaoController>().encerrarEscutas();
    }
    if (Get.isRegistered<InspiracaoController>()) {
      await Get.find<InspiracaoController>().encerrarEscutas();
    }
  }

  // ------------------------------------------------------------
  // 🔹 Usuários (CRUD básico)
  // ------------------------------------------------------------
  Future<void> salvarUsuario(UsuarioModel usuario) async {
    await perfilUsuarioRepository.salvarUsuario(usuario);
    usuarioLogado.value = usuario;
  }

  Future<UsuarioModel?> obterUsuario(String id) async {
    final usuario = await perfilUsuarioRepository.buscarUsuario(id);
    return usuario == null ? null : UsuarioModel.fromEntity(usuario);
  }

  UsuarioModel _aplicarPerfil(PerfilUsuario perfil) {
    final usuario = UsuarioModel.fromEntity(perfil.usuario);
    final enderecos = perfil.enderecos
        .map(EnderecoUsuarioModel.fromEntity)
        .toList(growable: false);

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

  void marcarLoginComSenha() {
    totpVerificadoNestaSessao = false;
    _storage.write(_chaveLoginMetodo, _metodoSenha);
  }

  void marcarLoginComGoogle() {
    totpVerificadoNestaSessao = true;
    _storage.write(_chaveLoginMetodo, _metodoGoogle);
  }

  void marcarTotpVerificado() {
    totpVerificadoNestaSessao = true;
  }

  bool _deveExigirTotp() {
    if (totpVerificadoNestaSessao) return false;
    if (_storage.read(_chaveLoginMetodo) == _metodoGoogle) return false;
    if (!_contaTemLoginComSenha()) return false;
    return true;
  }

  bool _contaTemLoginComSenha() {
    final providers =
        FirebaseAuth.instance.currentUser?.providerData ?? const [];
    return providers.any((provider) => provider.providerId == 'password');
  }

  bool _rotaTotp(String rota) =>
      rota == '/loginTotp' || rota == '/loginTotpSetup';

  bool _rotaDestinoEstavel(String rota) {
    return rota == '/HomeEventScreen' ||
        rota.startsWith('/HomeEventScreen/') ||
        rota == '/welcome' ||
        rota == '/fornecedor' ||
        rota == '/fornecedores' ||
        rota == '/admin' ||
        rota == '/areaconvidado' ||
        rota.startsWith('/areaconvidado') ||
        rota == '/conviteNaoEncontrado';
  }

  /// Subtelas abertas com Get.to() (ex.: lista de fornecedores) não são
  /// `/HomeEventScreen`. Sem esta guarda, qualquer revalidação de sessão
  /// manda o usuário de volta à splash e ela fica eterna.
  bool _usuarioJaNavegandoNaApp(String rota) {
    if (usuarioLogado.value == null) return false;
    if (rota.isEmpty) return false;
    if (rota == '/splash' ||
        rota == '/' ||
        rota == '/notfound' ||
        rota == '/role' ||
        rota == '/login' ||
        rota == '/register' ||
        rota == '/forgotPassword' ||
        _rotaTotp(rota)) {
      return false;
    }
    return true;
  }

  String? _nomeRotaDestino(Widget destino) {
    if (destino is HomeEventScreen) return '/HomeEventScreen';
    if (destino is WelcomeEventScreen) return '/welcome';
    if (destino is FornecedorHomeScreen ||
        destino is FornecedorAguardandoAprovacaoScreen) {
      return '/fornecedor';
    }
    if (destino is AdminDashboardScreen) return '/admin';
    if (destino is AreaConvidadoHomeScreen) return '/areaconvidado';
    if (destino is ConviteNaoEncontradoScreen) return '/conviteNaoEncontrado';
    return null;
  }

  void _limparEstadoTotp() {
    totpVerificadoNestaSessao = false;
    _storage.remove(_chaveLoginMetodo);
  }

  void _sincronizarUsuarioController(UsuarioModel usuario) {
    if (!Get.isRegistered<UsuarioController>()) return;
    Get.find<UsuarioController>().usuario.value = usuario;
  }

  Future<void> atualizarFcmTokenFornecedor(String idFornecedor) async {
    if (!suportaFcmFornecedor) {
      if (kDebugMode) {
        print('ℹ️ FCM não suportado nesta plataforma para fornecedor.');
      }
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('fornecedor')
          .doc(idFornecedor)
          .update({
        'fcm_token': token,
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;

        await FirebaseFirestore.instance
            .collection('fornecedor')
            .doc(idFornecedor)
            .update({
          'fcm_token': newToken,
        });
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
    await _db.collection(colecao).doc(idDocumento).delete();
  }

  /// 🔹 Adiciona serviço à lista (evita duplicatas)
  void adicionarServico(ServicoCotadoDto servico) {
    if (!servicosSelecionados.any((s) => s.idProduto == servico.idProduto)) {
      servicosSelecionados.add(servico);
    }
  }

  /// 🔹 Remove serviço da lista
  void removerServico(String idProduto) {
    servicosSelecionados.removeWhere((s) => s.idProduto == idProduto);
  }

  /// 🔹 Limpa todos os serviços selecionados
  void limparServicosSelecionados() {
    servicosSelecionados.clear();
  }

  /// 🔹 Verifica se um serviço está selecionado
  bool isServicoSelecionado(String idProduto) {
    return servicosSelecionados.any((s) => s.idProduto == idProduto);
  }

  bool get suportaFcmFornecedor {
    if (kIsWeb) return true;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void onClose() {
    _sessaoSub?.cancel();
    super.onClose();
  }
}
