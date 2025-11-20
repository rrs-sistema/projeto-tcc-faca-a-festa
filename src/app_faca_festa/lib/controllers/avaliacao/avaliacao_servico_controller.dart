import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/model.dart';
import './../fornecedor_controller.dart';

class AvaliacaoServicoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lista reativa de avaliações do serviço
  final RxList<Map<String, dynamic>> avaliacoes = <Map<String, dynamic>>[].obs;

  /// Média local apenas para exibição
  final RxDouble mediaNotas = 0.0.obs;

  /// Se o organizador pode ou não avaliar
  final permitidoAvaliarFornecedor = false.obs;

  // ======================================================
  // 1. Carregar avaliações de um serviço
  // ======================================================
  Future<void> carregarAvaliacoes(String idFornecedorServico) async {
    final ref = _db
        .collection('fornecedor_servico')
        .doc(idFornecedorServico)
        .collection('avaliacoes')
        .orderBy('data', descending: true);

    ref.snapshots().listen((snapshot) {
      avaliacoes.value = snapshot.docs.map((doc) => doc.data()).toList();
      _atualizarMedia();
    });
  }

  // ======================================================
  // 1) Avaliações de FORNECEDOR
  //    /fornecedor/{idFornecedor}/avaliacoes
  // ======================================================
  Future<void> carregarAvaliacoesFornecedor(String idFornecedor) async {
    final ref = _db
        .collection('fornecedor')
        .doc(idFornecedor)
        .collection('avaliacoes')
        .orderBy('data', descending: true);

    ref.snapshots().listen((snapshot) {
      avaliacoes.value = snapshot.docs.map((doc) => doc.data()).toList();
      _atualizarMedia();
    });
  }

  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) async {
    final ref = _db.collection('fornecedor').doc(idFornecedor).collection('avaliacoes').doc();

    await ref.set({
      'id': ref.id,
      'id_fornecedor': idFornecedor,
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'nota': nota,
      'comentario': comentario,
      'data': Timestamp.now(),
      'id_evento': idEvento,
      'nome_evento': nomeEvento,
    });

    // Aqui a Cloud Function pode atualizar:
    // - média do fornecedor
    // - selos do fornecedor
    // - ranking por categoria
  }

  // ======================================================
  // 2) Avaliações de SERVIÇO DO FORNECEDOR
  //    /fornecedor_servico/{idFornecedor}_{idServico}/avaliacoes
  // ======================================================
  Future<void> carregarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  }) async {
    final idFornecedorServico = '${idFornecedor}_$idServico';

    final ref = _db
        .collection('fornecedor_servico')
        .doc(idFornecedorServico)
        .collection('avaliacoes')
        .orderBy('data', descending: true);

    ref.snapshots().listen((snapshot) {
      avaliacoes.value = snapshot.docs.map((doc) => doc.data()).toList();
      _atualizarMedia();
    });
  }

  Future<void> adicionarAvaliacaoServico({
    required String idFornecedor,
    required String idServico,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) async {
    final idFornecedorServico = '${idFornecedor}_$idServico';

    final ref = _db
        .collection('fornecedor_servico')
        .doc(idFornecedorServico)
        .collection('avaliacoes')
        .doc();

    await ref.set({
      'id': ref.id,
      'id_fornecedor': idFornecedor,
      'id_servico': idServico,
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'nota': nota,
      'comentario': comentario,
      'data': Timestamp.now(),
      'id_evento': idEvento,
      'nome_evento': nomeEvento,
    });

    // Cloud Function aqui cuida de:
    // - média do serviço
    // - (se quiser) também influenciar a média do fornecedor
  }

  // ======================================================
  // 3) Mantém o mesmo cálculo de média
  // ======================================================
  void _atualizarMedia() {
    if (avaliacoes.isEmpty) {
      mediaNotas.value = 0;
      return;
    }

    final total = avaliacoes.fold<double>(
      0.0,
      (s, item) => s + (item['nota'] ?? 0),
    );

    mediaNotas.value = total / avaliacoes.length;
  }

  // ======================================================
  // 3. Adicionar uma avaliação
  //    (Cloud Functions cuidam de média, selos, ranking, push)
  // ======================================================
  Future<void> adicionarAvaliacao({
    required String idFornecedorServico,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) async {
    final ref = _db
        .collection('fornecedor_servico')
        .doc(idFornecedorServico)
        .collection('avaliacoes')
        .doc();

    await ref.set({
      'id': ref.id,
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'nota': nota,
      'comentario': comentario,
      'data': Timestamp.now(),
      'id_evento': idEvento,
      'nome_evento': nomeEvento,
    });

    /// Cloud Function irá:
    ///  - recalcular média do serviço
    ///  - recalcular média do fornecedor
    ///  - atualizar selos
    ///  - atualizar ranking da categoria
    ///  - enviar push notification
  }

  // ======================================================
  // 4. Verificar se o organizador pode avaliar o fornecedor
  // ======================================================
  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    final db = FirebaseFirestore.instance;

    // 1) CHECA SE ELE JÁ AVALIOU
    final avaliacao = await db
        .collection('avaliacao_fornecedor')
        .where('id_evento', isEqualTo: idEvento)
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (avaliacao.docs.isNotEmpty) return false;

    // 2) CHECA SE PARTICIPOU DA COTAÇÃO
    final cotacoes = await db.collection('cotacao').where('id_evento', isEqualTo: idEvento).get();

    for (var c in cotacoes.docs) {
      final fornecedorSnap = await c.reference.collection('fornecedores').doc(idFornecedor).get();

      if (fornecedorSnap.exists) return true;
    }

    // 3) CHECA SE PARTICIPOU DE ORÇAMENTO
    final orcamentos = await db
        .collection('orcamento')
        .where('id_evento', isEqualTo: idEvento)
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    if (orcamentos.docs.isNotEmpty) return true;

    return false;
  }

  Future<bool> podeAvaliarCotacao({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    // 1) Verifica se já avaliou
    final jaAvaliou = await _db
        .collection('avaliacao_fornecedor')
        .where('id_evento', isEqualTo: idEvento)
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (jaAvaliou.docs.isNotEmpty) return false;

    // 2) Verifica se essa cotação tem resposta OU recusa OU cancelamento
    return true; // avaliação permitida para qualquer interação real
  }

  // ======================================================
  // 5. Ranking da categoria (somente leitura)
  // ======================================================
  Future<List<FornecedorModel>> getRankingCategoria(String idCategoria) async {
    final fornecedorController = Get.find<FornecedorController>();

    final fornecedoresDaCategoria = fornecedorController.fornecedores
        .where((f) => f.categorias.any((c) => c['idCategoria'] == idCategoria))
        .toList();

    if (fornecedoresDaCategoria.isEmpty) return [];

    final validos = fornecedoresDaCategoria.where((f) => f.totalAvaliacoes >= 3).toList();

    if (validos.isEmpty) return [];

    validos.sort((a, b) => b.mediaAvaliacoes.compareTo(a.mediaAvaliacoes));

    return validos;
  }

  List<String> getSelosFornecedor(FornecedorModel fornecedor) {
    final selos = <String>[];

    final media = fornecedor.mediaAvaliacoes;
    final total = fornecedor.totalAvaliacoes;

    if (media >= 4.8 && total >= 8) {
      selos.add("Fornecedor 5 Estrelas");
    }

    if (media >= 4.5 && total >= 5) {
      selos.add("Premium");
    }

    if (media >= 4.0 && total >= 3) {
      selos.add("Muito Recomendado");
    }

    if (fornecedor.isTopCategoria == true) {
      selos.add("Top da Categoria");
    }

    return selos;
  }

  String? getSeloRanking(int posicao) {
    switch (posicao) {
      case 1:
        return "🥇 Ouro";
      case 2:
      case 3:
        return "🥈 Prata";
      case 4:
      case 5:
        return "🥉 Bronze";
    }
    return null;
  }
}
