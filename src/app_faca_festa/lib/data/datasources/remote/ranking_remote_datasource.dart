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
      final data = doc.data();
      final r = data['reputacao_verificada'];
      if (r is! Map || r['schema'] != 2 || (r['quantidade'] as num) <= 0) {
        continue;
      }
      final media = (r['media'] as num).toDouble();
      ranking.add(
        RankingServico(
          id: doc.id,
          idFornecedor: (data['id_fornecedor'] ?? '').toString(),
          idProdutoServico: (data['id_produto_servico'] ?? '').toString(),
          media: media,
          totalAvaliacoes: (r['quantidade'] as num).toInt(),
        ),
      );
    }

    ranking.sort((a, b) => b.media.compareTo(a.media));
    return ranking;
  }
}
