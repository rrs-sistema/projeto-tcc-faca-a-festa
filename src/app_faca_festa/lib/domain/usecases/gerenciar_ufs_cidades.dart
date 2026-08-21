import '../repositories/uf_cidade_repository.dart';

class GerenciarUfsCidades {
  GerenciarUfsCidades(this.repository);

  final UfCidadeRepository repository;

  Future<List<Map<String, dynamic>>> carregarEstados() {
    return repository.carregarEstados();
  }

  Future<List<Map<String, dynamic>>> carregarCidades(String idEstado) {
    return repository.carregarCidades(idEstado);
  }
}
