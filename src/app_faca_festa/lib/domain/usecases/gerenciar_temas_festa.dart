import '../entities/tema_festa.dart';
import '../repositories/tema_festa_repository.dart';

class GerenciarTemasFesta {
  GerenciarTemasFesta(this.repository);

  final TemaFestaRepository repository;

  Future<List<TemaFesta>> carregar() {
    return repository.carregar();
  }

  Future<TemaFesta?> buscarPorId(String idTema) {
    return repository.buscarPorId(idTema);
  }

  Future<void> salvar(TemaFesta tema) {
    return repository.salvar(tema);
  }

  Future<void> excluir(String idTema) {
    return repository.excluir(idTema);
  }

  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  }) {
    return repository.enviarCapa(idTema: idTema, bytes: bytes);
  }

  Future<void> removerCapaStorage({required String idTema}) {
    return repository.removerCapaStorage(idTema: idTema);
  }

  Future<void> popularTemasIniciais({
    required List<TemaFesta> temasIniciais,
    required List<TemaFesta> temasExistentes,
  }) {
    return repository.popularTemasIniciais(
      temasIniciais: temasIniciais,
      temasExistentes: temasExistentes,
    );
  }
}
