import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';

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

  final Convidado convidado;
  final Evento evento;
}

abstract class AbrirConvitePorToken {
  Future<AbrirConvitePorTokenResultado> abrir(String token);
}
