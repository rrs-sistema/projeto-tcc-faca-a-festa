import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './../presentation/pages/fornecedor/fornecedor_home_screen.dart';
import './../presentation/pages/admin/admin_dashboard_screen.dart';
import './../presentation/pages/welcome/welcome_event_screen.dart';
import './../presentation/pages/convidado/convidado_page.dart';
import './../presentation/pages/home_event_screen.dart';
import './avaliacao/avaliacao_servico_controller.dart';
import './../data/models/DTO/servico_cotado_dto.dart';
import './convidado/convidado_controller.dart';
import './contacao/cotacao_controller.dart';
import 'servico/servico_produto_controller.dart';
import './../role_selector_screen.dart';
import 'fornecedor/fornecedor_controller.dart';
import './orcamento_controller.dart';
import './../data/models/model.dart';
import './../domain/repositories/convite_convidado_repository.dart';
import './../domain/repositories/autenticacao_repository.dart';
import './../domain/repositories/perfil_usuario_repository.dart';
import './evento_controller.dart';
import './tarefa_controller.dart';
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
  StreamSubscription<SessaoUsuario?>? _sessaoSub;
  bool devMode = true;

  static const String _logTag = '[AppController]';
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
    _monitorarSessao();
  }

  // ------------------------------------------------------------
  // 🔹 Monitora sessão do Firebase Auth e redireciona o usuário
  // ------------------------------------------------------------
  void _monitorarSessao() {
    _sessaoSub = autenticacaoRepository.observarSessao().listen((user) async {
      await Future.delayed(
          const Duration(milliseconds: 300)); // ✅ pequeno delay
      // 🔥 verifica token de convite primeiro
      final token = _tokenConviteAtual();

      if (user == null) {
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

      if (Get.currentRoute.isEmpty || Get.currentRoute != '/splash') {
        Future.microtask(() {
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
    });
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
      Get.offAll(() => const ConvidadosPage());
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
      return const ConvidadosPage();
    }

    final evento =
        await eventoController.buscarEventoPeloIdEvento(convidado.idEvento);
    if (evento == null) {
      debugPrint(
          '$_logTag Convite encontrado, mas evento não existe: ${convidado.idEvento}.');
      return const ConvidadosPage();
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
    await autenticacaoRepository.sair();
    usuarioLogado.value = null;
    eventoController.reset();
    orcamentoController.reset();
    tarefaController.reset();
    Get.offAll(() => const WelcomeEventScreen());
  }

  Future<void> logoutFornecedor() async {
    await _sessaoSub?.cancel();
    await autenticacaoRepository.sair();
    usuarioLogado.value = null;
    eventoController.reset();
    orcamentoController.reset();
    tarefaController.reset();
    fornecedorController.logoutFornecedor();
    Get.offAll(() => const RoleSelectorScreen());
    _monitorarSessao(); // Reativa sessão
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
    return usuarioComEndereco;
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
