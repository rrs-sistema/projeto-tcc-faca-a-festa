abstract final class AppRotasSessao {
  static bool ehTotp(String rota) =>
      rota == '/loginTotp' || rota == '/loginTotpSetup';

  static bool destinoEstavel(String rota) {
    return rota == '/HomeEventScreen' ||
        rota.startsWith('/HomeEventScreen/') ||
        rota == '/welcome' ||
        rota == '/fornecedor' ||
        rota == '/fornecedores' ||
        rota == '/admin' ||
        rota == '/areaconvidado' ||
        rota.startsWith('/areaconvidado') ||
        rota == '/convite' ||
        rota.startsWith('/convite/') ||
        rota == '/conviteNaoEncontrado';
  }

  /// Subtelas abertas com Get.to() (ex.: lista de fornecedores) não são
  /// `/HomeEventScreen`. Sem esta guarda, qualquer revalidação de sessão
  /// manda o usuário de volta à splash e ela fica eterna.
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
