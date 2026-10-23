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
import 'package:app_faca_festa/domain/entities/fornecedor_dados_cadastrais.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_cadastro_edicao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
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
          ai.carregarAiDasSolicitacoesPendentes();
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

  bool get podeEditarDadosFornecedor {
    final usuario = _resolverAppController()?.usuarioLogado.value;
    return usuario?.tipo == 'A' && usuario?.ativo == true;
  }

  final _edicoesCadastrais = <String>{};

  Future<FornecedorCadastroEdicao> carregarCadastroFornecedorAdmin(
      String id) async {
    if (!podeEditarDadosFornecedor) {
      throw StateError('Acesso permitido somente a administradores ativos.');
    }
    final admin = _resolverAppController()?.usuarioLogado.value?.idUsuario;
    final cadastro = await _fornecedores.carregarCadastroEdicao(id);
    if (!podeEditarDadosFornecedor ||
        _resolverAppController()?.usuarioLogado.value?.idUsuario != admin) {
      throw StateError('A sessão mudou. Entre novamente na gestão.');
    }
    return cadastro;
  }

  Future<void> salvarCadastroFornecedorAdmin(
      FornecedorCadastroAlteracao alteracao) async {
    if (!podeEditarDadosFornecedor) {
      throw StateError('Acesso permitido somente a administradores ativos.');
    }
    final dados = alteracao.dados;
    final endereco = alteracao.endereco;
    final erros = [
      FormValidators.nomeCompleto(alteracao.nomeResponsavel),
      FormValidators.razaoSocial(dados.razaoSocial),
      FormValidators.email(dados.email),
      FormValidators.telefone(dados.telefone),
      FormValidators.cnpj(dados.cnpj),
      FormValidators.descricaoServicos(dados.descricao),
      FormValidators.cep(endereco.cep),
      FormValidators.logradouro(endereco.logradouro),
      FormValidators.numeroEndereco(endereco.numero),
      FormValidators.bairro(endereco.bairro),
      FormValidators.cidade(endereco.nomeCidade),
      FormValidators.uf(endereco.uf),
      FormValidators.selecao(alteracao.categorias, campo: 'uma categoria'),
      FormValidators.selecao(alteracao.servicos, campo: 'um serviço'),
      FormValidators.selecao(alteracao.tipoEventoIds,
          campo: 'um tipo de evento')
    ];
    final erro = erros.whereType<String>().firstOrNull;
    if (erro != null) throw StateError(erro);
    final id = alteracao.origem.fornecedor.idFornecedor;
    if (!_edicoesCadastrais.add(id)) {
      throw StateError('Já existe um salvamento em andamento.');
    }
    final admin = _resolverAppController()?.usuarioLogado.value?.idUsuario;
    try {
      await _fornecedores.salvarCadastroEdicao(alteracao);
      if (!podeEditarDadosFornecedor ||
          _resolverAppController()?.usuarioLogado.value?.idUsuario != admin) {
        return;
      }
      Fornecedor aplicar(Fornecedor atual) => dados.aplicarEm(atual).copyWith(
          tipoEventoIds: alteracao.tipoEventoIds,
          tipoEventoSlugs: alteracao.tipoEventoSlugs,
          tipoEventoNomes: alteracao.tipoEventoNomes,
          bannerUrl: alteracao.novoBannerUrl ?? atual.bannerUrl,
          categorias: alteracao.categorias
              .map((cat) => FornecedorCategoriaResumo(
                  idCategoria: cat.idCategoria,
                  nomeCategoria: cat.nomeCategoria ?? '',
                  subcategorias: cat.subcategorias))
              .toList());
      final index = fornecedores.indexWhere((f) => f.idFornecedor == id);
      if (index >= 0) {
        fornecedores[index] = aplicar(fornecedores[index]);
        listaAdmin.ordenar();
      }
      if (fornecedor.value?.idFornecedor == id) {
        fornecedor.value = aplicar(fornecedor.value!);
      }
      enderecos.removeWhere(
          (e) => e.idUsuario == endereco.idUsuario && e.id == endereco.id);
      enderecos.add(endereco);
      categoriasFornecedor.removeWhere((c) => c.idFornecedor == id);
      categoriasFornecedor.addAll(
          alteracao.categorias.map((c) => c.copyWith(idFornecedor: id)));
      final selecionados = alteracao.servicos.map((s) => s.id).toSet();
      for (var i = 0; i < allServicosFornecedor.length; i++) {
        final v = allServicosFornecedor[i];
        if (v.idFornecedor == id) {
          allServicosFornecedor[i] =
              v.copyWith(ativo: selecionados.contains(v.idProdutoServico));
        }
      }
      for (final servico in alteracao.servicos) {
        if (allServicosFornecedor.any(
            (s) => s.idFornecedor == id && s.idProdutoServico == servico.id)) {
          continue;
        }
        allServicosFornecedor.add(FornecedorProdutoServico(
            id: '${id}_${servico.id}',
            idFornecedor: id,
            idProdutoServico: servico.id,
            preco: 0,
            idSubcategoria: servico.idSubcategoria));
      }
      _registradorAuditoria.registrar(
          acao: 'FORNECEDOR_EDITADO',
          resumo: 'Cadastro do fornecedor atualizado pelo fluxo de criação.',
          entidadeTipo: 'fornecedor',
          entidadeId: id,
          entidadeNome: dados.razaoSocial,
          idFornecedor: id);
    } finally {
      _edicoesCadastrais.remove(id);
    }
  }

  Future<void> editarDadosFornecedorAdmin({
    required String idFornecedor,
    required FornecedorDadosCadastrais dados,
  }) async {
    if (!podeEditarDadosFornecedor) {
      throw StateError(
          'Somente administradores ativos podem editar estes dados.');
    }
    if (idFornecedor.trim().isEmpty) {
      throw ArgumentError('Fornecedor não identificado.');
    }
    final validacoes = [
      FormValidators.razaoSocial(dados.razaoSocial),
      FormValidators.email(dados.email, obrigatorio: false),
      FormValidators.telefone(dados.telefone,
          obrigatorio: dados.telefone.isNotEmpty),
      FormValidators.cnpj(dados.cnpj, obrigatorio: dados.cnpj.isNotEmpty),
      FormValidators.descricao(dados.descricao, minimo: 0, maximo: 2000),
    ];
    final invalido = validacoes.whereType<String>().firstOrNull;
    if (invalido != null) throw ArgumentError(invalido);
    if (!_edicoesCadastrais.add(idFornecedor)) {
      throw StateError(
          'Já existe um salvamento em andamento para este fornecedor.');
    }
    final idAdmin = _resolverAppController()?.usuarioLogado.value?.idUsuario;
    try {
      await _fornecedores.atualizarDadosCadastrais(
          idFornecedor: idFornecedor, dados: dados);
      // Não injeta dados de uma sessão anterior após sair ou trocar de conta.
      if (!podeEditarDadosFornecedor ||
          _resolverAppController()?.usuarioLogado.value?.idUsuario != idAdmin) {
        return;
      }
      final index =
          fornecedores.indexWhere((f) => f.idFornecedor == idFornecedor);
      if (index >= 0) {
        fornecedores[index] = dados.aplicarEm(fornecedores[index]);
        listaAdmin.ordenar();
      }
      final atual = fornecedor.value;
      if (atual?.idFornecedor == idFornecedor) {
        fornecedor.value = dados.aplicarEm(atual!);
      }
      _registradorAuditoria.registrar(
        acao: 'FORNECEDOR_EDITADO',
        resumo:
            'Dados cadastrais do fornecedor atualizados pelo administrador.',
        entidadeTipo: 'fornecedor',
        entidadeId: idFornecedor,
        entidadeNome: dados.razaoSocial,
        idFornecedor: idFornecedor,
      );
    } finally {
      _edicoesCadastrais.remove(idFornecedor);
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

  Future<void> listarServicosFornecedor(
    String idFornecedor, {
    bool atualizarIa = true,
  }) =>
      catalogo.listarComDetalhes(
        idFornecedor,
        atualizarIa: atualizarIa,
      );

  /// Busca estatísticas, catálogo e pedidos antes de recalcular a IA.
  /// Na primeira abertura a análise rodava com essas listas ainda vazias.
  Future<void> atualizarPainelOperacional() async {
    final atual = fornecedor.value;
    if (atual == null || !atual.aptoParaOperar) return;

    await atualizarEstatisticasFornecedor();
    await escutarSolicitacoesPendentes(atual.idFornecedor);
    await listarServicosFornecedor(atual.idFornecedor, atualizarIa: false);
    await ai.carregarAiDasSolicitacoesPendentes(forceRefresh: true);
  }

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
