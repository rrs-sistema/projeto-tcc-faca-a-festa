import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/ranking_servico.dart';
import 'package:app_faca_festa/domain/usecases/carregar_ranking_servicos.dart';
import 'package:app_faca_festa/core/conectividade/recarregar_ao_reconectar.dart';

class RankingController extends GetxController
    with RecarregarAoReconectar {
  RankingController({required CarregarRankingServicos carregarRankingServicos})
      : _carregarRankingServicos = carregarRankingServicos;

  final CarregarRankingServicos _carregarRankingServicos;
  final RxList<RankingServico> ranking = <RankingServico>[].obs;

  Future<void> carregarRanking(String idSubcategoria) async {
    repetirAoReconectar('ranking', () => carregarRanking(idSubcategoria));
    ranking.clear();
    ranking.value = await _carregarRankingServicos(idSubcategoria);
  }
}
