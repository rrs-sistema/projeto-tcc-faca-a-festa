import '../../domain/repositories/ranking_repository.dart';
import '../datasources/remote/ranking_remote_datasource.dart';

class RankingRepositoryImpl implements RankingRepository {
  RankingRepositoryImpl(this.remote);

  final RankingRemoteDatasource remote;

  @override
  Future<List<Map<String, dynamic>>> carregarRanking(String idSubcategoria) {
    return remote.carregarRanking(idSubcategoria);
  }
}
