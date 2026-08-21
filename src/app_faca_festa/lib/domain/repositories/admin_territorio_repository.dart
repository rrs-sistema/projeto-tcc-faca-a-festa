import '../../data/models/fornecedor/territorio_model.dart';

abstract class AdminTerritorioRepository {
  Future<List<TerritorioModel>> listarTerritorios();

  Future<void> salvarTerritorio(TerritorioModel territorio);

  Future<void> atualizarAtivo(String idTerritorio, bool ativo);
}
