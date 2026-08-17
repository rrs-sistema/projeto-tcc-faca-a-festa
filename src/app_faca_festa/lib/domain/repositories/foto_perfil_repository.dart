abstract interface class FotoPerfilRepository {
  Future<String> enviar({
    required String idUsuario,
    required String caminhoArquivo,
    required String nomeArquivo,
  });
}
