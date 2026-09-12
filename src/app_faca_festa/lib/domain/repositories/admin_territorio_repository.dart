import '../entities/territorio.dart';

abstract class AdminTerritorioRepository {
  Future<List<Territorio>> listarTerritorios();

  Future<void> salvarTerritorio(Territorio territorio);

  Future<void> atualizarAtivo(String idTerritorio, bool ativo);
}
