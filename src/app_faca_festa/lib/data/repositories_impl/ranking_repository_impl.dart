import 'package:app_faca_festa/domain/entities/ranking_servico.dart';
import 'package:app_faca_festa/domain/repositories/ranking_repository.dart';
import '../datasources/remote/ranking_remote_datasource.dart';

class RankingRepositoryImpl implements RankingRepository {
  RankingRepositoryImpl(this.remote);

  final RankingRemoteDatasource remote;

  @override
  Future<List<RankingServico>> carregarRanking(String idSubcategoria) {
    return remote.carregarRanking(idSubcategoria);
  }
}
