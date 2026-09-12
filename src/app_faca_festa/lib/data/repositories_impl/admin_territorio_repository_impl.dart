import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/domain/repositories/admin_territorio_repository.dart';
import '../datasources/remote/admin_territorio_remote_datasource.dart';
import '../models/fornecedor/territorio_model.dart' hide Territorio;

class AdminTerritorioRepositoryImpl implements AdminTerritorioRepository {
  AdminTerritorioRepositoryImpl(this.remote);

  final AdminTerritorioRemoteDatasource remote;

  @override
  Future<List<Territorio>> listarTerritorios() {
    return remote.listarTerritorios();
  }

  @override
  Future<void> salvarTerritorio(Territorio territorio) {
    return remote.salvarTerritorio(TerritorioModel.fromEntity(territorio));
  }

  @override
  Future<void> atualizarAtivo(String idTerritorio, bool ativo) {
    return remote.atualizarAtivo(idTerritorio, ativo);
  }
}
