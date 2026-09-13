import '../entities/uf_cidade.dart';
import '../repositories/uf_cidade_repository.dart';

class GerenciarUfsCidades {
  GerenciarUfsCidades(this.repository);

  final UfCidadeRepository repository;

  Future<List<Estado>> carregarEstados() {
    return repository.carregarEstados();
  }

  Future<List<Cidade>> carregarCidades(String idEstado) {
    return repository.carregarCidades(idEstado);
  }
}
