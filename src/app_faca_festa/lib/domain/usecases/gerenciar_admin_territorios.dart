import '../entities/territorio.dart';
import '../repositories/admin_territorio_repository.dart';

class GerenciarAdminTerritorios {
  GerenciarAdminTerritorios(this.repository);

  final AdminTerritorioRepository repository;

  Future<List<Territorio>> listarTerritorios() {
    return repository.listarTerritorios();
  }

  Future<void> salvarTerritorio(Territorio territorio) {
    return repository.salvarTerritorio(territorio);
  }

  Future<void> atualizarAtivo(String idTerritorio, bool ativo) {
    return repository.atualizarAtivo(idTerritorio, ativo);
  }
}
