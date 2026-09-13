import '../entities/ranking_servico.dart';
import '../repositories/ranking_repository.dart';

class CarregarRankingServicos {
  CarregarRankingServicos(this.repository);

  final RankingRepository repository;

  Future<List<RankingServico>> call(String idSubcategoria) {
    return repository.carregarRanking(idSubcategoria);
  }
}
