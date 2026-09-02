abstract class PushTokenRepository {
  bool get suportaTokenPush;

  Future<void> solicitarPermissao();

  Future<String?> obterTokenAtual();

  Stream<String> observarAtualizacoesToken();
}
