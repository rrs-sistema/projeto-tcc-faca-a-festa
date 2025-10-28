// ================================
// 🔹 Controller reativo GetX
// ================================
import 'dart:async';
import 'dart:io';

import 'package:app_faca_festa/data/models/servico_produto/subcategoria_servico_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/servico_produto/categoria_servico_model.dart';
import '../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../data/models/servico_produto/servico_foto.dart';
import '../presentation/dialogs/show_novo_orcamento_bottom_sheet.dart';
import './../data/models/model.dart';
import 'app_controller.dart';

class FornecedorController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🔹 Dados principais do fornecedor logado
  final Rx<FornecedorModel?> fornecedor = Rx<FornecedorModel?>(null);
  final RxList<FornecedorModel> fornecedores = <FornecedorModel>[].obs;

  /// 🔹 Serviços (coleção `fornecedor_servico`)
  final RxList<FornecedorProdutoServicoModel> servicosFornecedor =
      <FornecedorProdutoServicoModel>[].obs;

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

  //tempoMedioResposta

  final isLoadingServicos = false.obs;
  final isLoadingFotos = false.obs;

  StreamSubscription? _solicitacoesSub;

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

  /// 🔹 Atualiza os dados de um fornecedor existente no Firestore
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) async {
    try {
      await _db.collection('fornecedor').doc(fornecedor.idFornecedor).update(fornecedor.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar fornecedor: $e");
    }
  }

  /// 🔹 Faz upload de imagem para o Firebase Storage e retorna a URL pública
  Future<String> uploadBanner(File imageFile) async {
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

      final listaServicos =
          servicosSnap.docs.map((d) => FornecedorProdutoServicoModel.fromMap(d.data())).toList();

      allServicosFornecedor.assignAll(listaServicos);
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
      debugPrint('❌ [FornecedorController] Erro: $e');
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
  Future<void> escutarSolicitacoesPendentes() async {
    final f = fornecedor.value;
    if (f == null) return;

    // Cancela a escuta anterior, se já existir
    await _solicitacoesSub?.cancel();

    try {
      erro.value = '';

      _solicitacoesSub = _db
          .collectionGroup('fornecedores')
          .where('id_fornecedor', isEqualTo: f.idFornecedor)
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
  // === 🔹 Carrega o fornecedor logado
  // ==========================================================
  // ==========================================================
  // === 🔹 1. Busca produtos do fornecedor pelo CÓDIGO DO EVENTO
  // ==========================================================
  Future<void> carregarServicosPorEvento(String idEvento) async {
    try {
      carregando.value = true;
      erro.value = '';

      // 🔹 Busca orçamentos relacionados a esse evento
      final orcamentosSnap =
          await _db.collection('orcamento').where('id_evento', isEqualTo: idEvento).get();

      if (orcamentosSnap.docs.isEmpty) {
        servicosFornecedor.clear();
        return;
      }

// 🔹 Extrai IDs válidos dos serviços fornecidos (filtrando nulos)
      final fornecedoresIds = orcamentosSnap.docs
          .map((d) => d.data()['id_servico_fornecido'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // 🔹 Busca todos os serviços que pertencem a esses fornecedores
      final servicosSnap = await _db
          .collection('fornecedor_servico')
          .where('id_fornecedor_servico', whereIn: fornecedoresIds)
          .get();

      final listaServicos =
          servicosSnap.docs.map((d) => FornecedorProdutoServicoModel.fromMap(d.data())).toList();

      servicosFornecedor.assignAll(listaServicos);

      // 🔹 Carrega o catálogo de produtos relacionados
      final idsProdutos = listaServicos.map((s) => s.idProdutoServico).toList();
      await carregarCatalogoServicos();

      // 🔹 (Opcional) Carrega as fotos
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
    if (idFornecedor.isEmpty) return;

    _db
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((snapshot) async {
      final lista =
          snapshot.docs.map((d) => FornecedorProdutoServicoModel.fromMap(d.data())).toList();

      servicosFornecedor.assignAll(lista);

      final ids = lista.map((e) => e.idProdutoServico).toList();
      await carregarCatalogoServicos();
      await carregarFotosServicos(ids, idFornecedor);
      await escutarSolicitacoesPendentes();
    });
  }

  Future<void> listarServicosFornecedor(String idFornecedor) async {
    try {
      carregando.value = true;
      erro.value = '';

      final snapshot = await _db
          .collection('fornecedor_servico')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      servicosFornecedor.value =
          snapshot.docs.map((d) => FornecedorProdutoServicoModel.fromMap(d.data())).toList();
    } catch (e) {
      erro.value = 'Erro ao carregar serviços: $e';
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
    if (idsProdutoServico.isEmpty) return;

    try {
      isLoadingFotos.value = true;

      final snapshot = await _db
          .collection('servico_foto')
          .where('id_produto_servico', whereIn: idsProdutoServico)
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      final lista = snapshot.docs.map((d) => ServicoFotoModel.fromMap(d.data())).toList();
      fotosServico.assignAll(lista);
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar fotos: $e');
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
    String acao = 'solicitar', // 👈 padrão
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
        statusInicial: statusInicial, // 👈 envia o enum
        idOrcamento: idOrcamento);
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

  Future<void> vincularServico(FornecedorProdutoServicoModel model) async {
    await _db.collection('fornecedor_servico').doc(model.id).set(model.toMap());
    await escutarServicosFornecedor(model.idFornecedor);
  }

  Future<void> excluirVinculo(String id) async {
    await _db.collection('fornecedor_servico').doc(id).delete();
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
      });
    }

    return resultado;
  }

  @override
  void onClose() {
    _solicitacoesSub?.cancel();
    super.onClose();
  }
}
