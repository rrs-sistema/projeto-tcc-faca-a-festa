// ================================
// 🔹 Controller reativo GetX
// ================================
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
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
  final AppController? _appController;
  final AppController? Function()? _appControllerResolver;
  final AuditoriaRegistrar? _auditoria;
  final AuditoriaRegistrar? Function()? _auditoriaResolver;
  AuditoriaRegistrar get _registradorAuditoria =>
      _auditoria ??
      _auditoriaResolver?.call() ??
      const AuditoriaRegistrarVazio();

  /// 🔹 Dados principais do fornecedor logado
  final Rx<Fornecedor?> fornecedor = Rx<Fornecedor?>(null);
  final RxList<Fornecedor> fornecedores = <Fornecedor>[].obs;

  /// 🔹 Serviços (coleção `fornecedor_servico`)
  final RxList<FornecedorProdutoServico> servicosFornecedor =
      <FornecedorProdutoServico>[].obs;

  final RxList<FornecedorServicoDetalhado> servicosDetalhado =
      <FornecedorServicoDetalhado>[].obs;

  final RxList<FornecedorProdutoServico> allServicosFornecedor =
      <FornecedorProdutoServico>[].obs;

  /// 🔹 Catálogo global (`servico_produto`)
  final RxList<ServicoProduto> catalogoServicos = <ServicoProduto>[].obs;

  /// 🔹 Fotos dos serviços (`servico_foto`)
  final RxList<ServicoFoto> fotosServico = <ServicoFoto>[].obs;

  final RxList<CategoriaServico> categorias = <CategoriaServico>[].obs;

  final RxList<SubcategoriaServico> subCategorias = <SubcategoriaServico>[].obs;

  final categoriasServico = <Map<String, dynamic>>[].obs;
  final subcategoriasServico = <Map<String, dynamic>>[].obs;
  StreamSubscription<Fornecedor?>? _fornecedorSubscription;

  //tempoMedioResposta

  final isLoadingServicos = false.obs;
  final isLoadingFotos = false.obs;

  StreamSubscription? _solicitacoesSub;
  StreamSubscription<int>? _fornecedorCotacoesSub;
  StreamSubscription<List<FornecedorProdutoServico>>? _servicosFornecedorSub;
  String? _servicosEscutandoId;
  final Map<String, int> _mensagensNaoLidasPorCotacao = {};

  /// 🔹 Estatísticas do painel
  final ordenacaoSelecionada = 'status'.obs; // status | nome | recentes
  final RxInt solicitacoesPendentes = 0.obs;
  final RxInt mensagensNaoLidas = 0.obs;
  final RxDouble avaliacaoMedia = 0.0.obs;
  final RxDouble faturamentoMes = 0.0.obs;

  final RxInt totalFotos = 0.obs;
  final RxDouble tempoMedioResposta = 0.0.obs;

  /// 🔹 Estado geral
  final RxBool aptoParaOperar = false.obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  int get totalAptos =>
      fornecedores.where((f) => f.ativo && f.aptoParaOperar).length;
  int get totalPendentes =>
      fornecedores.where((f) => f.ativo && !f.aptoParaOperar).length;
  int get totalInativos => fornecedores.where((f) => !f.ativo).length;
  final filtroNome = ''.obs;
  final filtroCidade = RxnString();
  final filtroCategoria = RxnString();
  final filtroAprovado = RxnBool();
  final filtroAtivo = RxnBool();

  final filtroAvaliacaoMinima = 0.0.obs;
  // 🔹 Dados auxiliares carregados de outras coleções
  final enderecos = <EnderecoUsuario>[].obs;
  final categoriasFornecedor = <FornecedorCategoria>[].obs;
  final List<StreamSubscription> _mensagemListeners = [];

  Future<void> logoutFornecedor() async {
    fornecedores.clear();
    servicosFornecedor.clear();
    servicosFornecedor.clear();
    servicosDetalhado.clear();
    allServicosFornecedor.clear();
    catalogoServicos.clear();
    fotosServico.clear();
    categorias.clear();
    subCategorias.clear();
    categoriasServico.clear();
    subcategoriasServico.clear();
    await _fornecedorSubscription?.cancel();
    _fornecedorSubscription = null;
    await _solicitacoesSub?.cancel();
    await _fornecedorCotacoesSub?.cancel();
    await _servicosFornecedorSub?.cancel();
    for (final listener in _mensagemListeners) {
      await listener.cancel();
    }
    _mensagemListeners.clear();
    _mensagensNaoLidasPorCotacao.clear();
    mensagensNaoLidas.value = 0;
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

  Future<void> ouvirMensagensNaoLidas(String idFornecedor) async {
    if (idFornecedor.trim().isEmpty) return;
    if (!_usuarioLogadoEhFornecedor()) return;

    debugPrint(
        '\n📡 [MSG] Iniciando listener de mensagens NÃO lidas para $idFornecedor');

    await _fornecedorCotacoesSub?.cancel();
    for (final listener in _mensagemListeners) {
      await listener.cancel();
    }
    _mensagemListeners.clear();
    _mensagensNaoLidasPorCotacao.clear();
    mensagensNaoLidas.value = 0;

    _fornecedorCotacoesSub =
        _fornecedores.observarMensagensNaoLidas(idFornecedor).listen((total) {
      mensagensNaoLidas.value = total;
    }, onError: (e) {
      debugPrint('❌ Erro ao escutar cotações do fornecedor para mensagens: $e');
    });
  }

  /// 🟢 Inicia o listener do fornecedor logado
  void iniciarListenerFornecedor(String idFornecedor) {
    print('📡 Iniciando listener para fornecedor $idFornecedor...');

    // Cancela qualquer listener anterior
    _fornecedorSubscription?.cancel();

    _fornecedorSubscription = _fornecedores
        .observarFornecedorAtivo(idFornecedor)
        .listen((atualizado) {
      if (atualizado != null) {
        fornecedor.value = atualizado;
        aptoParaOperar.value = atualizado.aptoParaOperar;
        print('✅ Fornecedor atualizado: ${atualizado.razaoSocial}');
        if (atualizado.aptoParaOperar) {
          ai.carregarAiFornecedorComDadosAtuais();
        } else {
          ai.limparAiFornecedor();
        }
      } else {
        print('⚠️ Nenhum fornecedor ativo encontrado.');
        fornecedor.value = null;
      }
    }, onError: (e) {
      print('❌ Erro ao escutar fornecedor: $e');
    });
  }

  /// 🛑 Cancela o listener (ex: ao sair da conta)
  Future<void> pararListenerFornecedor() async {
    print('🛑 Parando listener de fornecedor...');
    await _fornecedorSubscription?.cancel();
    _fornecedorSubscription = null;
    fornecedor.value = null;
    ai.limparAiFornecedor();
  }

  Future<List<ServicoProduto>> buscarServicosFornecedorPorCategorias(
      String idFornecedor) async {
    try {
      final entidades = await _servicosProduto
          .listarServicosAtivosPorCategoriasFornecedor(idFornecedor);
      return entidades;
    } catch (e, s) {
      debugPrint('Erro ao buscar serviços do fornecedor: $e\n$s');
      return [];
    }
  }

  /// 🔹 Atualiza os dados de um fornecedor existente no Firestore
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

  /// 🔹 Faz upload de imagem para o Firebase Storage e retorna a URL pública.
  /// Exige usuário autenticado (regras de `banners_fornecedores`).
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

  Future<void> carregarTodosFornecedores() async {
    try {
      carregando.value = true;
      erro.value = '';

      final tipo = _resolverAppController()?.usuarioLogado.value?.tipo;
      final snapshot = await _fornecedores.carregarSnapshotAdmin(
        incluirEnderecos: tipo == 'A',
      );

      fornecedores.value = snapshot.fornecedores;
      enderecos.value = snapshot.enderecos;
      categoriasFornecedor.value = snapshot.categoriasFornecedor;
      categoriasServico.value = snapshot.categoriasServico;
      categorias.value = snapshot.categorias;
      subcategoriasServico.value = snapshot.subcategoriasServico;
      subCategorias.value = snapshot.subcategorias;
      allServicosFornecedor.assignAll(snapshot.servicosFornecedor);
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

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

  /// 🔹 Escuta em tempo real todas as solicitações com status = 'aguardando'
  Future<void> escutarSolicitacoesPendentes(String? idFornecedor) async {
    if (idFornecedor == null) return;
    if (!_usuarioLogadoEhFornecedor()) return;

    // Cancela a escuta anterior, se já existir
    await _solicitacoesSub?.cancel();

    try {
      erro.value = '';

      _solicitacoesSub = _fornecedores
          .observarSolicitacoesPendentes(idFornecedor)
          .listen((total) {
        solicitacoesPendentes.value = total;
      }, onError: (e) {
        debugPrint('❌ Erro ao escutar solicitações pendentes: $e');
      });
    } catch (e, s) {
      debugPrint('❌ Erro ao escutar solicitações pendentes: $e\n$s');
      erro.value = 'Erro ao escutar solicitações pendentes';
    }
  }

  // =============================================================
  // 🔸 LISTA FILTRADA
  // =============================================================
  List<Fornecedor> get fornecedoresFiltrados {
    final resultado = fornecedores.where((f) {
      // 🔹 Busca endereço e categoria vinculados
      final endereco =
          enderecos.firstWhereOrNull((e) => e.idUsuario == f.idUsuario);
      final cat = categoriasFornecedor
          .firstWhereOrNull((c) => c.idFornecedor == f.idFornecedor)
          ?.idCategoria;

      // 🔹 Avalia filtros
      final matchNome = filtroNome.value.isEmpty ||
          f.razaoSocial
              .toLowerCase()
              .contains(filtroNome.value.toLowerCase()) ||
          (f.descricao
                  ?.toLowerCase()
                  .contains(filtroNome.value.toLowerCase()) ??
              false) ||
          f.email.toLowerCase().contains(filtroNome.value.toLowerCase());

      final matchCidade = filtroCidade.value == null ||
          (endereco?.nomeCidade
                  ?.toLowerCase()
                  .contains(filtroCidade.value!.toLowerCase()) ??
              false);

      final matchCategoria =
          filtroCategoria.value == null || cat == filtroCategoria.value;

      final matchStatusAprovacao = filtroAprovado.value == null ||
          f.aptoParaOperar == filtroAprovado.value;

      final matchStatusAtivo =
          filtroAtivo.value == null || f.ativo == filtroAtivo.value;

      final passou = matchNome &&
          matchCidade &&
          matchCategoria &&
          matchStatusAprovacao &&
          matchStatusAtivo;

      return passou;
    }).toList();
    return resultado;
  }

  String cidadeDoFornecedor(Fornecedor f) {
    return enderecos
            .firstWhereOrNull((e) => e.idUsuario == f.idUsuario)
            ?.nomeCidade ??
        '';
  }

  List<String> nomesCategoriasDoFornecedor(Fornecedor f) {
    return categoriasFornecedor
        .where((c) => c.idFornecedor == f.idFornecedor)
        .map((c) => (c.nomeCategoria ?? '').trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
  }

  int servicosDoFornecedor(Fornecedor f) {
    return allServicosFornecedor
        .where((s) => s.idFornecedor == f.idFornecedor)
        .length;
  }

  void ordenarFornecedores() {
    final lista = [...fornecedores];
    switch (ordenacaoSelecionada.value) {
      case 'nome':
        lista.sort((a, b) =>
            a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase()));
        break;
      case 'recentes':
        lista.sort((a, b) => (b.dataCadastro).compareTo(a.dataCadastro));
        break;
      default:
        lista.sort((a, b) {
          if (a.ativo != b.ativo) return b.ativo ? 1 : -1;
          if (a.aptoParaOperar != b.aptoParaOperar) {
            return b.aptoParaOperar ? 1 : -1;
          }
          return a.razaoSocial
              .toLowerCase()
              .compareTo(b.razaoSocial.toLowerCase());
        });
    }
    fornecedores.assignAll(lista);
  }

  // =============================================================
  // 🔸 Aprovação e desativação
  // =============================================================
  Future<bool> aprovarFornecedor(String idFornecedor) {
    return _definirAptoParaOperar(idFornecedor, true);
  }

  Future<void> desativarFornecedor(String idFornecedor) async {
    try {
      final atual = fornecedores.firstWhereOrNull(
        (f) => f.idFornecedor == idFornecedor,
      );
      await _fornecedores.atualizarStatusAtivo(
        idFornecedor: idFornecedor,
        ativo: false,
      );
      fornecedores.removeWhere((f) => f.idFornecedor == idFornecedor);
      _registradorAuditoria.registrar(
        acao: 'FORNECEDOR_DESATIVADO',
        resumo: 'Fornecedor desativado pelo administrador.',
        entidadeTipo: 'fornecedor',
        entidadeId: idFornecedor,
        entidadeNome: atual?.razaoSocial,
        idFornecedor: idFornecedor,
        mudancas: const [
          AuditoriaMudanca(campo: 'Ativo', de: 'sim', para: 'não'),
        ],
      );
    } catch (e) {
      debugPrint('❌ Erro ao desativar fornecedor $idFornecedor: $e');
    }
  }

  Future<bool> reprovarFornecedor(String idFornecedor) {
    return _definirAptoParaOperar(idFornecedor, false);
  }

  Future<bool> _definirAptoParaOperar(String idFornecedor, bool apto) async {
    try {
      final id = idFornecedor.trim();
      if (id.isEmpty) {
        debugPrint('❌ idFornecedor vazio ao atualizar apto_para_operar');
        return false;
      }

      await _fornecedores.atualizarAptoParaOperar(
        idFornecedor: id,
        apto: apto,
      );

      final i = fornecedores.indexWhere(
        (x) => x.idFornecedor == id || x.idUsuario == id,
      );
      final nome = i >= 0 ? fornecedores[i].razaoSocial : null;
      if (i >= 0) {
        fornecedores[i] = fornecedores[i].copyWith(aptoParaOperar: apto);
      }
      fornecedores.refresh();
      _registradorAuditoria.registrar(
        acao: apto ? 'FORNECEDOR_APROVADO' : 'FORNECEDOR_REPROVADO',
        resumo: apto
            ? 'Fornecedor liberado para operar na plataforma.'
            : 'Fornecedor voltou para análise.',
        entidadeTipo: 'fornecedor',
        entidadeId: id,
        entidadeNome: nome,
        idFornecedor: id,
        mudancas: [
          AuditoriaMudanca(
            campo: 'Apto para operar',
            de: apto ? 'não' : 'sim',
            para: apto ? 'sim' : 'não',
          ),
        ],
      );
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar apto_para_operar de $idFornecedor: $e');
      return false;
    }
  }

  Future<void> ativarFornecedor(String idFornecedor) async {
    try {
      await _fornecedores.atualizarStatusAtivo(
        idFornecedor: idFornecedor,
        ativo: true,
      );
      final f =
          fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(ativo: true);
      }
      _registradorAuditoria.registrar(
        acao: 'FORNECEDOR_ATIVADO',
        resumo: 'Fornecedor reativado pelo administrador.',
        entidadeTipo: 'fornecedor',
        entidadeId: idFornecedor,
        entidadeNome: f?.razaoSocial,
        idFornecedor: idFornecedor,
        mudancas: const [
          AuditoriaMudanca(campo: 'Ativo', de: 'não', para: 'sim'),
        ],
      );
    } catch (e) {
      debugPrint('❌ Erro ao ativar fornecedor $idFornecedor: $e');
    }
  }

  // ==========================================================
  // === 🔹 1. Busca produtos do fornecedor pelo CÓDIGO DO EVENTO
  // ==========================================================
  Future<void> carregarServicosPorEvento(String idEvento) async {
    try {
      carregando.value = true;
      erro.value = '';

      final listaServicos =
          await _fornecedores.listarServicosPorEvento(idEvento);
      servicosFornecedor.assignAll(listaServicos);
      if (listaServicos.isEmpty) return;

      // 🔹 Carrega catálogo e fotos
      final idsProdutos = listaServicos.map((s) => s.idProdutoServico).toList();
      await carregarCatalogoServicos();

      for (final fornecedorId
          in listaServicos.map((s) => s.idFornecedor).toSet()) {
        await carregarFotosServicos(idsProdutos, fornecedorId);
      }
    } catch (e, s) {
      erro.value = 'Erro ao carregar serviços do evento: $e';
      debugPrint('❌ $e\n$s');
    } finally {
      carregando.value = false;
    }
  }

  // ==========================================================
  // === 🔹 Escuta os serviços de um fornecedor específico
  // ==========================================================
  Future<void> escutarServicosFornecedor(String idFornecedor) async {
    if (idFornecedor.trim().isEmpty) return;
    if (_servicosEscutandoId == idFornecedor &&
        _servicosFornecedorSub != null) {
      return;
    }

    await _servicosFornecedorSub?.cancel();
    _servicosEscutandoId = idFornecedor;

    _servicosFornecedorSub = _fornecedores
        .observarServicosFornecedor(idFornecedor)
        .listen((lista) async {
      servicosFornecedor.assignAll(lista);

      final ids = lista
          .map((e) => e.idProdutoServico)
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();

      await carregarCatalogoServicos();
      await carregarFotosServicos(ids, idFornecedor);
    }, onError: (e, s) {
      erro.value = 'Erro ao escutar serviços do fornecedor';
      debugPrint('❌ Erro ao escutar serviços do fornecedor: $e\n$s');
    });
  }

  Future<void> listarServicosFornecedor(String idFornecedor) async {
    try {
      carregando.value = true;
      erro.value = '';
      servicosDetalhado.clear();

      final lista = await _servicosProduto.listarServicosComDetalhes(
        idFornecedor: idFornecedor,
      );
      servicosDetalhado.assignAll(lista);
      await ai.carregarAiFornecedorComDadosAtuais();
    } catch (e, s) {
      erro.value = 'Erro ao carregar serviços: $e';
      debugPrint('❌ Erro ao listar serviços: $e\n$s');
    } finally {
      carregando.value = false;
    }
  }

  // ==========================================================
  // === 🔹 Carrega catálogo de serviços (coleção: servico_produto)
  // ==========================================================
  Future<void> carregarCatalogoServicos() async {
    final lista = await _servicosProduto.listarServicosAtivos();
    catalogoServicos.assignAll(lista);
  }

  // ==========================================================
  // === 🔹 Carrega fotos dos serviços
  // ==========================================================
  Future<void> carregarFotosServicos(
      List<String> idsProdutoServico, String idFornecedor) async {
    final idsUnicos =
        idsProdutoServico.where((id) => id.trim().isNotEmpty).toSet().toList();

    if (idsUnicos.isEmpty || idFornecedor.trim().isEmpty) {
      fotosServico.clear();
      return;
    }

    try {
      isLoadingFotos.value = true;
      final fotos = <ServicoFoto>[];
      for (final idProduto in idsUnicos) {
        fotos.addAll(
          await _servicoFotos.carregarFotos(
            idFornecedor: idFornecedor,
            idProdutoServico: idProduto,
          ),
        );
      }

      fotosServico.assignAll(fotos);
    } catch (e, s) {
      if (kDebugMode) debugPrint('Erro ao carregar fotos: $e\n$s');
    } finally {
      isLoadingFotos.value = false;
    }
  }

  // ==========================================================
  // === 🔹 Busca um serviço pelo ID
  // ==========================================================
  ServicoProduto? buscarServicoPorId(String idProdutoServico) {
    return catalogoServicos.firstWhereOrNull((s) => s.id == idProdutoServico);
  }

  // ==========================================================
  // === 🔹 Abre o BottomSheet para orçamento
  // ==========================================================
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

  // ==========================================================
  // === 🔹 Estatísticas básicas
  // ==========================================================

  Future<void> atualizarEstatisticasFornecedor() async {
    final f = fornecedor.value;
    if (f == null) return;

    try {
      final estatisticas =
          await _fornecedores.carregarEstatisticas(f.idFornecedor);
      solicitacoesPendentes.value = estatisticas.solicitacoesPendentes;
      servicosFornecedor.assignAll(estatisticas.servicosAtivos);
      mensagensNaoLidas.value = estatisticas.mensagensNaoLidas;
      avaliacaoMedia.value = estatisticas.avaliacaoMedia;
    } catch (e, s) {
      debugPrint('❌ Erro ao atualizar estatísticas: $e\n$s');
    }
  }

  Future<List<Map<String, dynamic>>>
      buscarSolicitacoesPendentesDetalhadas() async {
    final f = fornecedor.value;
    if (f == null) return [];

    return _fornecedores.listarSolicitacoesPendentesDetalhadas(f.idFornecedor);
  }

  // =============================================================
  // 🔸 FILTROS
  // =============================================================
  void aplicarFiltros({
    String? nome,
    String? cidade,
    String? categoria,
    bool? aprovado,
    bool? ativo,
  }) {
    filtroNome.value = nome ?? '';
    filtroCidade.value = cidade?.isEmpty ?? true ? null : cidade;
    filtroCategoria.value = categoria?.isEmpty ?? true ? null : categoria;
    filtroAprovado.value = aprovado;
    filtroAtivo.value = ativo;
  }

  void limparFiltros() {
    filtroNome.value = '';
    filtroCidade.value = null;
    filtroCategoria.value = null;
    filtroAprovado.value = null;
    filtroAtivo.value = null;
    update();
  }

  @override
  void onClose() {
    _solicitacoesSub?.cancel();
    _fornecedorCotacoesSub?.cancel();
    _servicosFornecedorSub?.cancel();

    for (final listener in _mensagemListeners) {
      listener.cancel();
    }
    _mensagemListeners.clear();

    _mensagensNaoLidasPorCotacao.clear();
    ai.limparAiFornecedor();
    pararListenerFornecedor();
    super.onClose();
  }
}
