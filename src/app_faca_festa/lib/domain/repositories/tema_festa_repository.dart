import '../entities/tema_festa.dart';

abstract class TemaFestaRepository {
  Future<List<TemaFesta>> carregar();

  Future<TemaFesta?> buscarPorId(String idTema);

  Future<void> salvar(TemaFesta tema);

  Future<void> excluir(String idTema);

  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  });

  Future<void> removerCapaStorage({required String idTema});

  List<TemaFesta> catalogoInicial();

  Future<void> popularTemasIniciais({
    required List<TemaFesta> temasExistentes,
  });
}
