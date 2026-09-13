// ================================
// 🔹 Controller reativo GetX
// ================================
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/orcamento.dart';
import 'package:app_faca_festa/domain/entities/servico_foto.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/entities/subcategoria_servico.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamentos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servico_fotos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_ai_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_catalogo.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_lista_admin.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_painel_ao_vivo.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/dialogs/show_novo_orcamento_bottom_sheet.dart';

class FornecedorController extends GetxController {
  FornecedorController({
    AutenticacaoRepository? autenticacaoRepository,
    GerenciarFornecedores? gerenciarFornecedores,
    GerenciarServicosProduto? gerenciarServicosProduto,
    GerenciarServicosProduto? Function()? gerenciarServicosProdutoResolver,
    GerenciarServicoFotos? gerenciarServicoFotos,
    GerenciarServicoFotos? Function()? gerenciarServicoFotosResolver,
    required this.ai,
    AuditoriaRegistrar? auditoria,
    AuditoriaRegistrar? Function()? auditoriaResolver,
    AppController? appController,
    AppController? Function()? appControllerResolver,
  })  : _autenticacaoRepository = autenticacaoRepository,
        _gerenciarFornecedores = gerenciarFornecedores,
        _gerenciarServicosProduto = gerenciarServicosProduto,
        _gerenciarServicosProdutoResolver = gerenciarServicosProdutoResolver,
        _gerenciarServicoFotos = gerenciarServicoFotos,
        _gerenciarServicoFotosResolver = gerenciarServicoFotosResolver,
        _appController = appController,
        _appControllerResolver = appControllerResolver,
        _auditoria = auditoria,
        _auditoriaResolver = auditoriaResolver {
    listaAdmin = FornecedorListaAdmin(
      fornecedores: fornecedores,
      enderecos: enderecos,
      categoriasFornecedor: categoriasFornecedor,
      categorias: categorias,
      subCategorias: subCategorias,
      categoriasServico: categoriasServico,
      subcategoriasServico: subcategoriasServico,
      allServicosFornecedor: allServicosFornecedor,
      filtroNome: filtroNome,
      filtroCidade: filtroCidade,
      filtroCategoria: filtroCategoria,
      filtroAprovado: filtroAprovado,
      filtroAtivo: filtroAtivo,
      ordenacaoSelecionada: ordenacaoSelecionada,
      usecase: () => _fornecedores,
      auditoria: () => _registradorAuditoria,
      tipoUsuario: () => _resolverAppController()?.usuarioLogado.value?.tipo,
      carregando: carregando,
      erro: erro,
    );
    catalogo = FornecedorCatalogo(
      servicosFornecedor: servicosFornecedor,
      servicosDetalhado: servicosDetalhado,
      catalogoServicos: catalogoServicos,
      fotosServico: fotosServico,
      isLoadingFotos: isLoadingFotos,
      carregando: carregando,
      erro: erro,
      fornecedores: () => _fornecedores,
      servicosProduto: () => _servicosProduto,
      fotos: () => _servicoFotos,
      recarregarAi: ai.carregarAiFornecedorComDadosAtuais,
    );
    painel = FornecedorPainelAoVivo(
      fornecedor: fornecedor,
      aptoParaOperar: aptoParaOperar,
      solicitacoesPendentes: solicitacoesPendentes,
      mensagensNaoLidas: mensagensNaoLidas,
      avaliacaoMedia: avaliacaoMedia,
      servicosFornecedor: servicosFornecedor,
      erro: erro,
      usecase: () => _fornecedores,
      usuarioEhFornecedor: _usuarioLogadoEhFornecedor,
      aoAtualizar: (atualizado) {
        if (atualizado.aptoParaOperar) {
          ai.carregarAiFornecedorComDadosAtuais();
        } else {
          ai.limparAiFornecedor();
        }
      },
      aoLimpar: ai.limparAiFornecedor,
    );
    ai.vincular(
      fornecedorAtual: () => fornecedor.value,
      servicosDetalhados: () => servicosDetalhado.toList(),
      solicitacoesPendentes: buscarSolicitacoesPendentesDetalhadas,
    );
  }

  final AutenticacaoRepository? _autenticacaoRepository;
  final GerenciarFornecedores? _gerenciarFornecedores;
  final GerenciarServicosProduto? _gerenciarServicosProduto;
  final GerenciarServicosProduto? Function()? _gerenciarServicosProdutoResolver;
  final GerenciarServicoFotos? _gerenciarServicoFotos;
  final GerenciarServicoFotos? Function()? _gerenciarServicoFotosResolver;
  final FornecedorAiController ai;
  late final FornecedorListaAdmin listaAdmin;
  late final FornecedorCatalogo catalogo;
  late final FornecedorPainelAoVivo painel;
  final AppController? _appController;
  final AppController? Function()? _appControllerResolver;
  final AuditoriaRegistrar? _auditoria;
  final AuditoriaRegistrar? Function()? _auditoriaResolver;
  AuditoriaRegistrar get _registradorAuditoria =>
      _auditoria ??
      _auditoriaResolver?.call() ??
      const AuditoriaRegistrarVazio();

  final Rx<Fornecedor?> fornecedor = Rx<Fornecedor?>(null);
  final RxList<Fornecedor> fornecedores = <Fornecedor>[].obs;

  final RxList<FornecedorProdutoServico> servicosFornecedor =
      <FornecedorProdutoServico>[].obs;

  final RxList<FornecedorServicoDetalhado> servicosDetalhado =
      <FornecedorServicoDetalhado>[].obs;

  final RxList<FornecedorProdutoServico> allServicosFornecedor =
      <FornecedorProdutoServico>[].obs;

  final RxList<ServicoProduto> catalogoServicos = <ServicoProduto>[].obs;

  final RxList<ServicoFoto> fotosServico = <ServicoFoto>[].obs;

  final RxList<CategoriaServico> categorias = <CategoriaServico>[].obs;

  final RxList<SubcategoriaServico> subCategorias = <SubcategoriaServico>[].obs;

  final categoriasServico = <Map<String, dynamic>>[].obs;
  final subcategoriasServico = <Map<String, dynamic>>[].obs;

  final isLoadingServicos = false.obs;
  final isLoadingFotos = false.obs;

  final ordenacaoSelecionada = 'status'.obs;
  final RxInt solicitacoesPendentes = 0.obs;
  final RxInt mensagensNaoLidas = 0.obs;
  final RxDouble avaliacaoMedia = 0.0.obs;
  final RxDouble faturamentoMes = 0.0.obs;

  final RxInt totalFotos = 0.obs;
  final RxDouble tempoMedioResposta = 0.0.obs;

  final RxBool aptoParaOperar = false.obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  int get totalAptos => listaAdmin.totalAptos;
  int get totalPendentes => listaAdmin.totalPendentes;
  int get totalInativos => listaAdmin.totalInativos;
  final filtroNome = ''.obs;
  final filtroCidade = RxnString();
  final filtroCategoria = RxnString();
  final filtroAprovado = RxnBool();
  final filtroAtivo = RxnBool();

  final filtroAvaliacaoMinima = 0.0.obs;
  final enderecos = <EnderecoUsuario>[].obs;
  final categoriasFornecedor = <FornecedorCategoria>[].obs;

  Future<void> logoutFornecedor() async {
    fornecedores.clear();
    servicosFornecedor.clear();
    servicosDetalhado.clear();
    allServicosFornecedor.clear();
    catalogoServicos.clear();
    fotosServico.clear();
    categorias.clear();
    subCategorias.clear();
    categoriasServico.clear();
    subcategoriasServico.clear();
    await catalogo.cancelarEscuta();
    await painel.cancelarEscutas();
    ai.limparAiFornecedor();
    fornecedor.value = null;
    aptoParaOperar.value = false;
  }

  @override
  void onInit() {
    super.onInit();

    Future.delayed(Duration.zero, () {
      final appController = _resolverAppController();
      if (appController == null) return;
      ever(appController.usuarioLogado, (usuario) async {
        if (usuario == null) return;
        await carregarTodosFornecedores();
      });
    });
  }

  Future<void> ouvirMensagensNaoLidas(String idFornecedor) =>
      painel.ouvirMensagensNaoLidas(idFornecedor);

  void iniciarListenerFornecedor(String idFornecedor) =>
      painel.iniciarListenerFornecedor(idFornecedor);

  Future<void> pararListenerFornecedor() => painel.pararListenerFornecedor();

  Future<List<ServicoProduto>> buscarServicosFornecedorPorCategorias(
    String idFornecedor,
  ) =>
      catalogo.listarAtivosPorCategorias(idFornecedor);

  Future<void> atualizarFornecedor(Fornecedor fornecedor) async {
    try {
      await _fornecedores.atualizarFornecedor(fornecedor);
      _registradorAuditoria.registrar(
        acao: 'FORNECEDOR_EDITADO',
        resumo: 'Perfil do fornecedor atualizado.',
        entidadeTipo: 'fornecedor',
        entidadeId: fornecedor.idFornecedor,
        entidadeNome: fornecedor.razaoSocial,
        idFornecedor: fornecedor.idFornecedor,
      );
    } catch (e) {
      throw Exception("Erro ao atualizar fornecedor: $e");
    }
  }

  Future<String> uploadBanner({
    required List<int> bytes,
    required String nomeArquivo,
    String? uid,
  }) async {
    final userId = uid ?? _idUsuarioAtual;
    if (userId == null || userId.isEmpty) {
      throw Exception(
        'É preciso estar autenticado para enviar o banner.',
      );
    }

    try {
      return await _fornecedores.uploadBanner(
        bytes: bytes,
        nomeArquivo: nomeArquivo,
        uid: userId,
      );
    } catch (e) {
      throw Exception("Erro ao enviar banner: $e");
    }
  }

  String? get _idUsuarioAtual {
    return _autenticacaoRepository?.idUsuarioAtual;
  }

  GerenciarFornecedores get _fornecedores {
    final service = _gerenciarFornecedores;
    if (service == null) {
      throw StateError('GerenciarFornecedores não configurado.');
    }
    return service;
  }

  GerenciarServicosProduto get _servicosProduto {
    final service = _gerenciarServicosProduto;
    if (service != null) return service;
    final resolved = _gerenciarServicosProdutoResolver?.call();
    if (resolved != null) return resolved;
    throw StateError('GerenciarServicosProduto não configurado.');
  }

  GerenciarServicoFotos get _servicoFotos {
    final service = _gerenciarServicoFotos;
    if (service != null) return service;
    final resolved = _gerenciarServicoFotosResolver?.call();
    if (resolved != null) return resolved;
    throw StateError('GerenciarServicoFotos não configurado.');
  }

  AppController? _resolverAppController() {
    if (_appController != null) return _appController;
    return _appControllerResolver?.call();
  }

  Future<void> carregarTodosFornecedores() => listaAdmin.carregarTodos();

  Future<Fornecedor?> buscarFornecedor(String idUsuario) async {
    try {
      final fornecedor = await _fornecedores.buscarPorIdUsuario(idUsuario);
      return fornecedor;
    } catch (e) {
      debugPrint("❌ Erro ao buscar último evento: $e");
      return null;
    }
  }

  bool _usuarioLogadoEhFornecedor() {
    try {
      return _resolverAppController()?.usuarioLogado.value?.tipo == 'F';
    } catch (_) {
      return false;
    }
  }

  Future<void> escutarSolicitacoesPendentes(String? idFornecedor) =>
      painel.escutarSolicitacoesPendentes(idFornecedor);

  List<Fornecedor> get fornecedoresFiltrados => listaAdmin.filtrados;

  String cidadeDoFornecedor(Fornecedor f) => listaAdmin.cidadeDoFornecedor(f);

  List<String> nomesCategoriasDoFornecedor(Fornecedor f) =>
      listaAdmin.nomesCategoriasDoFornecedor(f);

  int servicosDoFornecedor(Fornecedor f) => listaAdmin.servicosDoFornecedor(f);

  void ordenarFornecedores() => listaAdmin.ordenar();

  Future<bool> aprovarFornecedor(String idFornecedor) =>
      listaAdmin.aprovar(idFornecedor);

  Future<void> desativarFornecedor(String idFornecedor) =>
      listaAdmin.desativar(idFornecedor);

  Future<bool> reprovarFornecedor(String idFornecedor) =>
      listaAdmin.reprovar(idFornecedor);

  Future<void> ativarFornecedor(String idFornecedor) =>
      listaAdmin.ativar(idFornecedor);

  Future<void> carregarServicosPorEvento(String idEvento) =>
      catalogo.carregarPorEvento(idEvento);

  Future<void> escutarServicosFornecedor(String idFornecedor) =>
      catalogo.escutar(idFornecedor);

  Future<void> listarServicosFornecedor(String idFornecedor) =>
      catalogo.listarComDetalhes(idFornecedor);

  Future<void> carregarCatalogoServicos() => catalogo.carregarCatalogo();

  Future<void> carregarFotosServicos(
    List<String> idsProdutoServico,
    String idFornecedor,
  ) =>
      catalogo.carregarFotos(idsProdutoServico, idFornecedor);

  ServicoProduto? buscarServicoPorId(String idProdutoServico) =>
      catalogo.buscarPorId(idProdutoServico);

  Future<void> abrirCotacao({
    required BuildContext context,
    required String idEvento,
    required FornecedorProdutoServico servicoFornecedor,
    required GerenciarOrcamentos orcamentos,
    required EventThemeController themeController,
    String acao = 'solicitar',
    String? idOrcamento,
  }) async {
    final servicoProduto =
        buscarServicoPorId(servicoFornecedor.idProdutoServico);
    if (servicoProduto == null) {
      Get.snackbar(
        "Serviço não encontrado",
        "Não foi possível carregar o serviço solicitado.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final statusInicial = acao == 'reservar'
        ? StatusOrcamento.emNegociacao
        : acao == 'solicitar'
            ? StatusOrcamento.fechado
            : StatusOrcamento.pendente;

    await showNovoOrcamentoBottomSheet(
      context: context,
      idEvento: idEvento,
      idFornecedor: servicoFornecedor.idFornecedor,
      servico: servicoFornecedor,
      statusInicial: statusInicial,
      orcamentos: orcamentos,
      fornecedorController: this,
      themeController: themeController,
      idSolicitante: _resolverAppController()?.usuarioLogado.value?.idUsuario,
      idOrcamento: idOrcamento,
    );
  }

  Future<void> carregarFornecedoresDoEvento(String idEvento) async {
    try {
      carregando.value = true;
      erro.value = '';

      fornecedores.assignAll(
        await _fornecedores.listarFornecedoresDoEvento(idEvento),
      );
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> limparDuplicatasFornecedorCategoria() async {
    print('🧹 Iniciando limpeza da coleção fornecedor_categoria...');
    final duplicatasRemovidas =
        await _fornecedores.limparDuplicatasFornecedorCategoria();
    print('🧹 Limpeza concluída! Duplicatas removidas: $duplicatasRemovidas');
  }

  Future<void> atualizarEstatisticasFornecedor() =>
      painel.atualizarEstatisticas();

  Future<List<Cotacao>> buscarSolicitacoesPendentesDetalhadas() =>
      painel.listarSolicitacoesPendentesDetalhadas();

  void aplicarFiltros({
    String? nome,
    String? cidade,
    String? categoria,
    bool? aprovado,
    bool? ativo,
  }) {
    listaAdmin.aplicarFiltros(
      nome: nome,
      cidade: cidade,
      categoria: categoria,
      aprovado: aprovado,
      ativo: ativo,
    );
  }

  void limparFiltros() {
    listaAdmin.limparFiltros();
    update();
  }

  @override
  void onClose() {
    catalogo.cancelarEscuta();
    painel.cancelarEscutas();
    ai.limparAiFornecedor();
    painel.pararListenerFornecedor();
    super.onClose();
  }
}
