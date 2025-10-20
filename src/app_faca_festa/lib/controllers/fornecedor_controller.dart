// ================================
// 🔹 Controller reativo GetX
// ================================
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../data/models/servico_produto/servico_foto.dart';
import '../presentation/dialogs/show_novo_orcamento_bottom_sheet.dart';
import './../data/models/model.dart';
import 'app_controller.dart';

class FornecedorController extends GetxController {
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _orcamentoSubscription;

  /// 🔹 Dados principais do fornecedor logado
  final Rx<FornecedorModel?> fornecedor = Rx<FornecedorModel?>(null);
  final RxList<FornecedorModel> fornecedores = <FornecedorModel>[].obs;

  /// 🔹 Serviços (coleção `fornecedor_servico`)
  final RxList<FornecedorProdutoServicoModel> servicosFornecedor =
      <FornecedorProdutoServicoModel>[].obs;

  /// 🔹 Catálogo global (`servico_produto`)
  final RxList<ServicoProdutoModel> catalogoServicos = <ServicoProdutoModel>[].obs;

  /// 🔹 Fotos dos serviços (`servico_foto`)
  final RxList<ServicoFotoModel> fotosServico = <ServicoFotoModel>[].obs;

  final RxList<OrcamentoModel> orcamentos = <OrcamentoModel>[].obs;

  /// 🔹 Estatísticas do painel
  final RxInt solicitacoesPendentes = 0.obs;
  final RxInt mensagensNaoLidas = 0.obs;
  final RxDouble avaliacaoMedia = 0.0.obs;
  final RxDouble faturamentoMes = 0.0.obs;

  /// 🔹 Estado geral
  final RxBool aptoParaOperar = false.obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;
  final app = Get.find<AppController>();

  final filtroNome = ''.obs;
  final filtroCidade = RxnString();
  final filtroCategoria = RxnString();
  final filtroAprovado = RxnBool();

  final filtroAvaliacaoMinima = 0.0.obs;
  // 🔹 Dados auxiliares carregados de outras coleções
  final enderecos = <EnderecoUsuarioModel>[].obs;
  final categoriasFornecedor = <FornecedorCategoriaModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // 🔹 Escuta o usuário logado — carrega o fornecedor quando mudar
    ever(app.usuarioLogado, (usuario) {
      if (usuario != null && usuario.idUsuario.isNotEmpty) {
        carregarFornecedorLogado(usuario.idUsuario);
      }
    });
  }

  Future<void> carregarTodosFornecedores() async {
    try {
      carregando.value = true;
      erro.value = '';

      final snapshot = await _db.collection('fornecedor').get();

      fornecedores.value = snapshot.docs.map((d) => FornecedorModel.fromMap(d.data())).toList();

      fornecedoresFiltrados; // Chama o filtro
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> carregarFornecedoresComFiltros({
    bool? ativo,
    bool? aptoParaOperar,
  }) async {
    try {
      carregando.value = true;
      erro.value = '';

      Query query = _db.collection('fornecedor');

      if (ativo != null) query = query.where('ativo', isEqualTo: ativo);
      if (aptoParaOperar != null) {
        query = query.where('apto_para_operar', isEqualTo: aptoParaOperar);
      }

      final snapshot = await query.get();

      fornecedores.value = snapshot.docs
          .map((d) => FornecedorModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      erro.value = 'Erro ao filtrar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> aprovarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({
        'apto_para_operar': true,
        'ativo': true,
      });
      await carregarTodosFornecedores();
      Get.snackbar('Fornecedor aprovado', 'O fornecedor foi liberado para operar.',
          backgroundColor: Colors.green.shade100);
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao aprovar fornecedor: $e', backgroundColor: Colors.red.shade100);
    }
  }

  Future<void> desativarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({
        'ativo': false,
      });
      await carregarTodosFornecedores();
      Get.snackbar('Fornecedor desativado', 'O fornecedor foi desativado com sucesso.',
          backgroundColor: Colors.orange.shade100);
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao desativar fornecedor: $e',
          backgroundColor: Colors.red.shade100);
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
        erro.value = 'Nenhum fornecedor encontrado para este evento.';
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

      if (fornecedoresIds.isEmpty) {
        debugPrint('⚠️ Nenhum serviço de fornecedor vinculado a este evento.');
        return;
      }

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
      await carregarCatalogoServicos(idsProdutos);

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
  // === 🔹 2. Busca produtos pelo CÓDIGO DO FORNECEDOR (login)
  // ==========================================================
  Future<void> carregarFornecedorLogado(String idUsuario) async {
    try {
      carregando.value = true;
      erro.value = '';

      final query = await _db
          .collection('fornecedor')
          .where('id_usuario', isEqualTo: idUsuario)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        erro.value = 'Nenhum fornecedor encontrado para o usuário atual.';
        return;
      }

      fornecedor.value = FornecedorModel.fromMap(query.docs.first.data());
      aptoParaOperar.value = fornecedor.value?.aptoParaOperar ?? false;

      escutarServicosFornecedor(fornecedor.value!.idFornecedor);
    } catch (e, s) {
      erro.value = 'Erro ao carregar fornecedor: $e';
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
      await carregarCatalogoServicos(ids);
      await carregarFotosServicos(ids, idFornecedor);
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
  Future<void> carregarCatalogoServicos(List<String> idsProdutoServico) async {
    if (idsProdutoServico.isEmpty) return;

    final snapshot = await _db
        .collection('servico_produto')
        .where(FieldPath.documentId, whereIn: idsProdutoServico)
        .get();

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

    final snapshot = await _db
        .collection('servico_foto')
        .where('id_produto_servico', whereIn: idsProdutoServico)
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    final lista = snapshot.docs.map((d) => ServicoFotoModel.fromMap(d.data())).toList();
    fotosServico.assignAll(lista);
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
        debugPrint('⚠️ Nenhum serviço de fornecedor vinculado a este evento.');
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

  Future<void> carregarOrcamentosDoEvento(String idEvento) async {
    try {
      // 🔸 Cancela qualquer escuta anterior para evitar duplicação
      await _orcamentoSubscription?.cancel();

      _orcamentoSubscription = _db
          .collection('orcamento')
          .where('id_evento', isEqualTo: idEvento)
          .snapshots()
          .listen((snapshot) async {
        final lista = snapshot.docs.map((d) => OrcamentoModel.fromMap(d.data())).toList();
        orcamentos.assignAll(lista);

        if (lista.isEmpty) {
          servicosFornecedor.clear();
          fornecedores.clear();
          return;
        }

        // 🔹 Busca serviços relacionados (somente IDs válidos)
        final servicoFornecidoIds = lista
            .map((d) => d.idServicoFornecido)
            .where((id) => id != null && id.toString().isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        if (servicoFornecidoIds.isEmpty) {
          debugPrint('⚠️ Nenhum serviço de fornecedor vinculado a este evento.');
          servicosFornecedor.clear();
          fornecedores.clear();
          return;
        }

        // 🔹 Busca os serviços de fornecedor válidos
        final fornecedorServicosSnap = await _db
            .collection('fornecedor_servico')
            .where(FieldPath.documentId, whereIn: servicoFornecidoIds)
            .get();

        final servicosList = fornecedorServicosSnap.docs
            .map((d) => FornecedorProdutoServicoModel.fromMap(d.data()))
            .toList();
        servicosFornecedor.assignAll(servicosList);

        // 🔹 Busca fornecedores desses serviços (somente IDs válidos)
        final fornecidoIds = fornecedorServicosSnap.docs
            .map((d) => d.data()['id_fornecedor'])
            .where((id) => id != null && id.toString().isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        if (fornecidoIds.isEmpty) {
          debugPrint('⚠️ Nenhum fornecedor relacionado encontrado.');
          fornecedores.clear();
          return;
        }

        final fornecedoresSnap = await _db
            .collection('fornecedor')
            .where(FieldPath.documentId, whereIn: fornecidoIds)
            .get();

        fornecedores.assignAll(
          fornecedoresSnap.docs.map((d) => FornecedorModel.fromMap(d.data())).toList(),
        );

        // 🔹 Atualiza catálogo (se necessário)
        final idsProdutos = servicosList.map((s) => s.idProdutoServico).toList();
        await carregarCatalogoServicos(idsProdutos);
      });
    } catch (e, s) {
      debugPrint('❌ Erro ao escutar orçamentos: $e\n$s');
    }
  }

  Future<void> vincularServico(FornecedorProdutoServicoModel model) async {
    await _db.collection('fornecedor_servico').doc(model.idFornecedorServico).set(model.toMap());
    await escutarServicosFornecedor(model.idFornecedor);
  }

  Future<void> excluirVinculo(String id) async {
    await _db.collection('fornecedor_servico').doc(id).delete();
  }

  // ==========================================================
  // === 🔹 Estatísticas básicas
  // ==========================================================
  int get contratadosCount {
    final fechados = orcamentos.where((o) => o.status == StatusOrcamento.fechado).length;
    ('✅ $fechados fornecedores contratados.');
    return fechados;
  }

  // 🔹 Métodos de filtro
  void aplicarFiltros({
    String? nome,
    String? cidade,
    String? categoria,
    bool? aprovado,
  }) {
    filtroNome.value = nome ?? '';
    filtroCidade.value = cidade ?? '';
    filtroCategoria.value = categoria ?? '';
    filtroAprovado.value = aprovado;
  }

  void limparFiltros() {
    filtroNome.value = '';
    filtroCidade.value = '';
    filtroCategoria.value = '';
    filtroAprovado.value = null;
  }

  // 🔹 Retorna lista filtrada combinando dados cruzados
  List<FornecedorModel> get fornecedoresFiltrados {
    return fornecedores.where((f) {
      // 🔹 Busca o endereço do usuário associado ao fornecedor
      final endereco = enderecos.firstWhereOrNull((e) => e.idUsuario == f.idUsuario);

      // 🔹 Busca a categoria vinculada ao fornecedor
      final cat = categoriasFornecedor
          .firstWhereOrNull((c) => c.idFornecedor == f.idFornecedor)
          ?.idCategoria;

      // 🔹 Filtros
      final matchNome = filtroNome.value.isEmpty ||
          f.razaoSocial.toLowerCase().contains(filtroNome.value.toLowerCase()) ||
          (f.descricao?.toLowerCase().contains(filtroNome.value.toLowerCase()) ?? false) ||
          f.email.toLowerCase().contains(filtroNome.value.toLowerCase());

      // ✅ Usa o filtroCidade (RxnString)
      final matchCidade = filtroCidade.value == null ||
          (endereco?.nomeCidade?.toLowerCase().contains(filtroCidade.value!.toLowerCase()) ??
              false);

      // ✅ Usa o filtroCategoria (RxnString)
      final matchCategoria = filtroCategoria.value == null || cat == filtroCategoria.value;

      final matchStatus = filtroAprovado.value == null || f.aptoParaOperar == filtroAprovado.value;

      // ✅ Se todos os critérios combinarem, o fornecedor entra na lista filtrada
      return matchNome && matchCidade && matchCategoria && matchStatus;
    }).toList();
  }

  @override
  void onClose() {
    _orcamentoSubscription?.cancel();
    super.onClose();
  }
}
