abstract interface class DocumentoRepository {
  Future<void> excluirDocumento({
    required String colecao,
    required String idDocumento,
  });
}
