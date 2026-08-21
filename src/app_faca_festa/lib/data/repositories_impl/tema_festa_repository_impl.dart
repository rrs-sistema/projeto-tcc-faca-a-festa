import '../../domain/repositories/tema_festa_repository.dart';
import '../datasources/remote/tema_festa_remote_datasource.dart';
import '../models/evento/tema_festa_model.dart';

class TemaFestaRepositoryImpl implements TemaFestaRepository {
  TemaFestaRepositoryImpl(this.remote);

  final TemaFestaRemoteDatasource remote;

  @override
  Future<List<TemaFestaModel>> carregar() {
    return remote.carregar();
  }

  @override
  Future<TemaFestaModel?> buscarPorId(String idTema) {
    return remote.buscarPorId(idTema);
  }

  @override
  Future<void> salvar(TemaFestaModel tema) {
    return remote.salvar(tema);
  }

  @override
  Future<void> excluir(String idTema) {
    return remote.excluir(idTema);
  }

  @override
  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  }) {
    return remote.enviarCapa(idTema: idTema, bytes: bytes);
  }

  @override
  Future<void> removerCapaStorage({required String idTema}) {
    return remote.removerCapaStorage(idTema: idTema);
  }

  @override
  Future<void> popularTemasIniciais({
    required List<TemaFestaModel> temasIniciais,
    required List<TemaFestaModel> temasExistentes,
  }) {
    return remote.popularTemasIniciais(
      temasIniciais: temasIniciais,
      temasExistentes: temasExistentes,
    );
  }
}
