import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/ranking_servico.dart';

class RankingRemoteDatasource {
  RankingRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Future<List<RankingServico>> carregarRanking(String idSubcategoria) async {
    final query = await _db
        .collection('fornecedor_servico')
        .where('id_subcategoria', isEqualTo: idSubcategoria)
        .get();

    final ranking = <RankingServico>[];

    for (final doc in query.docs) {
      final avaliacoesSnap = await doc.reference.collection('avaliacoes').get();
      if (avaliacoesSnap.docs.isEmpty) continue;

      final notas = avaliacoesSnap.docs
          .map((avaliacao) => (avaliacao.data()['nota'] as num).toDouble())
          .toList();
      final media = notas.reduce((a, b) => a + b) / notas.length;
      final data = doc.data();

      ranking.add(
        RankingServico(
          id: doc.id,
          idFornecedor: (data['id_fornecedor'] ?? '').toString(),
          idProdutoServico: (data['id_produto_servico'] ?? '').toString(),
          media: media,
          totalAvaliacoes: notas.length,
        ),
      );
    }

    ranking.sort((a, b) => b.media.compareTo(a.media));
    return ranking;
  }
}
