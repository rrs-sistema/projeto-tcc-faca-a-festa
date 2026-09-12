class AbrirConvitePorTokenException implements Exception {
  const AbrirConvitePorTokenException(this.codigo, [this.mensagem]);

  final String codigo;
  final String? mensagem;
}

class AbrirConvitePorTokenResultado {
  const AbrirConvitePorTokenResultado({
    required this.convidado,
    required this.evento,
  });

  final Map<String, dynamic> convidado;
  final Map<String, dynamic> evento;
}

abstract class AbrirConvitePorToken {
  Future<AbrirConvitePorTokenResultado> abrir(String token);
}
