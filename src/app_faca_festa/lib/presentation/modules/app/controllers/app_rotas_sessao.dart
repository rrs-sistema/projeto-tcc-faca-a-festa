abstract final class AppRotasSessao {
  static bool ehTotp(String rota) =>
      rota == '/loginTotp' || rota == '/loginTotpSetup';

  static bool ehConvite(String rota) =>
      rota == '/convite' ||
      rota.startsWith('/convite/') ||
      rota == '/convite-organizador' ||
      rota.startsWith('/convite-organizador/') ||
      rota == '/areaconvidado' ||
      rota.startsWith('/areaconvidado') ||
      rota == '/conviteNaoEncontrado';

  static bool destinoEstavel(String rota) {
    return rota == '/HomeEventScreen' ||
        rota.startsWith('/HomeEventScreen/') ||
        rota == '/welcome' ||
        rota == '/fornecedor' ||
        rota == '/fornecedores' ||
        rota == '/admin' ||
        ehConvite(rota);
  }

  /// Preserva as subtelas abertas pelo usuário durante a revalidação da sessão.
  static bool usuarioJaNavegando(String rota, {required bool temUsuario}) {
    if (!temUsuario) return false;
    if (rota.isEmpty) return false;
    if (rota == '/splash' ||
        rota == '/' ||
        rota == '/notfound' ||
        rota == '/role' ||
        rota == '/login' ||
        rota == '/register' ||
        rota == '/forgotPassword' ||
        ehTotp(rota)) {
      return false;
    }
    return true;
  }
}
