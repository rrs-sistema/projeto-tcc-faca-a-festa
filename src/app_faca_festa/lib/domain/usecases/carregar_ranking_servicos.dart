import '../repositories/ranking_repository.dart';

class CarregarRankingServicos {
  CarregarRankingServicos(this.repository);

  final RankingRepository repository;

  Future<List<Map<String, dynamic>>> call(String idSubcategoria) {
    return repository.carregarRanking(idSubcategoria);
  }
}
