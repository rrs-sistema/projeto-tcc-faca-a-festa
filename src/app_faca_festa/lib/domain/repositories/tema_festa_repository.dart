import '../../data/models/evento/tema_festa_model.dart';

abstract class TemaFestaRepository {
  Future<List<TemaFestaModel>> carregar();

  Future<TemaFestaModel?> buscarPorId(String idTema);

  Future<void> salvar(TemaFestaModel tema);

  Future<void> excluir(String idTema);

  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  });

  Future<void> removerCapaStorage({required String idTema});

  Future<void> popularTemasIniciais({
    required List<TemaFestaModel> temasIniciais,
    required List<TemaFestaModel> temasExistentes,
  });
}
