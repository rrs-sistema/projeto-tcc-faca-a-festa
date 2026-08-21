import '../../data/models/fornecedor/territorio_model.dart';
import '../repositories/admin_territorio_repository.dart';

class GerenciarAdminTerritorios {
  GerenciarAdminTerritorios(this.repository);

  final AdminTerritorioRepository repository;

  Future<List<TerritorioModel>> listarTerritorios() {
    return repository.listarTerritorios();
  }

  Future<void> salvarTerritorio(TerritorioModel territorio) {
    return repository.salvarTerritorio(territorio);
  }

  Future<void> atualizarAtivo(String idTerritorio, bool ativo) {
    return repository.atualizarAtivo(idTerritorio, ativo);
  }
}
