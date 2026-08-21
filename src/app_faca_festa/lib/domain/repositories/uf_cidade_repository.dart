abstract class UfCidadeRepository {
  Future<List<Map<String, dynamic>>> carregarEstados();

  Future<List<Map<String, dynamic>>> carregarCidades(String idEstado);
}
