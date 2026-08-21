import 'package:cloud_firestore/cloud_firestore.dart';

class RankingRemoteDatasource {
  RankingRemoteDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<List<Map<String, dynamic>>> carregarRanking(
    String idSubcategoria,
  ) async {
    final query = await _db
        .collection('fornecedor_servico')
        .where('id_subcategoria', isEqualTo: idSubcategoria)
        .get();

    final ranking = <Map<String, dynamic>>[];

    for (final doc in query.docs) {
      final avaliacoesSnap = await doc.reference.collection('avaliacoes').get();
      if (avaliacoesSnap.docs.isEmpty) continue;

      final notas = avaliacoesSnap.docs
          .map((avaliacao) => (avaliacao.data()['nota'] as num).toDouble())
          .toList();
      final media = notas.reduce((a, b) => a + b) / notas.length;
      final data = doc.data();

      ranking.add({
        'id': doc.id,
        'id_fornecedor': data['id_fornecedor'],
        'id_produto_servico': data['id_produto_servico'],
        'media': media,
        'total': notas.length,
      });
    }

    ranking.sort((a, b) => b['media'].compareTo(a['media']));
    return ranking;
  }
}
