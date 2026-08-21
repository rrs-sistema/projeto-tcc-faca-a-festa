import 'package:cloud_firestore/cloud_firestore.dart';

class AvaliacaoServicoRemoteDatasource {
  AvaliacaoServicoRemoteDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

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
    final avaliacao = await _db
        .collection('avaliacao_fornecedor')
        .where('id_evento', isEqualTo: idEvento)
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (avaliacao.docs.isNotEmpty) return false;

    final cotacoes = await _db
        .collection('cotacao')
        .where('id_evento', isEqualTo: idEvento)
        .get();

    for (final cotacao in cotacoes.docs) {
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

    return jaAvaliou.docs.isEmpty;
  }
}
