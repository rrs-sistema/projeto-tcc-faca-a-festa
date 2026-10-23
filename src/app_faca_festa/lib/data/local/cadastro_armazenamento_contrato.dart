abstract interface class ArmazenamentoCadastroLocal {
  Future<Map<String, String>> listar(String prefixo);
  Future<void> gravar(String chave, String valor);
  Future<void> remover(String chave);
}
