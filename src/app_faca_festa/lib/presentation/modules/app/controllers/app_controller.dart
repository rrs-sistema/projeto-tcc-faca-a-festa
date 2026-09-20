import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/servico_cotado.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/repositories/push_token_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_documentos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_carrinho_cotacao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_ciclo_sessao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_convite_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_sessao_fornecedor.dart';
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
    required PushTokenRepository pushTokenRepository,
    required this.documentos,
    required GerenciarFornecedores fornecedores,
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
        sessaoFornecedor = AppSessaoFornecedor(
          fornecedores: fornecedores,
          fornecedorController: fornecedorController,
          theme: themeController,
          orcamentos: orcamentoController,
          avaliacoes: avaliacaoController,
          servicos: servicoController,
          push: pushTokenRepository,
        ),
        _orcamentoGastoController = orcamentoGastoController,
        _orcamentoGastoControllerResolver = orcamentoGastoControllerResolver,
        _fornecedorLocalizacaoController = fornecedorLocalizacaoController,
        _fornecedorLocalizacaoControllerResolver =
            fornecedorLocalizacaoControllerResolver,
        _inspiracaoController = inspiracaoController,
        _inspiracaoControllerResolver = inspiracaoControllerResolver,
        _usuarioController = usuarioController,
        _usuarioControllerResolver = usuarioControllerResolver {
    _cicloSessao = AppCicloSessao(
      autenticacao: autenticacaoRepository,
      perfil: perfilUsuarioRepository,
      convite: convite,
      totp: totp,
      carrinho: carrinho,
      sessaoFornecedor: sessaoFornecedor,
      eventos: eventoController,
      orcamentos: orcamentoController,
      cotacoes: cotacaoController,
      fornecedor: fornecedorController,
      tarefas: tarefaController,
      servicos: servicoController,
      theme: themeController,
      auditoria: auditoria,
      auditoriaResolver: auditoriaResolver,
    );
    convite.vincular(
      obterUsuario: obterUsuario,
      carregando: carregando,
    );
    sessaoFornecedor.vincular(
      usuarioLogado: () => usuarioLogado.value,
      carregando: carregando,
    );
    _cicloSessao.vincular(
      usuarioLogado: usuarioLogado,
      enderecoPrincipal: enderecoPrincipal,
      enderecosUsuario: enderecosUsuario,
      carregando: carregando,
      encerrandoSessao: encerrandoSessao,
      contaIncompleta: contaIncompleta,
      sincronizarUsuarioController: _sincronizarUsuarioController,
      validarDependenciasHomeEvent: _validarDependenciasHomeEvent,
      validarDependenciasAdminDashboard: _validarDependenciasAdminDashboard,
      pararEscutasOpcionais: _pararEscutasOpcionais,
    );
  }

  final Rx<Usuario?> usuarioLogado = Rx<Usuario?>(null);
  final Rx<EnderecoUsuario?> enderecoPrincipal = Rx<EnderecoUsuario?>(null);
  final RxList<EnderecoUsuario> enderecosUsuario = <EnderecoUsuario>[].obs;

  RxList<ServicoCotado> get servicosSelecionados => carrinho.servicos;

  final RxBool contaIncompleta = false.obs;
  final RxBool carregando = false.obs;
  final RxBool encerrandoSessao = false.obs;
  bool devMode = true;

  final AutenticacaoRepository autenticacaoRepository;
  final PerfilUsuarioRepository perfilUsuarioRepository;
  final GerenciarDocumentos documentos;
  final AppConviteController convite;
  final AppTotpSessao totp;
  final AppCarrinhoCotacao carrinho;
  final AppSessaoFornecedor sessaoFornecedor;
  late final AppCicloSessao _cicloSessao;

  final EventoController eventoController;
  final OrcamentoController orcamentoController;
  final CotacaoController cotacaoController;
  final FornecedorController fornecedorController;
  final TarefaController tarefaController;
  final AvaliacaoServicoController avaliacaoController;
  final ServicoProdutoController servicoController;
  final EventThemeController themeController;
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

    convite.capturarTokenInicial();
    _cicloSessao.monitorar();
  }

  Future<Usuario?> prepararUsuarioComEndereco() async {
    try {
      final idUsuario = autenticacaoRepository.idUsuarioAtual;
      if (idUsuario == null) return null;

      carregando.value = true;

      final usuario = await perfilUsuarioRepository.buscarUsuario(idUsuario);
      if (usuario == null) {
        debugPrint('⚠️ Usuário não encontrado no Firestore.');
        carregando.value = false;
        return null;
      }

      final enderecos =
          await perfilUsuarioRepository.listarEnderecos(idUsuario);
      _cicloSessao.aplicarPerfil(
        PerfilUsuario(usuario: usuario, enderecos: enderecos),
      );

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

  void iniciarSessao() => _cicloSessao.iniciar();

  void reterNaSplash({Duration minimo = const Duration(milliseconds: 4500)}) =>
      _cicloSessao.reterNaSplash(minimo: minimo);

  RxString get conviteToken => convite.conviteToken;
  RxBool get acessoPorLink => convite.acessoPorLink;
  bool get fluxoConviteAtivo => convite.fluxoConviteAtivo;

  String? obterTokenConvite() => convite.obterTokenConvite();

  String? tokenConviteAtual() => convite.tokenConviteAtual();

  void guardarTokenConvite(String token) => convite.guardarTokenConvite(token);

  Future<AreaConvidadoArgs?> abrirConvite(String token) =>
      convite.abrirConvite(token);

  Future<void> redirecionarConvidadoAposLogin(
    Usuario usuario, {
    String? token,
  }) =>
      convite.redirecionarConvidadoAposLogin(usuario, token: token);

  Future<void> verificarAprovacaoFornecedorPendente() =>
      sessaoFornecedor.verificarAprovacaoPendente();

  Future<void> logout() async {
    await _cicloSessao.encerrar();
  }

  Future<void> logoutFornecedor() async {
    await _cicloSessao.encerrar(limparFornecedorAntes: true);
  }

  Future<void> salvarUsuario(Usuario usuario) async {
    await perfilUsuarioRepository.salvarUsuario(usuario);
    usuarioLogado.value = usuario;
  }

  Future<Usuario?> obterUsuario(String id) async {
    return perfilUsuarioRepository.buscarUsuario(id);
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

  Future<void> _pararEscutasOpcionais() async {
    await _resolverOrcamentoGastoController()?.encerrarEscutas();
    await _resolverFornecedorLocalizacaoController()?.encerrarEscutas();
    await _resolverInspiracaoController()?.encerrarEscutas();
  }

  Future<void> excluirDocumento(String colecao, String idDocumento) async {
    await documentos.excluirDocumento(
      colecao: colecao,
      idDocumento: idDocumento,
    );
  }

  void adicionarServico(ServicoCotado servico) => carrinho.adicionar(servico);

  void removerServico(String idProduto) => carrinho.remover(idProduto);

  void limparServicosSelecionados() => carrinho.limpar();

  bool isServicoSelecionado(String idProduto) => carrinho.contem(idProduto);

  @override
  void onClose() {
    unawaited(_cicloSessao.cancelarEscuta());
    sessaoFornecedor.encerrar();
    super.onClose();
  }
}
