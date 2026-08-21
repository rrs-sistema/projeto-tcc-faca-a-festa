import '../../data/models/evento/tema_festa_model.dart';
import '../repositories/tema_festa_repository.dart';

class GerenciarTemasFesta {
  GerenciarTemasFesta(this.repository);

  final TemaFestaRepository repository;

  Future<List<TemaFestaModel>> carregar() {
    return repository.carregar();
  }

  Future<TemaFestaModel?> buscarPorId(String idTema) {
    return repository.buscarPorId(idTema);
  }

  Future<void> salvar(TemaFestaModel tema) {
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
    required List<TemaFestaModel> temasIniciais,
    required List<TemaFestaModel> temasExistentes,
  }) {
    return repository.popularTemasIniciais(
      temasIniciais: temasIniciais,
      temasExistentes: temasExistentes,
    );
  }
}
