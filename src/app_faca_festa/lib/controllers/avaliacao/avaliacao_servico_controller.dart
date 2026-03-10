import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/model.dart';

class AvaliacaoServicoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ======================================================
  // 🔹 1. Avaliações do SERVIÇO
  // ======================================================
  final RxList<Map<String, dynamic>> avaliacoesServico = <Map<String, dynamic>>[].obs;
  final RxDouble mediaServico = 0.0.obs;

  // ======================================================
  // 🔹 2. Avaliações do FORNECEDOR
  // ======================================================
  final RxList<Map<String, dynamic>> avaliacoesFornecedor = <Map<String, dynamic>>[].obs;
  final RxDouble mediaFornecedor = 0.0.obs;

  /// Controle se o organizador pode avaliar ou não
  final permitidoAvaliarFornecedor = false.obs;

  // ======================================================
  // 1) CARREGAR AVALIAÇÕES DO SERVIÇO
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
      avaliacoesServico.value = snapshot.docs.map((doc) => doc.data()).toList();

      _calcularMediaServico();
    });
  }

  void _calcularMediaServico() {
    if (avaliacoesServico.isEmpty) {
      mediaServico.value = 0;
      return;
    }

    final total = avaliacoesServico.fold<double>(
      0.0,
      (s, item) => s + (item['nota'] ?? 0),
    );

    mediaServico.value = total / avaliacoesServico.length;
  }

  Future<double> getMediaServico({
    required String idFornecedor,
    required String idServico,
  }) async {
    final idFornecedorServico = '${idFornecedor}_$idServico';

    final snap = await _db
        .collection('fornecedor_servico')
        .doc(idFornecedorServico)
        .collection('avaliacoes')
        .get();

    if (snap.docs.isEmpty) return 0;

    double soma = 0;
    for (var d in snap.docs) {
      soma += (d['nota'] ?? 0);
    }

    return soma / snap.docs.length;
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
  }

  // ======================================================
  // 2) CARREGAR AVALIAÇÕES DO FORNECEDOR
  //    /fornecedor/{idFornecedor}/avaliacoes
  // ======================================================
  Future<void> carregarAvaliacoesFornecedor(String idFornecedor) async {
    final ref = _db
        .collection('fornecedor')
        .doc(idFornecedor)
        .collection('avaliacoes')
        .orderBy('data', descending: true);

    ref.snapshots().listen((snapshot) {
      avaliacoesFornecedor.value = snapshot.docs.map((doc) => doc.data()).toList();

      _calcularMediaFornecedor();
    });
  }

  void _calcularMediaFornecedor() {
    if (avaliacoesFornecedor.isEmpty) {
      mediaFornecedor.value = 0;
      return;
    }

    final total = avaliacoesFornecedor.fold<double>(
      0.0,
      (s, item) => s + (item['nota'] ?? 0),
    );

    mediaFornecedor.value = total / avaliacoesFornecedor.length;
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
  }

  // ======================================================
  // 3) Permissões e validações (manteve igual)
  // ======================================================

  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    // Mesmo código anterior...
    final avaliacao = await _db
        .collection('avaliacao_fornecedor')
        .where('id_evento', isEqualTo: idEvento)
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (avaliacao.docs.isNotEmpty) return false;

    final cotacoes = await _db.collection('cotacao').where('id_evento', isEqualTo: idEvento).get();

    for (var c in cotacoes.docs) {
      final fornecedorSnap = await c.reference.collection('fornecedores').doc(idFornecedor).get();

      if (fornecedorSnap.exists) return true;
    }

    final orcamentos = await _db
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
    final jaAvaliou = await _db
        .collection('avaliacao_fornecedor')
        .where('id_evento', isEqualTo: idEvento)
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (jaAvaliou.docs.isNotEmpty) return false;

    return true;
  }

  // ======================================================
  // 4) Selos, ranking, etc. (mantido igual)
  // ======================================================

  List<String> getSelosFornecedor(FornecedorModel fornecedor) {
    final selos = <String>[];

    final media = fornecedor.mediaAvaliacoes;
    final total = fornecedor.totalAvaliacoes;

    if (media >= 4.8 && total >= 8) selos.add("Fornecedor 5 Estrelas");
    if (media >= 4.5 && total >= 5) selos.add("Premium");
    if (media >= 4.0 && total >= 3) selos.add("Muito Recomendado");
    if (fornecedor.isTopCategoria == true) selos.add("Top da Categoria");

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
