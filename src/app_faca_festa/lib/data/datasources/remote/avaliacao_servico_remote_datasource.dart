import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AvaliacaoServicoRemoteDatasource {
  AvaliacaoServicoRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> observarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  }) {
    final idFornecedorServico = '${idFornecedor}_$idServico';

    return _db
        .collection('fornecedor_servico')
        .doc(idFornecedorServico)
        .collection('avaliacoes')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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

    var soma = 0.0;
    for (final doc in snap.docs) {
      soma += (doc.data()['nota'] ?? 0);
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
  }) {
    final idFornecedorServico = '${idFornecedor}_$idServico';
    final ref = _db
        .collection('fornecedor_servico')
        .doc(idFornecedorServico)
        .collection('avaliacoes')
        .doc();

    return ref.set({
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

  Stream<List<Map<String, dynamic>>> observarAvaliacoesFornecedor(
    String idFornecedor,
  ) {
    return _db
        .collection('fornecedor')
        .doc(idFornecedor)
        .collection('avaliacoes')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) {
    final ref = _db
        .collection('fornecedor')
        .doc(idFornecedor)
        .collection('avaliacoes')
        .doc();

    return ref.set({
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

  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    try {
      final avaliacao = await _db
          .collection('avaliacao_fornecedor')
          .where('id_evento', isEqualTo: idEvento)
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .where('id_usuario', isEqualTo: idUsuario)
          .limit(1)
          .get();

      if (avaliacao.docs.isNotEmpty) return false;

      // A regra de `cotacao` só libera listagem para o solicitante
      // (`id_usuario_solicitante == uid`). Filtrar só por `id_evento`
      // gera PERMISSION_DENIED e derruba a tela de detalhe.
      final cotacoes = await _db
          .collection('cotacao')
          .where('id_usuario_solicitante', isEqualTo: idUsuario)
          .get();

      for (final cotacao in cotacoes.docs) {
        if (cotacao.data()['id_evento'] != idEvento) continue;

        final fornecedorSnap = await cotacao.reference
            .collection('fornecedores')
            .doc(idFornecedor)
            .get();

        if (fornecedorSnap.exists) return true;
      }

      final orcamentos = await _db
          .collection('orcamento')
          .where('id_evento', isEqualTo: idEvento)
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      return orcamentos.docs.isNotEmpty;
    } catch (e, s) {
      debugPrint('❌ Erro ao verificar se pode avaliar fornecedor: $e\n$s');
      return false;
    }
  }

  Future<bool> podeAvaliarCotacao({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    try {
      final jaAvaliou = await _db
          .collection('avaliacao_fornecedor')
          .where('id_evento', isEqualTo: idEvento)
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .where('id_usuario', isEqualTo: idUsuario)
          .limit(1)
          .get();

      return jaAvaliou.docs.isEmpty;
    } catch (e, s) {
      debugPrint('❌ Erro ao verificar se pode avaliar cotação: $e\n$s');
      return false;
    }
  }
}
