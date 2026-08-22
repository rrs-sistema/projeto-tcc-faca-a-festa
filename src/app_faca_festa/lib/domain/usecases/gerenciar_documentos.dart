import '../repositories/documento_repository.dart';

class GerenciarDocumentos {
  GerenciarDocumentos(this.repository);

  final DocumentoRepository repository;

  Future<void> excluirDocumento({
    required String colecao,
    required String idDocumento,
  }) {
    return repository.excluirDocumento(
      colecao: colecao,
      idDocumento: idDocumento,
    );
  }
}
