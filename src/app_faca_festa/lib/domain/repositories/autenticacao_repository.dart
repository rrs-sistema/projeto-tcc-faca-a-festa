class AutenticacaoException implements Exception {
  const AutenticacaoException(this.codigo);

  final String codigo;
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

  Future<void> entrarComGoogle();

  Future<String> criarUsuario({
    required String email,
    required String senha,
  });

  Future<void> sair();
}
