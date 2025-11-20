import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class RankingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<Map<String, dynamic>> ranking = <Map<String, dynamic>>[].obs;

  /// Carrega ranking dos serviços de uma subcategoria
  Future<void> carregarRanking(String idSubcategoria) async {
    ranking.clear();

    final query = await _db
        .collection('fornecedor_servico')
        .where('id_subcategoria', isEqualTo: idSubcategoria)
        .get();

    for (var doc in query.docs) {
      final servicoId = doc.id;

      final avaliacoesSnap = await doc.reference.collection('avaliacoes').get();

      if (avaliacoesSnap.docs.isEmpty) continue;

      final notas = avaliacoesSnap.docs.map((d) => (d['nota'] as num).toDouble()).toList();

      final media = notas.reduce((a, b) => a + b) / notas.length;

      ranking.add({
        'id': servicoId,
        'id_fornecedor': doc['id_fornecedor'],
        'id_produto_servico': doc['id_produto_servico'],
        'media': media,
        'total': notas.length,
      });
    }

    // ordenar do melhor para o pior
    ranking.sort((a, b) => b['media'].compareTo(a['media']));
  }
}
