// ================================
// 🔹 Controller reativo GetX
// ================================
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';

import 'package:app_faca_festa/data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:app_faca_festa/data/models/fornecedor/avaliacao_servico_model.dart';
import 'package:app_faca_festa/data/models/fornecedor/fornecedor_interacao_model.dart';
import 'package:app_faca_festa/data/models/fornecedor_intelligence/insight_fornecedor_model.dart';
import 'package:app_faca_festa/data/models/fornecedor_intelligence/proxima_acao_fornecedor_model.dart';
import 'package:app_faca_festa/data/models/fornecedor_intelligence/resumo_reputacao_fornecedor_model.dart';
import 'package:app_faca_festa/data/models/fornecedor_intelligence/score_cotacao_fornecedor_model.dart';
import 'package:app_faca_festa/data/models/fornecedor_intelligence/sugestao_resposta_cotacao_ai_model.dart';
import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/data/models/servico_produto/categoria_servico_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/fornecedor_categoria_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/servico_foto_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/subcategoria_servico_model.dart';
import 'package:app_faca_festa/data/services/auditoria/auditoria_app.dart';
import 'package:app_faca_festa/data/services/fornecedor_ai_generativa_service.dart';
import 'package:app_faca_festa/data/services/fornecedor_ai_service.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servico_fotos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/dialogs/show_novo_orcamento_bottom_sheet.dart';

class FornecedorController extends GetxController {
  FornecedorController({
    AutenticacaoRepository? autenticacaoRepository,
    GerenciarFornecedores? gerenciarFornecedores,
    GerenciarServicosProduto? gerenciarServicosProduto,
    FornecedorAiGenerativaService? fornecedorAiGenerativaService,
  })  : _autenticacaoRepository = autenticacaoRepository,
        _gerenciarFornecedores = gerenciarFornecedores,
        _gerenciarServicosProduto = gerenciarServicosProduto,
        _fornecedorAiGenerativaService = fornecedorAiGenerativaService;

  final AutenticacaoRepository? _autenticacaoRepository;
  final GerenciarFornecedores? _gerenciarFornecedores;
  final GerenciarServicosProduto? _gerenciarServicosProduto;
  final FornecedorAiGenerativaService? _fornecedorAiGenerativaService;

  /// 🔹 Dados principais do fornecedor logado
  final Rx<FornecedorModel?> fornecedor = Rx<FornecedorModel?>(null);
  final RxList<FornecedorModel> fornecedores = <FornecedorModel>[].obs;

  /// 🔹 Serviços (coleção `fornecedor_servico`)
  final RxList<FornecedorProdutoServicoModel> servicosFornecedor =
      <FornecedorProdutoServicoModel>[].obs;

  final RxList<FornecedorServicoDetalhadoDto> servicosDetalhado =
      <FornecedorServicoDetalhadoDto>[].obs;

  final RxList<FornecedorProdutoServicoModel> allServicosFornecedor =
      <FornecedorProdutoServicoModel>[].obs;

  /// 🔹 Catálogo global (`servico_produto`)
  final RxList<ServicoProdutoModel> catalogoServicos =
      <ServicoProdutoModel>[].obs;

  /// 🔹 Fotos dos serviços (`servico_foto`)
  final RxList<ServicoFotoModel> fotosServico = <ServicoFotoModel>[].obs;

  final RxList<CategoriaServicoModel> categorias =
      <CategoriaServicoModel>[].obs;

  final RxList<SubcategoriaServicoModel> subCategorias =
      <SubcategoriaServicoModel>[].obs;

  final categoriasServico = <Map<String, dynamic>>[].obs;
  final subcategoriasServico = <Map<String, dynamic>>[].obs;
  StreamSubscription<FornecedorModel?>? _fornecedorSubscription;

  //tempoMedioResposta

  final isLoadingServicos = false.obs;
  final isLoadingFotos = false.obs;

  StreamSubscription? _solicitacoesSub;
  StreamSubscription<int>? _fornecedorCotacoesSub;
  StreamSubscription<List<FornecedorProdutoServicoModel>>?
      _servicosFornecedorSub;
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
  late AppController appController; // 🔹 Define, mas sem inicializar aqui

  final filtroNome = ''.obs;
  final filtroCidade = RxnString();
  final filtroCategoria = RxnString();
  final filtroAprovado = RxnBool();
  final filtroAtivo = RxnBool();

  final filtroAvaliacaoMinima = 0.0.obs;
  // 🔹 Dados auxiliares carregados de outras coleções
  final enderecos = <EnderecoUsuarioModel>[].obs;
  final categoriasFornecedor = <FornecedorCategoriaModel>[].obs;
  final List<StreamSubscription> _mensagemListeners = [];

  // ============================================================
  // 🔹 IA LOCAL DO FORNECEDOR (sem API externa / sem Firestore)
  // ============================================================
  final FornecedorAiService _fornecedorAiService = FornecedorAiService();

  // ============================================================
  // 🔹 IA GENERATIVA - resposta sugerida para cotação
  // ============================================================
  FornecedorAiGenerativaService get _aiGenerativaService =>
      _fornecedorAiGenerativaService ??
      Get.find<FornecedorAiGenerativaService>();

  /// Cache local em memória por cotação. Não grava no Firestore.
  final RxMap<String, SugestaoRespostaCotacaoAiModel>
      sugestoesRespostaCotacaoAi =
      <String, SugestaoRespostaCotacaoAiModel>{}.obs;

  /// Loading individual por cotação. Evita bloquear todos os cards.
  final RxMap<String, bool> carregandoRespostaCotacaoAi = <String, bool>{}.obs;

  /// Loading geral para algum painel que queira observar a geração.
  final RxBool isLoadingRespostaCotacaoAi = false.obs;

  final Rxn<ProximaAcaoFornecedorModel> proximaAcaoFornecedor =
      Rxn<ProximaAcaoFornecedorModel>();

  final RxList<InsightFornecedorModel> insightsFornecedor =
      <InsightFornecedorModel>[].obs;

  /// Score calculado por cotação. Chave: idCotacao.
  final RxMap<String, ScoreCotacaoFornecedorModel> scoresCotacoes =
      <String, ScoreCotacaoFornecedorModel>{}.obs;

  final Rxn<ResumoReputacaoFornecedorModel> resumoReputacao =
      Rxn<ResumoReputacaoFornecedorModel>();

  final RxList<InsightFornecedorModel> alertasPerfil =
      <InsightFornecedorModel>[].obs;

  final RxBool isLoadingAi = false.obs;

  bool _aiInicializada = false;
  String? _ultimaChaveCacheAi;
  DateTime? _ultimaAtualizacaoAi;
  bool _carregandoAiInterno = false;

  /// Reservado para futuras streams específicas da IA.
  /// Hoje a IA é local, mas mantemos a lista para evitar vazamento
  /// se futuramente algum insight passar a ser escutado em tempo real.
  final List<StreamSubscription<dynamic>> _aiSubscriptions = [];

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
    sugestoesRespostaCotacaoAi.clear();
    carregandoRespostaCotacaoAi.clear();
    isLoadingRespostaCotacaoAi.value = false;
    mensagensNaoLidas.value = 0;
    _limparDadosAi();
    fornecedor.value = null;
    aptoParaOperar.value = false;
  }

  @override
  void onInit() {
    super.onInit();

    Future.delayed(Duration.zero, () {
      appController = Get.find<AppController>();
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
          carregarAiFornecedorComDadosAtuais();
        } else {
          _limparDadosAi();
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
    _limparDadosAi();
  }

  Future<List<ServicoProdutoModel>> buscarServicosFornecedorPorCategorias(
      String idFornecedor) async {
    try {
      return await _servicosProduto
          .listarServicosAtivosPorCategoriasFornecedor(idFornecedor);
    } catch (e, s) {
      debugPrint('Erro ao buscar serviços do fornecedor: $e\n$s');
      return [];
    }
  }

  /// 🔹 Atualiza os dados de um fornecedor existente no Firestore
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) async {
    try {
      await _fornecedores.atualizarFornecedor(fornecedor);
      AuditoriaApp.registrar(
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
  Future<String> uploadBanner(
    File imageFile, {
    Uint8List? bytesWeb,
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
        imageFile: imageFile,
        bytesWeb: bytesWeb,
        uid: userId,
      );
    } catch (e) {
      throw Exception("Erro ao enviar banner: $e");
    }
  }

  String? get _idUsuarioAtual {
    if (_autenticacaoRepository != null) {
      return _autenticacaoRepository.idUsuarioAtual;
    }
    if (!Get.isRegistered<AutenticacaoRepository>()) return null;
    return Get.find<AutenticacaoRepository>().idUsuarioAtual;
  }

  GerenciarFornecedores get _fornecedores {
    if (_gerenciarFornecedores != null) return _gerenciarFornecedores;
    return Get.find<GerenciarFornecedores>();
  }

  GerenciarServicosProduto get _servicosProduto {
    if (_gerenciarServicosProduto != null) return _gerenciarServicosProduto;
    return Get.find<GerenciarServicosProduto>();
  }

  Future<void> carregarTodosFornecedores() async {
    try {
      carregando.value = true;
      erro.value = '';

      final tipo = Get.isRegistered<AppController>()
          ? Get.find<AppController>().usuarioLogado.value?.tipo
          : null;
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

  Future<FornecedorModel?> buscarFornecedor(String idUsuario) async {
    try {
      return await _fornecedores.buscarPorIdUsuario(idUsuario);
    } catch (e) {
      debugPrint("❌ Erro ao buscar último evento: $e");
      return null;
    }
  }

  bool _usuarioLogadoEhFornecedor() {
    try {
      return Get.find<AppController>().usuarioLogado.value?.tipo == 'F';
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
  List<FornecedorModel> get fornecedoresFiltrados {
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

  String cidadeDoFornecedor(FornecedorModel f) {
    return enderecos
            .firstWhereOrNull((e) => e.idUsuario == f.idUsuario)
            ?.nomeCidade ??
        '';
  }

  List<String> nomesCategoriasDoFornecedor(FornecedorModel f) {
    return categoriasFornecedor
        .where((c) => c.idFornecedor == f.idFornecedor)
        .map((c) => (c.nomeCategoria ?? '').trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
  }

  int servicosDoFornecedor(FornecedorModel f) {
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
      AuditoriaApp.registrar(
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
      AuditoriaApp.registrar(
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
      AuditoriaApp.registrar(
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
      await carregarAiFornecedorComDadosAtuais();
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
      final fotos = <ServicoFotoModel>[];
      for (final idProduto in idsUnicos) {
        fotos.addAll(
          await Get.find<GerenciarServicoFotos>().carregarFotos(
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
  ServicoProdutoModel? buscarServicoPorId(String idProdutoServico) {
    return catalogoServicos.firstWhereOrNull((s) => s.id == idProdutoServico);
  }

  // ==========================================================
  // === 🔹 Abre o BottomSheet para orçamento
  // ==========================================================
  Future<void> abrirCotacao({
    required BuildContext context,
    required String idEvento,
    required FornecedorProdutoServicoModel servicoFornecedor,
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
  // 🔸 IA GENERATIVA - resposta sugerida para cotação
  // =============================================================

  bool isGerandoRespostaCotacaoAi(String idCotacao) {
    if (idCotacao.trim().isEmpty) return false;
    return carregandoRespostaCotacaoAi[idCotacao] == true;
  }

  SugestaoRespostaCotacaoAiModel? sugestaoRespostaAiDaCotacao(
    String idCotacao,
  ) {
    if (idCotacao.trim().isEmpty) return null;
    return sugestoesRespostaCotacaoAi[idCotacao];
  }

  /// Gera apenas uma sugestão para revisão do fornecedor.
  ///
  /// Não envia mensagem, não confirma contratação e não grava no Firestore.
  Future<SugestaoRespostaCotacaoAiModel> gerarRespostaCotacaoComIa({
    required dynamic solicitacao,
    bool forceRefresh = false,
  }) async {
    final idCotacao = _readCotacaoString(
      solicitacao,
      const ['id', 'idCotacao', 'id_cotacao'],
    );

    if (idCotacao.isEmpty) {
      return _fallbackRespostaCotacaoAi(
        'Não foi possível identificar a cotação para gerar a resposta.',
      );
    }

    final cached = sugestoesRespostaCotacaoAi[idCotacao];
    if (!forceRefresh &&
        cached != null &&
        cached.respostaSugerida.trim().isNotEmpty) {
      return cached;
    }

    final fornecedorAtual = fornecedor.value;
    if (fornecedorAtual == null) {
      return _fallbackRespostaCotacaoAi(
        'Não foi possível identificar o fornecedor logado.',
      );
    }

    if (carregandoRespostaCotacaoAi[idCotacao] == true) {
      return cached ??
          _fallbackRespostaCotacaoAi(
            'A sugestão já está sendo gerada. Aguarde alguns instantes.',
          );
    }

    try {
      carregandoRespostaCotacaoAi[idCotacao] = true;
      isLoadingRespostaCotacaoAi.value = true;

      final input = _montarCotacaoInputParaIa(solicitacao);
      final eventoCotacao = await _buscarEventoParaRespostaAi(input.idEvento);

      final sugestao = await _aiGenerativaService.gerarSugestaoRespostaCotacao(
        fornecedor: fornecedorAtual,
        evento: eventoCotacao,
        cotacao: input,
        servicosFornecedor: servicosDetalhado.toList(),
      );

      final resultado = sugestao.respostaSugerida.trim().isEmpty
          ? _fallbackRespostaCotacaoAi(
              'A resposta gerada veio vazia. Revise os dados da cotação e tente novamente.',
            )
          : sugestao;

      sugestoesRespostaCotacaoAi[idCotacao] = resultado;
      return resultado;
    } catch (e, s) {
      debugPrint('❌ Erro ao gerar resposta da cotação com IA: $e\n$s');

      final fallback = _fallbackRespostaCotacaoAi(
        'Não foi possível gerar a sugestão agora. Você ainda pode responder manualmente.',
      );

      sugestoesRespostaCotacaoAi[idCotacao] = fallback;
      return fallback;
    } finally {
      carregandoRespostaCotacaoAi[idCotacao] = false;
      isLoadingRespostaCotacaoAi.value = false;
    }
  }

  Future<EventoModel?> _buscarEventoParaRespostaAi(String? idEvento) async {
    final id = idEvento?.trim() ?? '';
    if (id.isEmpty) return null;

    try {
      return _fornecedores.buscarEventoPorId(id);
    } catch (e) {
      debugPrint('⚠️ Não foi possível carregar evento para IA da cotação: $e');
      return null;
    }
  }

  FornecedorAiCotacaoInput _montarCotacaoInputParaIa(dynamic solicitacao) {
    final idCotacao = _readCotacaoString(
      solicitacao,
      const ['id', 'idCotacao', 'id_cotacao'],
    );

    final categoria = _readCotacaoString(
      solicitacao,
      const ['categoriaNome', 'categoria_nome', 'categoria'],
    );

    final subcategoria = _readCotacaoString(
      solicitacao,
      const ['subcategoriaNome', 'subcategoria_nome', 'subcategoria'],
    );

    final descricao = _readCotacaoString(
      solicitacao,
      const ['descricao', 'observacao', 'mensagemCliente', 'mensagem_cliente'],
    );

    final valorReferencia = _readCotacaoDouble(
      solicitacao,
      const [
        'valorEstimadoTotal',
        'valor_estimado_total',
        'valorReferencia',
        'valor_referencia'
      ],
    );

    return FornecedorAiCotacaoInput(
      idCotacao: idCotacao,
      idEvento: _readCotacaoString(
        solicitacao,
        const ['idEvento', 'id_evento'],
      ),
      idFornecedor: fornecedor.value?.idFornecedor,
      idOrganizador: _readCotacaoString(
        solicitacao,
        const [
          'idUsuarioSolicitante',
          'id_usuario_solicitante',
          'idOrganizador',
          'id_organizador'
        ],
      ),
      categoriaSolicitada: categoria,
      subcategoriaSolicitada: subcategoria,
      mensagemCliente: descricao,
      statusCotacao: _readCotacaoStatus(solicitacao),
      valorReferencia: valorReferencia,
      cidadeEvento: _readCotacaoString(
        solicitacao,
        const ['cidadeEvento', 'cidade_evento', 'cidade'],
      ),
      ufEvento: _readCotacaoString(
        solicitacao,
        const ['ufEvento', 'uf_evento', 'uf'],
      ),
      dataSolicitacao: _readCotacaoDate(
        solicitacao,
        const [
          'dataCadastro',
          'data_cadastro',
          'dataSolicitacao',
          'data_solicitacao',
          'dataEnvio',
          'data_envio'
        ],
      ),
      visualizadoEm: _readCotacaoDate(
        solicitacao,
        const ['visualizadoEm', 'visualizado_em'],
      ),
      dataResposta: _readCotacaoDate(
        solicitacao,
        const ['dataResposta', 'data_resposta'],
      ),
    );
  }

  SugestaoRespostaCotacaoAiModel _fallbackRespostaCotacaoAi(String motivo) {
    return SugestaoRespostaCotacaoAiModel(
      respostaSugerida:
          'Olá, tudo bem? Recebi sua solicitação de orçamento. Para preparar uma proposta adequada, poderia me confirmar o serviço desejado, a data, o local do evento e a quantidade de convidados?',
      versaoCurta:
          'Olá! Para preparar uma proposta, poderia me confirmar o serviço desejado, data, local e quantidade de convidados?',
      pontosParaRevisar: const [
        'Confirmar disponibilidade antes de responder.',
        'Conferir serviço solicitado.',
        'Revisar preço ou faixa de preço antes de enviar.',
      ],
      perguntasFaltantes: const [
        'Qual serviço você deseja para o evento?',
        'Onde será o evento?',
        'Para quantas pessoas será o evento?',
      ],
      dadosUtilizados: const [],
      alertas: [motivo],
      nivelConfianca: 'baixo',
      motivoNivelConfianca:
          'Os dados disponíveis não foram suficientes para gerar uma resposta mais precisa.',
    );
  }

  String _readCotacaoStatus(dynamic solicitacao) {
    try {
      final dynamic status = _readDynamicCotacaoField(solicitacao, 'status');
      if (status == null) return '';

      try {
        final dynamic name = status.name;
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      } catch (_) {}

      return status.toString().trim();
    } catch (_) {
      return '';
    }
  }

  String _readCotacaoString(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _readDynamicCotacaoField(solicitacao, field);
        if (value == null) continue;

        final text = value.toString().trim();
        if (text.isNotEmpty && text != 'null') {
          return text;
        }
      } catch (_) {}
    }

    return '';
  }

  double? _readCotacaoDouble(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _readDynamicCotacaoField(solicitacao, field);
        if (value == null) continue;

        if (value is num) return value.toDouble();

        final normalized = value
            .toString()
            .replaceAll('R\$', '')
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();

        final parsed = double.tryParse(normalized);
        if (parsed != null) return parsed;
      } catch (_) {}
    }

    return null;
  }

  DateTime? _readCotacaoDate(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _readDynamicCotacaoField(solicitacao, field);
        if (value == null) continue;

        if (value is DateTime) return value;
        try {
          final dynamic candidate = value;
          final converted = candidate.toDate();
          if (converted is DateTime) return converted;
        } catch (_) {
          // Segue para parse de String abaixo.
        }

        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) return parsed;
      } catch (_) {}
    }

    return null;
  }

  dynamic _readDynamicCotacaoField(dynamic source, String field) {
    if (source == null) return null;

    if (source is Map) {
      return source[field];
    }

    switch (field) {
      case 'id':
        return source.id;
      case 'idCotacao':
        return source.idCotacao;
      case 'id_cotacao':
        return source.id_cotacao;
      case 'idEvento':
        return source.idEvento;
      case 'id_evento':
        return source.id_evento;
      case 'idUsuarioSolicitante':
        return source.idUsuarioSolicitante;
      case 'id_usuario_solicitante':
        return source.id_usuario_solicitante;
      case 'idOrganizador':
        return source.idOrganizador;
      case 'id_organizador':
        return source.id_organizador;
      case 'categoriaNome':
        return source.categoriaNome;
      case 'categoria_nome':
        return source.categoria_nome;
      case 'categoria':
        return source.categoria;
      case 'subcategoriaNome':
        return source.subcategoriaNome;
      case 'subcategoria_nome':
        return source.subcategoria_nome;
      case 'subcategoria':
        return source.subcategoria;
      case 'descricao':
        return source.descricao;
      case 'observacao':
        return source.observacao;
      case 'mensagemCliente':
        return source.mensagemCliente;
      case 'mensagem_cliente':
        return source.mensagem_cliente;
      case 'valorEstimadoTotal':
        return source.valorEstimadoTotal;
      case 'valor_estimado_total':
        return source.valor_estimado_total;
      case 'valorReferencia':
        return source.valorReferencia;
      case 'valor_referencia':
        return source.valor_referencia;
      case 'cidadeEvento':
        return source.cidadeEvento;
      case 'cidade_evento':
        return source.cidade_evento;
      case 'cidade':
        return source.cidade;
      case 'ufEvento':
        return source.ufEvento;
      case 'uf_evento':
        return source.uf_evento;
      case 'uf':
        return source.uf;
      case 'dataCadastro':
        return source.dataCadastro;
      case 'data_cadastro':
        return source.data_cadastro;
      case 'dataSolicitacao':
        return source.dataSolicitacao;
      case 'data_solicitacao':
        return source.data_solicitacao;
      case 'dataEnvio':
        return source.dataEnvio;
      case 'data_envio':
        return source.data_envio;
      case 'visualizadoEm':
        return source.visualizadoEm;
      case 'visualizado_em':
        return source.visualizado_em;
      case 'dataResposta':
        return source.dataResposta;
      case 'data_resposta':
        return source.data_resposta;
      case 'status':
        return source.status;
      default:
        return null;
    }
  }

  // =============================================================
  // 🔸 IA LOCAL DO FORNECEDOR
  // =============================================================

  /// Carrega/recalcula os dados de IA usando apenas os dados já disponíveis
  /// em memória ou recebidos por parâmetro.
  ///
  /// Não consulta Firestore, não grava dados e não envia mensagens.
  Future<void> carregarAiFornecedorComDadosAtuais({
    List<AvaliacaoServicoModel> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<EventoModel> eventos = const [],
    List<FornecedorInteracaoModel> interacoes = const [],
    bool forceRefresh = false,
  }) async {
    final f = fornecedor.value;

    if (f == null) {
      _limparDadosAi();
      return;
    }

    if (_carregandoAiInterno) return;

    final chaveAtual = _gerarChaveCacheAi(
      fornecedor: f,
      servicos: servicosDetalhado,
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
    );

    if (!forceRefresh && _podeUsarCacheAi(chaveAtual)) {
      return;
    }

    try {
      _carregandoAiInterno = true;
      isLoadingAi.value = true;

      final analiseFornecedor = _fornecedorAiService.gerarAnaliseFornecedor(
        fornecedor: f,
        servicos: servicosDetalhado,
        avaliacoes: avaliacoes,
      );

      resumoReputacao.value = analiseFornecedor.resumoReputacao;
      alertasPerfil.assignAll(analiseFornecedor.alertasPerfilIncompleto);

      final novosInsights = <InsightFornecedorModel>[
        ...analiseFornecedor.alertasPerfilIncompleto,
        _catalogoParaInsight(
          f.idFornecedor,
          analiseFornecedor.sugestaoCatalogo,
        ),
        _reputacaoParaInsight(
          f.idFornecedor,
          analiseFornecedor.resumoReputacao,
        ),
      ];

      final novosScores = <String, ScoreCotacaoFornecedorModel>{};
      ProximaAcaoFornecedorModel? melhorAcao;

      for (final cotacao in cotacoes) {
        final evento = _buscarEventoDaCotacao(
          cotacao: cotacao,
          eventos: eventos,
        );

        final analiseCotacao = _fornecedorAiService.gerarAnaliseCotacao(
          fornecedor: f,
          evento: evento,
          cotacao: cotacao,
          servicos: servicosDetalhado,
          interacoes: interacoes,
          catalogo: analiseFornecedor.sugestaoCatalogo,
          reputacao: analiseFornecedor.resumoReputacao,
        );

        novosScores[cotacao.idCotacao] = analiseCotacao.scoreCotacao;

        novosInsights.add(
          _scoreCotacaoParaInsight(
            f.idFornecedor,
            analiseCotacao.scoreCotacao,
            analiseCotacao.motivosOportunidade,
          ),
        );

        melhorAcao = _selecionarMelhorAcao(
          atual: melhorAcao,
          candidata: analiseCotacao.proximaAcao,
        );
      }

      scoresCotacoes.assignAll(novosScores);

      melhorAcao ??= _fornecedorAiService.gerarProximaAcaoInteligente(
        fornecedor: f,
        catalogo: analiseFornecedor.sugestaoCatalogo,
        reputacao: analiseFornecedor.resumoReputacao,
      );

      proximaAcaoFornecedor.value = melhorAcao;
      insightsFornecedor.assignAll(_ordenarInsights(novosInsights));

      _ultimaChaveCacheAi = chaveAtual;
      _ultimaAtualizacaoAi = DateTime.now();
      _aiInicializada = true;
    } catch (e, s) {
      debugPrint('❌ Erro ao gerar IA local do fornecedor: $e\n$s');
      _aplicarFallbackAi(f);
    } finally {
      isLoadingAi.value = false;
      _carregandoAiInterno = false;
    }
  }

  /// Atalho para recalcular a IA ignorando o cache local.
  Future<void> recalcularAiFornecedor({
    List<AvaliacaoServicoModel> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<EventoModel> eventos = const [],
    List<FornecedorInteracaoModel> interacoes = const [],
  }) async {
    await carregarAiFornecedorComDadosAtuais(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: true,
    );
  }

  /// Inicializa a IA somente uma vez. Útil para tela que chama o controller
  /// no initState/onReady e não quer recalcular a cada rebuild.
  Future<void> inicializarAiFornecedorUmaVez({
    List<AvaliacaoServicoModel> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<EventoModel> eventos = const [],
    List<FornecedorInteracaoModel> interacoes = const [],
  }) async {
    if (_aiInicializada) return;

    await carregarAiFornecedorComDadosAtuais(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
    );
  }

  /// Opcional: aproveita o método já existente de solicitações pendentes
  /// e transforma os mapas em DTOs de entrada para a IA.
  ///
  /// Use apenas quando a tela realmente precisar dos scores de cotação,
  /// pois este método usa a busca já existente de solicitações detalhadas.
  Future<void> carregarAiDasSolicitacoesPendentes({
    List<AvaliacaoServicoModel> avaliacoes = const [],
    List<EventoModel> eventos = const [],
    List<FornecedorInteracaoModel> interacoes = const [],
    bool forceRefresh = false,
  }) async {
    final f = fornecedor.value;
    if (f == null) {
      _limparDadosAi();
      return;
    }

    final solicitacoes = await buscarSolicitacoesPendentesDetalhadas();

    final cotacoes = solicitacoes
        .map(_cotacaoInputFromSolicitacaoMap)
        .whereType<FornecedorAiCotacaoInput>()
        .toList();

    await carregarAiFornecedorComDadosAtuais(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: forceRefresh,
    );
  }

  void limparAiFornecedor() {
    _limparDadosAi();
  }

  void _limparDadosAi() {
    proximaAcaoFornecedor.value = null;
    insightsFornecedor.clear();
    scoresCotacoes.clear();
    resumoReputacao.value = null;
    alertasPerfil.clear();
    isLoadingAi.value = false;
    sugestoesRespostaCotacaoAi.clear();
    carregandoRespostaCotacaoAi.clear();
    isLoadingRespostaCotacaoAi.value = false;

    _ultimaChaveCacheAi = null;
    _ultimaAtualizacaoAi = null;
    _aiInicializada = false;
    _carregandoAiInterno = false;
  }

  bool _podeUsarCacheAi(String chaveAtual) {
    if (_ultimaChaveCacheAi == null || _ultimaAtualizacaoAi == null) {
      return false;
    }

    if (_ultimaChaveCacheAi != chaveAtual) {
      return false;
    }

    final diff = DateTime.now().difference(_ultimaAtualizacaoAi!);
    return diff.inMinutes < 10;
  }

  String _gerarChaveCacheAi({
    required FornecedorModel fornecedor,
    required List<FornecedorServicoDetalhadoDto> servicos,
    required List<AvaliacaoServicoModel> avaliacoes,
    required List<FornecedorAiCotacaoInput> cotacoes,
    required List<EventoModel> eventos,
    required List<FornecedorInteracaoModel> interacoes,
  }) {
    final partes = <String>[
      fornecedor.idFornecedor,
      fornecedor.ativo.toString(),
      fornecedor.aptoParaOperar.toString(),
      fornecedor.mediaAvaliacoes.toStringAsFixed(2),
      fornecedor.totalAvaliacoes.toString(),
      fornecedor.totalContratacoes.toString(),
      fornecedor.categorias.length.toString(),
      fornecedor.tipoEventoIds.length.toString(),
      fornecedor.tipoEventoSlugs.length.toString(),
      fornecedor.tipoEventoNomes.length.toString(),
      fornecedor.precoMinimo?.toStringAsFixed(2) ?? 'sem_min',
      fornecedor.precoMaximo?.toStringAsFixed(2) ?? 'sem_max',
      fornecedor.precoMedio?.toStringAsFixed(2) ?? 'sem_medio',
      servicos.length.toString(),
      avaliacoes.length.toString(),
      cotacoes.length.toString(),
      eventos.length.toString(),
      interacoes.length.toString(),
      servicos
          .map((s) => '${s.id}:${s.ativo}:${s.preco}:${s.precoPromocao ?? ''}')
          .join('|'),
      cotacoes
          .map((c) =>
              '${c.idCotacao}:${c.statusCotacao ?? ''}:${c.valorReferencia ?? ''}')
          .join('|'),
    ];

    return partes.join('#');
  }

  EventoModel? _buscarEventoDaCotacao({
    required FornecedorAiCotacaoInput cotacao,
    required List<EventoModel> eventos,
  }) {
    final idEvento = cotacao.idEvento;

    if (idEvento == null || idEvento.trim().isEmpty) {
      return null;
    }

    return eventos.firstWhereOrNull((evento) => evento.idEvento == idEvento);
  }

  ProximaAcaoFornecedorModel _selecionarMelhorAcao({
    required ProximaAcaoFornecedorModel? atual,
    required ProximaAcaoFornecedorModel candidata,
  }) {
    if (atual == null) return candidata;

    if (candidata.urgente && !atual.urgente) {
      return candidata;
    }

    if (candidata.prioridade > atual.prioridade) {
      return candidata;
    }

    final scoreAtual = atual.score ?? 0;
    final scoreCandidata = candidata.score ?? 0;

    if (candidata.prioridade == atual.prioridade &&
        scoreCandidata > scoreAtual) {
      return candidata;
    }

    return atual;
  }

  List<InsightFornecedorModel> _ordenarInsights(
    List<InsightFornecedorModel> insights,
  ) {
    final filtrados =
        insights.where((item) => item.titulo.trim().isNotEmpty).toList();

    filtrados.sort((a, b) {
      final prioridadeCompare = b.prioridade.compareTo(a.prioridade);

      if (prioridadeCompare != 0) {
        return prioridadeCompare;
      }

      final scoreA = a.score ?? 0;
      final scoreB = b.score ?? 0;

      return scoreB.compareTo(scoreA);
    });

    return filtrados;
  }

  InsightFornecedorModel _catalogoParaInsight(
    String idFornecedor,
    dynamic catalogo,
  ) {
    return InsightFornecedorModel(
      idInsight: 'insight_catalogo_$idFornecedor',
      idFornecedor: idFornecedor,
      tipo: 'catalogo',
      titulo: catalogo.titulo,
      descricao: catalogo.descricao,
      prioridade: catalogo.scoreCatalogo < 40 ? 5 : 3,
      score: catalogo.scoreCatalogo,
      nivel: catalogo.nivelCatalogo,
      motivos: List<String>.from(catalogo.pendencias),
      acoesSugeridas: List<String>.from(catalogo.melhoriasPrioritarias),
      origem: catalogo.origem,
      status: 'novo',
      versaoRegra: catalogo.versaoRegra,
      createdAt: DateTime.now(),
      expiresAt: catalogo.expiresAt,
    );
  }

  InsightFornecedorModel _reputacaoParaInsight(
    String idFornecedor,
    ResumoReputacaoFornecedorModel reputacao,
  ) {
    final prioridade =
        reputacao.totalAvaliacoes < 5 || reputacao.mediaGeral < 4 ? 4 : 2;

    return InsightFornecedorModel(
      idInsight: 'insight_reputacao_$idFornecedor',
      idFornecedor: idFornecedor,
      tipo: 'reputacao',
      titulo: 'Resumo da reputação',
      descricao: reputacao.resumo,
      prioridade: prioridade,
      score: reputacao.mediaGeral,
      nivel: reputacao.tendencia,
      motivos: [
        ...reputacao.pontosFortes,
        ...reputacao.pontosAtencao,
      ],
      acoesSugeridas: reputacao.totalAvaliacoes < 5
          ? ['Solicitar avaliações após eventos concluídos']
          : ['Acompanhar avaliações recentes'],
      origem: reputacao.origem,
      status: 'novo',
      versaoRegra: reputacao.versaoRegra,
      createdAt: DateTime.now(),
      expiresAt: reputacao.expiresAt,
    );
  }

  InsightFornecedorModel _scoreCotacaoParaInsight(
    String idFornecedor,
    ScoreCotacaoFornecedorModel score,
    List<String> motivos,
  ) {
    final prioridade = score.score >= 75
        ? 5
        : score.score >= 45
            ? 3
            : 2;

    final titulo = score.score >= 75
        ? 'Cotação com alta oportunidade'
        : score.score >= 45
            ? 'Cotação com oportunidade moderada'
            : 'Cotação com baixa compatibilidade';

    return InsightFornecedorModel(
      idInsight: 'insight_score_${score.idCotacao}',
      idFornecedor: idFornecedor,
      idEvento: score.idEvento.trim().isEmpty ? null : score.idEvento,
      idCotacao: score.idCotacao.trim().isEmpty ? null : score.idCotacao,
      tipo: 'oportunidade_cotacao',
      titulo: titulo,
      descricao: 'Score de oportunidade: ${score.score.toStringAsFixed(0)}%.',
      prioridade: prioridade,
      score: score.score,
      nivel: score.nivel,
      motivos: motivos,
      acoesSugeridas: score.score >= 45
          ? ['Analisar cotação', 'Responder com proposta clara']
          : ['Revisar compatibilidade antes de responder'],
      origem: score.origem,
      status: 'novo',
      versaoRegra: score.versaoRegra,
      createdAt: DateTime.now(),
      expiresAt: score.expiresAt,
    );
  }

  FornecedorAiCotacaoInput? _cotacaoInputFromSolicitacaoMap(
    Map<String, dynamic> data,
  ) {
    final idCotacao =
        (data['idCotacao'] ?? data['id_cotacao'] ?? '').toString();

    if (idCotacao.trim().isEmpty) return null;

    return FornecedorAiCotacaoInput(
      idCotacao: idCotacao,
      idEvento: data['idEvento']?.toString() ?? data['id_evento']?.toString(),
      idFornecedor: fornecedor.value?.idFornecedor,
      idOrganizador: data['idUsuarioSolicitante']?.toString() ??
          data['id_usuario_solicitante']?.toString(),
      categoriaSolicitada: data['categoriaNome']?.toString() ??
          data['categoria_nome']?.toString(),
      mensagemCliente:
          data['descricao']?.toString() ?? data['observacao']?.toString(),
      statusCotacao: data['status']?.toString() ?? 'pendente',
      valorReferencia: _toDoubleOrNull(
        data['valorEstimadoTotal'] ?? data['valor_estimado_total'],
      ),
      dataSolicitacao: _toDateTimeOrNull(
        data['dataEnvio'] ?? data['data_envio'],
      ),
    );
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    try {
      final dynamic candidate = value;
      final converted = candidate.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Mantém compatibilidade com valores que não são Timestamp do Firestore.
    }
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  void _aplicarFallbackAi(FornecedorModel fornecedor) {
    final now = DateTime.now();

    proximaAcaoFornecedor.value = ProximaAcaoFornecedorModel(
      idAcao: 'acao_fallback_${fornecedor.idFornecedor}',
      idFornecedor: fornecedor.idFornecedor,
      tipoAcao: 'fallback',
      titulo: 'Não foi possível gerar a análise agora',
      descricao:
          'Verifique seu catálogo, mantenha seus dados atualizados e responda novas cotações rapidamente.',
      acaoPrincipal: 'Revisar perfil',
      prioridade: 2,
      urgente: false,
      origem: 'deterministic_rules',
      versaoRegra: '1.0.0',
      status: 'novo',
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
    );

    insightsFornecedor.assignAll([
      InsightFornecedorModel(
        idInsight: 'insight_fallback_${fornecedor.idFornecedor}',
        idFornecedor: fornecedor.idFornecedor,
        tipo: 'fallback',
        titulo: 'Análise indisponível',
        descricao:
            'Não conseguimos calcular os insights com os dados atuais. Complete o perfil e tente novamente.',
        prioridade: 2,
        motivos: const [
          'Dados insuficientes ou falha no processamento local.',
        ],
        acoesSugeridas: const [
          'Completar perfil',
          'Revisar catálogo',
        ],
        origem: 'deterministic_rules',
        status: 'novo',
        versaoRegra: '1.0.0',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      ),
    ]);
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

    for (final sub in _aiSubscriptions) {
      sub.cancel();
    }
    _aiSubscriptions.clear();

    _mensagensNaoLidasPorCotacao.clear();
    sugestoesRespostaCotacaoAi.clear();
    carregandoRespostaCotacaoAi.clear();
    isLoadingRespostaCotacaoAi.value = false;
    _limparDadosAi();
    pararListenerFornecedor();
    super.onClose();
  }
}
