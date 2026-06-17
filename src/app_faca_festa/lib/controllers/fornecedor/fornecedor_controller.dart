// ================================
// 🔹 Controller reativo GetX
// ================================
// ignore_for_file: avoid_print

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';

import '../../data/models/fornecedor_intelligence/resumo_reputacao_fornecedor_model.dart';
import '../../data/models/fornecedor_intelligence/score_cotacao_fornecedor_model.dart';
import '../../data/models/fornecedor_intelligence/proxima_acao_fornecedor_model.dart';
import '../../data/models/fornecedor_intelligence/insight_fornecedor_model.dart';
import '../../data/models/fornecedor_intelligence/sugestao_resposta_cotacao_ai_model.dart';
import '../../data/models/servico_produto/subcategoria_servico_model.dart';
import '../../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../../presentation/dialogs/show_novo_orcamento_bottom_sheet.dart';
import '../../data/models/servico_produto/categoria_servico_model.dart';
import '../../data/models/fornecedor/fornecedor_interacao_model.dart';
import '../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../data/models/servico_produto/servico_foto_model.dart';
import '../../data/models/fornecedor/avaliacao_servico_model.dart';
import '../../data/services/fornecedor_ai_service.dart';
import '../../data/services/fornecedor_ai_generativa_service.dart';
import '../../data/models/model.dart';
import '../app_controller.dart';

class FornecedorController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
  final RxList<ServicoProdutoModel> catalogoServicos = <ServicoProdutoModel>[].obs;

  /// 🔹 Fotos dos serviços (`servico_foto`)
  final RxList<ServicoFotoModel> fotosServico = <ServicoFotoModel>[].obs;

  final RxList<CategoriaServicoModel> categorias = <CategoriaServicoModel>[].obs;

  final RxList<SubcategoriaServicoModel> subCategorias = <SubcategoriaServicoModel>[].obs;

  final categoriasServico = <Map<String, dynamic>>[].obs;
  final subcategoriasServico = <Map<String, dynamic>>[].obs;
  StreamSubscription<QuerySnapshot>? _fornecedorSubscription;

  //tempoMedioResposta

  final isLoadingServicos = false.obs;
  final isLoadingFotos = false.obs;

  StreamSubscription? _solicitacoesSub;
  StreamSubscription<QuerySnapshot>? _fornecedorCotacoesSub;
  StreamSubscription<QuerySnapshot>? _servicosFornecedorSub;
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
  final FornecedorAiGenerativaService _fornecedorAiGenerativaService =
      FornecedorAiGenerativaService();

  /// Cache local em memória por cotação. Não grava no Firestore.
  final RxMap<String, SugestaoRespostaCotacaoAiModel> sugestoesRespostaCotacaoAi =
      <String, SugestaoRespostaCotacaoAiModel>{}.obs;

  /// Loading individual por cotação. Evita bloquear todos os cards.
  final RxMap<String, bool> carregandoRespostaCotacaoAi = <String, bool>{}.obs;

  /// Loading geral para algum painel que queira observar a geração.
  final RxBool isLoadingRespostaCotacaoAi = false.obs;

  final Rxn<ProximaAcaoFornecedorModel> proximaAcaoFornecedor = Rxn<ProximaAcaoFornecedorModel>();

  final RxList<InsightFornecedorModel> insightsFornecedor = <InsightFornecedorModel>[].obs;

  /// Score calculado por cotação. Chave: idCotacao.
  final RxMap<String, ScoreCotacaoFornecedorModel> scoresCotacoes =
      <String, ScoreCotacaoFornecedorModel>{}.obs;

  final Rxn<ResumoReputacaoFornecedorModel> resumoReputacao = Rxn<ResumoReputacaoFornecedorModel>();

  final RxList<InsightFornecedorModel> alertasPerfil = <InsightFornecedorModel>[].obs;

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
  }

  @override
  void onInit() {
    super.onInit();

    Future.delayed(Duration.zero, () {
      appController = Get.find<AppController>();
      ever(appController.usuarioLogado, (usuario) async {
        carregarTodosFornecedores();
      });
    });
  }

  Future<void> ouvirMensagensNaoLidas(String idFornecedor) async {
    if (idFornecedor.trim().isEmpty) return;

    debugPrint('\n📡 [MSG] Iniciando listener de mensagens NÃO lidas para $idFornecedor');

    await _fornecedorCotacoesSub?.cancel();
    for (final listener in _mensagemListeners) {
      await listener.cancel();
    }
    _mensagemListeners.clear();
    _mensagensNaoLidasPorCotacao.clear();
    mensagensNaoLidas.value = 0;

    _fornecedorCotacoesSub = FirebaseFirestore.instance
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((fornecedorSnap) async {
      final cotacoesAtuais = <String>{};

      for (final f in fornecedorSnap.docs) {
        final cotacaoRef = f.reference.parent.parent;
        if (cotacaoRef == null) continue;

        final idCotacao = cotacaoRef.id;
        cotacoesAtuais.add(idCotacao);

        if (_mensagensNaoLidasPorCotacao.containsKey(idCotacao)) {
          continue;
        }

        _mensagensNaoLidasPorCotacao[idCotacao] = 0;

        final sub = cotacaoRef
            .collection('fornecedores')
            .doc(idFornecedor)
            .collection('mensagens')
            .where('id_usuario', isNotEqualTo: idFornecedor)
            .where('lido', isEqualTo: false)
            .snapshots()
            .listen((msgSnap) {
          _mensagensNaoLidasPorCotacao[idCotacao] = msgSnap.docs.length;
          mensagensNaoLidas.value =
              _mensagensNaoLidasPorCotacao.values.fold<int>(0, (total, item) => total + item);
        }, onError: (e) {
          debugPrint('❌ Erro ao escutar mensagens da cotação $idCotacao: $e');
        });

        _mensagemListeners.add(sub);
      }

      final removidas = _mensagensNaoLidasPorCotacao.keys
          .where((idCotacao) => !cotacoesAtuais.contains(idCotacao))
          .toList();
      for (final idCotacao in removidas) {
        _mensagensNaoLidasPorCotacao.remove(idCotacao);
      }
      mensagensNaoLidas.value =
          _mensagensNaoLidasPorCotacao.values.fold<int>(0, (total, item) => total + item);
    }, onError: (e) {
      debugPrint('❌ Erro ao escutar cotações do fornecedor para mensagens: $e');
    });
  }

  /// 🟢 Inicia o listener do fornecedor logado
  void iniciarListenerFornecedor(String idFornecedor) {
    final db = FirebaseFirestore.instance;

    print('📡 Iniciando listener para fornecedor $idFornecedor...');

    // Cancela qualquer listener anterior
    _fornecedorSubscription?.cancel();

    _fornecedorSubscription = db
        .collection('fornecedor')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('ativo', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        fornecedor.value = FornecedorModel.fromMap(data);
        print('✅ Fornecedor atualizado: ${fornecedor.value!.razaoSocial}');
        carregarAiFornecedorComDadosAtuais();
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
    final db = FirebaseFirestore.instance;

    try {
      // 1️⃣ Buscar todas as categorias vinculadas ao fornecedor
      final catSnap = await db
          .collection('fornecedor_categoria')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      if (catSnap.docs.isEmpty) return [];

      // 2️⃣ Extrair todas as subcategorias (agora dentro do mesmo documento)
      final List<String> subcategoriasIds = [];
      for (var doc in catSnap.docs) {
        final data = doc.data();
        final subs = (data['subcategorias'] as List?)
                ?.map((s) => s['idSubcategoria']?.toString())
                .whereType<String>()
                .toList() ??
            [];
        subcategoriasIds.addAll(subs);
      }

      if (subcategoriasIds.isEmpty) return [];

      // 3️⃣ Buscar os serviços/produtos vinculados às subcategorias
      final servSnap = await db
          .collection('servico_produto')
          .where('id_subcategoria', whereIn: subcategoriasIds)
          .where('ativo', isEqualTo: true)
          .get();

      // 4️⃣ Converter o resultado em lista de modelos
      final servicos =
          servSnap.docs.map((d) => ServicoProdutoModel.fromMap({'id': d.id, ...d.data()})).toList();

      return servicos;
    } catch (e, s) {
      debugPrint('Erro ao buscar serviços do fornecedor: $e\n$s');
      return [];
    }
  }

  /// 🔹 Atualiza os dados de um fornecedor existente no Firestore
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) async {
    try {
      await _db.collection('fornecedor').doc(fornecedor.idFornecedor).update(fornecedor.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar fornecedor: $e");
    }
  }

  /// 🔹 Faz upload de imagem para o Firebase Storage e retorna a URL pública
  Future<String> uploadBanner(File imageFile, {Uint8List? bytesWeb}) async {
    try {
      final String fileName =
          'banners_fornecedores/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Erro ao enviar banner: $e");
    }
  }

  Future<void> carregarTodosFornecedores() async {
    try {
      carregando.value = true;
      erro.value = '';

      // ================================
      // 🔸 Fornecedores
      // ================================
      final fornecedoresSnap = await _db.collection('fornecedor').get();
      final listaFornecedores =
          fornecedoresSnap.docs.map((d) => FornecedorModel.fromMap(d.data())).toList();

      // ✅ ORDENAR: aprovados > pendentes > desativados, e nome A-Z
      listaFornecedores.sort((a, b) {
        // 1️⃣ Status ativo primeiro
        if (a.ativo != b.ativo) return b.ativo ? 1 : -1;

        // 2️⃣ Depois, aprovados primeiro
        if (a.aptoParaOperar != b.aptoParaOperar) return b.aptoParaOperar ? 1 : -1;

        // 3️⃣ Por fim, ordem alfabética
        return a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase());
      });

      fornecedores.value = listaFornecedores;

      // ================================
      // 🔸 Endereços (subcoleção)
      // ================================
      final endSnap = await _db.collectionGroup('enderecos').get();
      enderecos.value = endSnap.docs.map((d) => EnderecoUsuarioModel.fromMap(d.data())).toList();

      // ================================
      // 🔸 Categorias do fornecedor
      // ================================
      final catSnap = await _db.collection('fornecedor_categoria').get();
      categoriasFornecedor.value =
          catSnap.docs.map((d) => FornecedorCategoriaModel.fromMap(d.data())).toList();

      // ================================
      // 🔸 Categorias principais
      // ================================
      final catServSnap = await _db.collection('categoria_servico').get();
      categoriasServico.value = catServSnap.docs
          .map((d) => {
                'id': d['id'],
                'nome': d['nome'],
                'descricao': d['descricao'],
                'ativo': d['ativo'],
              })
          .toList();

      categorias.value =
          catServSnap.docs.map((d) => CategoriaServicoModel.fromMap(d.data())).toList();

      // ================================
      // 🔸 Subcategorias
      // ================================
      final subcatSnap = await _db.collection('subcategoria_servico').get();
      subcategoriasServico.value = subcatSnap.docs
          .map((d) => {
                'id': d['id'],
                'nome': d['nome'],
                'id_categoria': d['id_categoria'],
                'descricao': d['descricao'],
                'ativo': d['ativo'],
              })
          .toList();

      subCategorias.value =
          subcatSnap.docs.map((d) => SubcategoriaServicoModel.fromMap(d.data())).toList();

      final servicosSnap = await _db.collection('fornecedor_servico').get();

      final listaServicos = servicosSnap.docs.map((doc) {
        final data = doc.data();
        final idDoc = doc.id;

        // 🔹 Captura os dois padrões de campos (camelCase e snake_case)
        final idFornecedor = data['id_fornecedor'] ?? data['idFornecedor'] ?? '';
        final idProdutoServico = data['id_produto_servico'] ?? data['idProdutoServico'] ?? '';
        final idSubcategoria = data['id_subcategoria'] ?? data['idSubcategoria'];
        final preco = (data['preco'] as num?)?.toDouble() ?? 0.0;
        final precoPromocao = (data['preco_promocao'] as num?)?.toDouble();
        final ativo = data['ativo'] ?? true;

        return FornecedorProdutoServicoModel(
          id: idDoc, // ✅ usa o ID real do documento Firestore
          idFornecedor: idFornecedor,
          idProdutoServico: idProdutoServico,
          idSubcategoria: idSubcategoria,
          preco: preco,
          precoPromocao: precoPromocao,
          ativo: ativo,
          dataCadastro: FornecedorProdutoServicoModel.toDateTime(data['data_cadastro']),
        );
      }).toList();

      allServicosFornecedor.assignAll(listaServicos);
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<FornecedorModel?> buscarFornecedor(String idUsuario) async {
    try {
      final snapshot = await _db
          .collection('fornecedor')
          .where('id_usuario', isEqualTo: idUsuario)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return FornecedorModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint("❌ Erro ao buscar último evento: $e");
      return null;
    }
  }

  /// 🔹 Escuta em tempo real todas as solicitações com status = 'aguardando'
  Future<void> escutarSolicitacoesPendentes(String? idFornecedor) async {
    if (idFornecedor == null) return;

    // Cancela a escuta anterior, se já existir
    await _solicitacoesSub?.cancel();

    try {
      erro.value = '';

      _solicitacoesSub = _db
          .collectionGroup('fornecedores')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .where('status', isEqualTo: 'aguardando')
          .snapshots()
          .listen((snapshot) {
        // 🔹 Atualiza automaticamente o valor reativo
        solicitacoesPendentes.value = snapshot.docs.length;
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
      final endereco = enderecos.firstWhereOrNull((e) => e.idUsuario == f.idUsuario);
      final cat = categoriasFornecedor
          .firstWhereOrNull((c) => c.idFornecedor == f.idFornecedor)
          ?.idCategoria;

      // 🔹 Avalia filtros
      final matchNome = filtroNome.value.isEmpty ||
          f.razaoSocial.toLowerCase().contains(filtroNome.value.toLowerCase()) ||
          (f.descricao?.toLowerCase().contains(filtroNome.value.toLowerCase()) ?? false) ||
          f.email.toLowerCase().contains(filtroNome.value.toLowerCase());

      final matchCidade = filtroCidade.value == null ||
          (endereco?.nomeCidade?.toLowerCase().contains(filtroCidade.value!.toLowerCase()) ??
              false);

      final matchCategoria = filtroCategoria.value == null || cat == filtroCategoria.value;

      final matchStatusAprovacao =
          filtroAprovado.value == null || f.aptoParaOperar == filtroAprovado.value;

      final matchStatusAtivo = filtroAtivo.value == null || f.ativo == filtroAtivo.value;

      final passou =
          matchNome && matchCidade && matchCategoria && matchStatusAprovacao && matchStatusAtivo;

      return passou;
    }).toList();
    return resultado;
  }

  void ordenarFornecedores() {
    final lista = [...fornecedores];
    switch (ordenacaoSelecionada.value) {
      case 'nome':
        lista.sort((a, b) => a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase()));
        break;
      case 'recentes':
        lista.sort((a, b) => (b.dataCadastro).compareTo(a.dataCadastro));
        break;
      default:
        lista.sort((a, b) {
          if (a.ativo != b.ativo) return b.ativo ? 1 : -1;
          if (a.aptoParaOperar != b.aptoParaOperar) return b.aptoParaOperar ? 1 : -1;
          return a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase());
        });
    }
    fornecedores.assignAll(lista);
  }

  // =============================================================
  // 🔸 Aprovação e desativação
  // =============================================================
  Future<void> aprovarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'apto_para_operar': true});
      final f = fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(aptoParaOperar: true);
      }
    } catch (e) {
      debugPrint('❌ Erro ao aprovar fornecedor $idFornecedor: $e');
    }
  }

  Future<void> desativarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'ativo': false});
      fornecedores.removeWhere((f) => f.idFornecedor == idFornecedor);
    } catch (e) {
      debugPrint('❌ Erro ao desativar fornecedor $idFornecedor: $e');
    }
  }

  Future<void> reprovarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'apto_para_operar': false});
      final f = fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(aptoParaOperar: false);
      }
    } catch (e) {
      debugPrint('❌ Erro ao reprovar fornecedor $idFornecedor: $e');
    }
  }

  Future<void> ativarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'ativo': true});
      final f = fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(ativo: true);
      }
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

      // 🔹 Busca orçamentos relacionados
      final orcamentosSnap =
          await _db.collection('orcamento').where('id_evento', isEqualTo: idEvento).get();

      if (orcamentosSnap.docs.isEmpty) {
        servicosFornecedor.clear();
        return;
      }

      // 🔹 Extrai os IDs dos documentos de fornecedor_servico vinculados ao evento
      final fornecedoresIds = orcamentosSnap.docs
          .map((d) => d.data()['id_servico_fornecido'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // 🚨 Correção: evita erro "whereIn vazio"
      if (fornecedoresIds.isEmpty) {
        servicosFornecedor.clear();
        return;
      }

      // 🚨 Correção: busca usando o ID REAL do documento
      final servicosSnap = await _db
          .collection('fornecedor_servico')
          .where(FieldPath.documentId, whereIn: fornecedoresIds)
          .get();

      final listaServicos = servicosSnap.docs
          .map((d) => FornecedorProdutoServicoModel.fromMap({
                'id': d.id,
                ...d.data(),
              }))
          .toList();

      servicosFornecedor.assignAll(listaServicos);

      // 🔹 Carrega catálogo e fotos
      final idsProdutos = listaServicos.map((s) => s.idProdutoServico).toList();
      await carregarCatalogoServicos();

      for (final fornecedorId in fornecedoresIds) {
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

    await _servicosFornecedorSub?.cancel();

    _servicosFornecedorSub = _db
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((snapshot) async {
      final lista = snapshot.docs
          .map((d) => FornecedorProdutoServicoModel.fromMap({
                'id': d.id,
                ...d.data(),
              }))
          .toList();

      servicosFornecedor.assignAll(lista);

      final ids =
          lista.map((e) => e.idProdutoServico).where((id) => id.trim().isNotEmpty).toSet().toList();

      await carregarCatalogoServicos();
      await carregarFotosServicos(ids, idFornecedor);
      await escutarSolicitacoesPendentes(idFornecedor);
      await ouvirMensagensNaoLidas(idFornecedor);
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

      // 1️⃣ Buscar categorias do fornecedor
      final allSnap = await _db.collection('fornecedor_categoria').get();

      final catDocs = allSnap.docs.where((d) {
        final data = d.data();
        final idForn = (data['id_fornecedor'] ?? '').toString().trim();
        return idForn == idFornecedor.trim();
      }).toList();

      if (catDocs.isEmpty) {
        return;
      }

      // 2️⃣ Mapear subcategorias e vínculos
      final Map<String, String> mapaSubcategorias = {};
      final Map<String, String> mapaCategorias = {};
      final Map<String, String> mapaSubParaCat = {};
      final List<String> subcategoriasIds = [];

      for (var doc in catDocs) {
        final data = doc.data();
        final idCat = (data['id_categoria'] ?? '').toString();
        final nomeCat = (data['nome_categoria'] ?? '').toString();
        mapaCategorias[idCat] = nomeCat;

        final subs = (data['subcategorias'] as List?) ?? [];
        for (final sub in subs) {
          if (sub is Map<String, dynamic>) {
            final idSub = (sub['idSubcategoria'] ?? '').toString();
            final nomeSub = (sub['nomeSubcategoria'] ?? '').toString();
            if (idSub.isNotEmpty) {
              mapaSubcategorias[idSub] = nomeSub;
              mapaSubParaCat[idSub] = idCat;
              subcategoriasIds.add(idSub);
            }
          }
        }
      }

      if (subcategoriasIds.isEmpty) {
        return;
      }

      // 3️⃣ Buscar serviços das subcategorias
      final servSnap = await _db
          .collection('servico_produto')
          .where('id_subcategoria', whereIn: subcategoriasIds)
          .where('ativo', isEqualTo: true)
          .get();

      if (servSnap.docs.isEmpty) {
        return;
      }

      // 4️⃣ Montar lista final
      final List<FornecedorServicoDetalhadoDto> lista = [];

      for (final d in servSnap.docs) {
        final data = d.data();

        final idSub = (data['id_subcategoria'] ?? '').toString();
        final idCat = mapaSubParaCat[idSub] ?? '';
        final nomeServico = (data['nome'] ?? 'Serviço sem nome').toString();
        final descricao = (data['descricao'] ?? '').toString();
        final preco = (data['preco'] as num?)?.toDouble() ?? 0.0;
        final precoPromocao = (data['preco_promocao'] as num?)?.toDouble();
        final ativo = data['ativo'] ?? true;
        final nomeCat = mapaCategorias[idCat] ?? 'Sem categoria';
        final nomeSub = mapaSubcategorias[idSub] ?? 'Sem subcategoria';

        lista.add(FornecedorServicoDetalhadoDto(
            id: d.id,
            idFornecedor: idFornecedor,
            idProdutoServico: d.id, // ✅ correto agora
            idSubcategoria: idSub,
            nomeServico: nomeServico,
            descricaoServico: descricao,
            preco: preco,
            precoPromocao: precoPromocao,
            nomeCategoria: nomeCat,
            nomeSubcategoria: nomeSub,
            ativo: ativo,
            quantidade: 1));
      }

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
    final snapshot = await _db.collection('servico_produto').where('ativo', isEqualTo: true).get();

    final lista = snapshot.docs.map((d) {
      return ServicoProdutoModel.fromMap({
        'id': d.id,
        ...d.data(),
      });
    }).toList();

    catalogoServicos.assignAll(lista);
  }

  // ==========================================================
  // === 🔹 Carrega fotos dos serviços
  // ==========================================================
  Future<void> carregarFotosServicos(List<String> idsProdutoServico, String idFornecedor) async {
    final idsUnicos = idsProdutoServico.where((id) => id.trim().isNotEmpty).toSet().toList();

    if (idsUnicos.isEmpty || idFornecedor.trim().isEmpty) {
      fotosServico.clear();
      return;
    }

    try {
      isLoadingFotos.value = true;
      final List<ServicoFotoModel> fotos = [];

      for (var i = 0; i < idsUnicos.length; i += 30) {
        final fim = (i + 30) > idsUnicos.length ? idsUnicos.length : i + 30;
        final chunk = idsUnicos.sublist(i, fim);

        final snapshot = await _db
            .collection('servico_foto')
            .where('id_produto_servico', whereIn: chunk)
            .where('id_fornecedor', isEqualTo: idFornecedor)
            .get();

        fotos.addAll(snapshot.docs.map((d) => ServicoFotoModel.fromMap(d.data())));
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
    final servicoProduto = buscarServicoPorId(servicoFornecedor.idProdutoServico);
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

      // 🔹 Busca todos os orçamentos do evento
      final orcamentosSnap = await FirebaseFirestore.instance
          .collection('orcamento')
          .where('id_evento', isEqualTo: idEvento)
          .get();

      // 🔹 Extrai IDs válidos dos serviços fornecidos (filtrando nulos)
      final servicoFornecidoIds = orcamentosSnap.docs
          .map((d) => d.data()['id_servico_fornecido'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      if (servicoFornecidoIds.isEmpty) {
        return;
      }

      final fornecedorServicosSnap = await FirebaseFirestore.instance
          .collection('fornecedor_servico')
          .where(FieldPath.documentId, whereIn: servicoFornecidoIds)
          .get();

      // 🔹 Busca fornecedores desses serviços (somente IDs válidos)
      final fornecidoIds = fornecedorServicosSnap.docs
          .map((d) => d.data()['id_fornecedor'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final fornecedoresSnap = await FirebaseFirestore.instance
          .collection('fornecedor')
          .where(FieldPath.documentId, whereIn: fornecidoIds)
          .get();

      fornecedores.assignAll(fornecedoresSnap.docs.map((d) {
        return FornecedorModel.fromMap(d.data());
      }).toList());
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> limparDuplicatasFornecedorCategoria() async {
    final db = FirebaseFirestore.instance;
    print('🧹 Iniciando limpeza da coleção fornecedor_categoria...');

    final snap = await db.collection('fornecedor_categoria').get();
    final docs = snap.docs;

    print('📄 Total de documentos encontrados: ${docs.length}');
    final Map<String, List<QueryDocumentSnapshot>> agrupados = {};

    // 🔹 Agrupa por fornecedor + categoria
    for (final doc in docs) {
      final data = doc.data();
      final fornecedor = data['id_fornecedor'] ?? '';
      final categoria = data['id_categoria'] ?? '';
      if (fornecedor.isEmpty || categoria.isEmpty) continue;

      final chave = '$fornecedor|$categoria';
      agrupados.putIfAbsent(chave, () => []);
      agrupados[chave]!.add(doc);
    }

    int duplicatasRemovidas = 0;

    for (final entry in agrupados.entries) {
      final lista = entry.value;
      if (lista.length <= 1) continue; // ✅ Sem duplicata

      // 🔹 Ordena por data_cadastro (mantém o mais antigo)
      lista.sort((a, b) {
        final da = (a.data() as Map<String, dynamic>)['data_cadastro'];
        final dbt = (b.data() as Map<String, dynamic>)['data_cadastro'];
        return da.toString().compareTo(dbt.toString());
      });

      final principal = lista.first;
      final idPrincipal = principal.id;
      final dataPrincipal = Map<String, dynamic>.from(principal.data() as Map<String, dynamic>);
      final subcategoriasPrincipais =
          List<Map<String, dynamic>>.from(dataPrincipal['subcategorias'] ?? []);

      print('🧩 Unificando duplicatas para fornecedor_categoria [$idPrincipal]');

      // 🔹 Mescla subcategorias das duplicatas
      for (final duplicada in lista.skip(1)) {
        final dataDup = Map<String, dynamic>.from(duplicada.data() as Map<String, dynamic>);
        final subs = List<Map<String, dynamic>>.from(dataDup['subcategorias'] ?? []);

        for (final sub in subs) {
          final idSub = sub['idSubcategoria'];
          final jaExiste = subcategoriasPrincipais.any((s) => s['idSubcategoria'] == idSub);
          if (!jaExiste) {
            subcategoriasPrincipais.add(sub);
            print('   ➕ Subcategoria adicionada: ${sub['nomeSubcategoria']}');
          }
        }

        // 🔹 Remove duplicata
        await db.collection('fornecedor_categoria').doc(duplicada.id).delete();
        duplicatasRemovidas++;
        print('   ❌ Documento duplicado removido: ${duplicada.id}');
      }

      // 🔹 Atualiza documento principal consolidado
      await db.collection('fornecedor_categoria').doc(idPrincipal).update({
        'subcategorias': subcategoriasPrincipais,
        'nome_categoria': dataPrincipal['nome_categoria'] ?? '',
      });

      print(
          '✅ Documento principal atualizado com ${subcategoriasPrincipais.length} subcategorias.');
    }

    print('🧹 Limpeza concluída! Duplicatas removidas: $duplicatasRemovidas');
  }

  // ==========================================================
  // === 🔹 Estatísticas básicas
  // ==========================================================

  Future<void> atualizarEstatisticasFornecedor() async {
    final f = fornecedor.value;
    if (f == null) return;

    try {
      // === 🔹 Solicitações pendentes / em negociação ===
      final orcSnap =
          await _db.collection('orcamento').where('id_fornecedor', isEqualTo: f.idFornecedor).get();

      final pendentes = orcSnap.docs.where((d) {
        final status = d['status']?.toString().toLowerCase();
        return status == 'pendente' || status == 'em_negociacao';
      }).length;
      solicitacoesPendentes.value = pendentes;

      // === 🔹 Serviços ativos ===
      final servSnap = await _db
          .collection('fornecedor_servico')
          .where('id_fornecedor', isEqualTo: f.idFornecedor)
          .where('ativo', isEqualTo: true)
          .get();
      servicosFornecedor
          .assignAll(servSnap.docs.map((d) => FornecedorProdutoServicoModel.fromMap(d.data())));

      // === 🔹 Mensagens não lidas ===
      final msgSnap = await _db
          .collectionGroup('mensagens')
          .where('id_fornecedor', isEqualTo: f.idFornecedor)
          .where('lida', isEqualTo: false)
          .get();
      mensagensNaoLidas.value = msgSnap.docs.length;

      // === 🔹 Avaliação média ===
      final avalSnap = await _db
          .collection('avaliacoes')
          .where('id_fornecedor', isEqualTo: f.idFornecedor)
          .get();

      if (avalSnap.docs.isNotEmpty) {
        final soma = avalSnap.docs.map((d) => (d['nota'] ?? 0).toDouble()).reduce((a, b) => a + b);
        avaliacaoMedia.value = soma / avalSnap.docs.length;
      } else {
        avaliacaoMedia.value = 0;
      }
    } catch (e, s) {
      debugPrint('❌ Erro ao atualizar estatísticas: $e\n$s');
    }
  }

  Future<List<Map<String, dynamic>>> buscarSolicitacoesPendentesDetalhadas() async {
    final f = fornecedor.value;
    if (f == null) return [];

    final resultado = <Map<String, dynamic>>[];

    // 🔹 Busca todos os registros "aguardando" em qualquer cotação
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: f.idFornecedor)
        .where('status', isEqualTo: 'aguardando')
        .get();

    for (final doc in snapshot.docs) {
      final dataFornecedor = doc.data();
      final cotacaoRef = doc.reference.parent.parent; // cotacao/{id}
      if (cotacaoRef == null) continue;

      final cotacaoSnap = await cotacaoRef.get();
      if (!cotacaoSnap.exists) continue;

      final dataCotacao = cotacaoSnap.data() as Map<String, dynamic>;

      resultado.add({
        'idCotacao': cotacaoRef.id,
        'categoriaNome': dataCotacao['categoria_nome'] ?? 'Cotação',
        'descricao': dataCotacao['observacao'] ?? '',
        'dataEnvio': dataCotacao['data_envio'],
        'dataLimite': dataCotacao['data_limite_resposta'],
        'status': dataCotacao['status'],
        'idEvento': dataCotacao['id_evento'],
        'idUsuarioSolicitante': dataCotacao['id_usuario_solicitante'],
        'prazoEntrega': dataFornecedor['prazo_entrega'],
        'condicaoPagamento': dataFornecedor['condicao_pagamento'],
        'observacaoFornecedor': dataFornecedor['observacao_fornecedor'],
        'nomeSolicitante': dataCotacao['nome_usuario_solicitante'],
        'valorEstimadoTotal': dataCotacao['valor_estimado_total'] ?? 0.0,
      });
    }

    return resultado;
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
    if (!forceRefresh && cached != null && cached.respostaSugerida.trim().isNotEmpty) {
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

      final sugestao = await _fornecedorAiGenerativaService.gerarSugestaoRespostaCotacao(
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
      final doc = await _db.collection('evento').doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return EventoModel.fromMap(doc.data()!);
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
      const ['valorEstimadoTotal', 'valor_estimado_total', 'valorReferencia', 'valor_referencia'],
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
        const ['idUsuarioSolicitante', 'id_usuario_solicitante', 'idOrganizador', 'id_organizador'],
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

        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;

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
      servicos.map((s) => '${s.id}:${s.ativo}:${s.preco}:${s.precoPromocao ?? ''}').join('|'),
      cotacoes
          .map((c) => '${c.idCotacao}:${c.statusCotacao ?? ''}:${c.valorReferencia ?? ''}')
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

    if (candidata.prioridade == atual.prioridade && scoreCandidata > scoreAtual) {
      return candidata;
    }

    return atual;
  }

  List<InsightFornecedorModel> _ordenarInsights(
    List<InsightFornecedorModel> insights,
  ) {
    final filtrados = insights.where((item) => item.titulo.trim().isNotEmpty).toList();

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
    final prioridade = reputacao.totalAvaliacoes < 5 || reputacao.mediaGeral < 4 ? 4 : 2;

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
    final idCotacao = (data['idCotacao'] ?? data['id_cotacao'] ?? '').toString();

    if (idCotacao.trim().isEmpty) return null;

    return FornecedorAiCotacaoInput(
      idCotacao: idCotacao,
      idEvento: data['idEvento']?.toString() ?? data['id_evento']?.toString(),
      idFornecedor: fornecedor.value?.idFornecedor,
      idOrganizador:
          data['idUsuarioSolicitante']?.toString() ?? data['id_usuario_solicitante']?.toString(),
      categoriaSolicitada: data['categoriaNome']?.toString() ?? data['categoria_nome']?.toString(),
      mensagemCliente: data['descricao']?.toString() ?? data['observacao']?.toString(),
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
    if (value is Timestamp) return value.toDate();
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
