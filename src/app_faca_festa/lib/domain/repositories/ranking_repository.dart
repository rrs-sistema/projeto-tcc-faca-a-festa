import '../entities/ranking_servico.dart';

abstract class RankingRepository {
  Future<List<RankingServico>> carregarRanking(String idSubcategoria);
}
