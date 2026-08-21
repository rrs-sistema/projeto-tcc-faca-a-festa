import '../../domain/repositories/admin_territorio_repository.dart';
import '../datasources/remote/admin_territorio_remote_datasource.dart';
import '../models/fornecedor/territorio_model.dart';

class AdminTerritorioRepositoryImpl implements AdminTerritorioRepository {
  AdminTerritorioRepositoryImpl(this.remote);

  final AdminTerritorioRemoteDatasource remote;

  @override
  Future<List<TerritorioModel>> listarTerritorios() {
    return remote.listarTerritorios();
  }

  @override
  Future<void> salvarTerritorio(TerritorioModel territorio) {
    return remote.salvarTerritorio(territorio);
  }

  @override
  Future<void> atualizarAtivo(String idTerritorio, bool ativo) {
    return remote.atualizarAtivo(idTerritorio, ativo);
  }
}
