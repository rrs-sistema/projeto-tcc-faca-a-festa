import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/domain/repositories/admin_territorio_repository.dart';
import '../datasources/remote/admin_territorio_remote_datasource.dart';
import '../models/fornecedor/territorio_model.dart';

class AdminTerritorioRepositoryImpl implements AdminTerritorioRepository {
  AdminTerritorioRepositoryImpl(this.remote);

  final AdminTerritorioRemoteDatasource remote;

  @override
  Future<List<Territorio>> listarTerritorios() {
    return UpdateOperations.run(() async {
      return remote.listarTerritorios();
    });
  }

  @override
  Future<void> salvarTerritorio(Territorio territorio) {
    return UpdateOperations.run(() async {
      return remote.salvarTerritorio(TerritorioModel.fromEntity(territorio));
    });
  }

  @override
  Future<void> atualizarAtivo(String idTerritorio, bool ativo) {
    return UpdateOperations.run(() async {
      return remote.atualizarAtivo(idTerritorio, ativo);
    });
  }
}
