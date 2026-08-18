import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './../presentation/pages/convidado/convite_nao_encontrado_screen.dart';
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
  final RxBool carregando = false.obs;
  final RxBool encerrandoSessao = false.obs;
  StreamSubscription<SessaoUsuario?>? _sessaoSub;
  bool _processandoSessao = false;
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

    // Quando o app é aberto por um link /convite/{token}, não abrimos a área
    // do convidado de forma anônima. Guardamos o token para vincular ao UID
    // assim que o usuário fizer login/cadastro como convidado.
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

      await buscarUltimoEvento(idUsuario);

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
      debugPrint('$_logTag Validação de sessão já em andamento. Ignorando.');
      return;
    }
    _processandoSessao = true;

    try {
      await Future.delayed(
          const Duration(milliseconds: 300)); // ✅ pequeno delay
      // 🔥 verifica token de convite primeiro
      final token = _tokenConviteAtual();

      if (user == null) {
        _limparEstadoTotp();
        if (token != null && token.isNotEmpty && !conviteProcessado) {
          conviteToken.value = token;
          debugPrint(
              '$_logTag Convidado acessando via convite sem sessão: $token');

          // Mantém o convidado no fluxo de autenticação. O token será vinculado
          // depois do login/cadastro.
          if (Get.currentRoute != '/role') {
            Get.offAllNamed('/role', arguments: {
              'tipo': 'C',
              'convidado': true,
              'conviteToken': token,
            });
          }
          return;
        }

        usuarioLogado.value = null;
        enderecoPrincipal.value = null;
        eventoController.limparSessaoAtual();

        if (Get.currentRoute != '/role') Get.offAllNamed('/role');
        return;
      }

      if (!_rotaTotp(Get.currentRoute) &&
          (Get.currentRoute.isEmpty || Get.currentRoute != '/splash')) {
        Future.microtask(() {
          if (_rotaTotp(Get.currentRoute)) return;
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

        Widget destino;

        // ----------------------------------------------------------
        // 🔹 Lógica de roteamento por tipo de usuário
        // ----------------------------------------------------------
        switch (usuario.tipo) {
          case 'F': // 🧑‍🔧 Fornecedor
            final fornecedorDoc =
                await _db.collection('fornecedor').doc(usuario.idUsuario).get();

            if (fornecedorDoc.exists && fornecedorDoc.data() != null) {
              final fornecedor = FornecedorModel.fromMap(fornecedorDoc.data()!);

              // 🔥 Atualiza Token FCM no login
              await atualizarFcmTokenFornecedor(usuario.idUsuario);

              if (!fornecedor.aptoParaOperar) {
                Get.snackbar(
                  "Em análise",
                  "Seu cadastro ainda não foi aprovado pelo administrador.",
                  backgroundColor: Colors.orange.shade400,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              }
              fornecedorController.fornecedor.value = fornecedor;

              fornecedorController.ouvirMensagensNaoLidas(fornecedor.idUsuario);
              fornecedorController
                  .iniciarListenerFornecedor(fornecedor.idUsuario);
              fornecedorController
                  .escutarSolicitacoesPendentes(fornecedor.idUsuario);

              orcamentoController.escutarOrcamentos(fornecedor.idUsuario);
              avaliacaoController
                  .carregarAvaliacoesFornecedor(fornecedor.idUsuario);
              servicoController.carregarServicosComDetalhesOtimizado(
                  idFornecedor: fornecedor.idUsuario);
            }
            destino = FornecedorHomeScreen();
            break;

          case 'C': // 🎁 Convidado
            destino = await _resolverDestinoConvidado(usuario, token: token);
            break;

          case 'A': // 🛠️ Administrador
            servicoController.carregarServicosComDetalhesOtimizado();
            destino = const AdminDashboardScreen();
            break;

          default: // 🎉 Organizador
            await eventoController.buscarUltimoEvento(usuario.idUsuario);
            final evento = eventoController.eventoAtualEntidade;

            if (evento != null) {
              debugPrint(
                  '🔹 Carregando dados do evento ${evento.nomeEvento}...');
              fornecedorController.carregarServicosPorEvento(evento.idEvento);
              await orcamentoController
                  .carregarOrcamentosDoEvento(evento.idEvento);
              cotacaoController.ouvirMinhasCotacoes();

              debugPrint(
                  '✅ Evento ${evento.nomeEvento} carregado com sucesso!');
              destino = HomeEventScreen();
            } else {
              contaIncompleta.value = true;
              Lottie.asset(
                'assets/animations/confetti_background.json',
                width: 180,
                height: 180,
                repeat: true,
                fit: BoxFit.contain,
              );
              Get.snackbar(
                "🎉 Falta escolher o tipo de evento!",
                "Seu cadastro foi concluído com sucesso. Agora, selecione o tipo de evento para continuarmos o planejamento.",
                backgroundColor: Colors.orange.shade400,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(12),
                borderRadius: 14,
                icon:
                    const Icon(Icons.celebration_rounded, color: Colors.white),
                duration: const Duration(seconds: 10),
              );

              destino = const WelcomeEventScreen();
            }
            break;
        }

        carregando.value = false;
        Get.offAll(
          () => destino,
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
    // return 'be6133cb-9450-4e87-8282-e7df2d037581';
    final uri = Uri.base;
    if (uri.pathSegments.contains('convite')) {
      final token = uri.pathSegments.last.trim();
      return token.isEmpty ? null : token;
    }
    return null;
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

  /// Abre um convite de forma segura.
  ///
  /// Se o usuário ainda não estiver autenticado, o token fica guardado e o app
  /// segue para o fluxo de login/cadastro como convidado. Depois que a conta é
  /// criada, o token é vinculado ao UID do Firebase Auth.
  Future<void> abrirConvite(String token) async {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return;

    conviteToken.value = tokenLimpo;
    conviteProcessado = false;
    conviteTokenProcessado = '';
    final idUsuario = autenticacaoRepository.idUsuarioAtual;

    if (idUsuario == null) {
      conviteProcessado = false;
      debugPrint(
          '$_logTag Convite guardado aguardando autenticação: $tokenLimpo');
      Get.offAllNamed('/role', arguments: {
        'tipo': 'C',
        'convidado': true,
        'conviteToken': tokenLimpo,
      });
      return;
    }

    final usuario = await obterUsuario(idUsuario);
    if (usuario == null) {
      Get.offAllNamed('/role', arguments: {
        'tipo': 'C',
        'convidado': true,
        'conviteToken': tokenLimpo,
      });
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

    await redirecionarConvidadoAposLogin(usuario, token: tokenLimpo);
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
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 550),
      );
    } catch (e, s) {
      carregando.value = false;
      debugPrint('$_logTag Erro ao redirecionar convidado: $e\n$s');
      Get.offAll(() => const ConviteNaoEncontradoScreen());
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

    await eventoController.buscarTipoEvento(evento.idTipoEvento);
    await themeController.aplicarTemaPorId(evento.idTipoEvento);

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
      _limparEstadoTotp();
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
