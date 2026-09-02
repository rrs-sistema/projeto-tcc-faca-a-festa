import 'package:get/get.dart';

import 'package:app_faca_festa/domain/usecases/carregar_ranking_servicos.dart';

class RankingController extends GetxController {
  RankingController({required CarregarRankingServicos carregarRankingServicos})
      : _carregarRankingServicos = carregarRankingServicos;

  final CarregarRankingServicos _carregarRankingServicos;
  final RxList<Map<String, dynamic>> ranking = <Map<String, dynamic>>[].obs;

  /// Carrega ranking dos serviços de uma subcategoria
  Future<void> carregarRanking(String idSubcategoria) async {
    ranking.clear();
    ranking.value = await _carregarRankingServicos(idSubcategoria);
  }
}
