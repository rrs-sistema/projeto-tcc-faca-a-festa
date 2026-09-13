import '../entities/uf_cidade.dart';

abstract class UfCidadeRepository {
  Future<List<Estado>> carregarEstados();

  Future<List<Cidade>> carregarCidades(String idEstado);
}
