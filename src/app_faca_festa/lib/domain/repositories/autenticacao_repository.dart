class AutenticacaoException implements Exception {
  const AutenticacaoException(this.codigo, [this.mensagem]);

  final String codigo;
  final String? mensagem;

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

  String? get nomeUsuarioAtual;

  String? get fotoUsuarioAtual;

  Stream<SessaoUsuario?> observarSessao();

  bool get sessaoAnonima;

  bool get contaAtualTemLoginComSenha;

  /// Conta só do convite (anônimo ou token customizado, sem e-mail/Google).
  bool get sessaoVisitanteConvite;

  Future<void> entrarAnonimamente();

  Future<void> entrarComTokenCustomizado(String token);

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

  Future<void> solicitarCodigoRedefinicaoSenha({
    required String email,
  });

  Future<void> redefinirSenhaComCodigo({
    required String email,
    required String codigo,
    required String novaSenha,
  });

  Future<Map<String, dynamic>> iniciarTotpMfa();

  Future<Map<String, dynamic>> solicitarCodigoEmailMfa();

  Future<void> confirmarTotpMfa(String codigo);

  Future<void> confirmarEmailMfa(String codigo);

  Future<void> verificarTotpMfa(String codigo);

  Future<void> verificarEmailMfa(String codigo);

  Future<void> sair();
}
