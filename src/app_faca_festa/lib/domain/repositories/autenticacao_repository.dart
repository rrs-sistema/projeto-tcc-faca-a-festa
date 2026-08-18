class AutenticacaoException implements Exception {
  const AutenticacaoException(this.codigo);

  final String codigo;

  bool get foiCancelada => autenticacaoFoiCancelada(codigo);
}

/// Indica que o usuário fechou o provedor Google sem escolher uma conta.
bool autenticacaoFoiCancelada(String codigo) {
  switch (codigo) {
    case 'canceled':
    case 'web-context-canceled':
    case 'ERROR_WEB_CONTEXT_CANCELED':
    case 'popup-closed-by-user':
      return true;
    default:
      return false;
  }
}

class SessaoUsuario {
  const SessaoUsuario({required this.idUsuario, this.email});

  final String idUsuario;
  final String? email;
}

abstract interface class AutenticacaoRepository {
  String? get idUsuarioAtual;

  String? get emailUsuarioAtual;

  Stream<SessaoUsuario?> observarSessao();

  Future<void> entrar({
    required String email,
    required String senha,
  });

  /// `true` se o usuário autenticou. `false` se fechou o seletor sem escolher conta.
  Future<bool> entrarComGoogle();

  Future<String> criarUsuario({
    required String email,
    required String senha,
  });

  Future<void> sair();
}
