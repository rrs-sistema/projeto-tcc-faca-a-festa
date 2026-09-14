import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';

class AuthFluxoArgs {
  const AuthFluxoArgs({
    this.tipo = 'O',
    this.conviteToken = '',
  });

  final String tipo;
  final String conviteToken;

  String get tipoNormalizado {
    final value = tipo.trim().toUpperCase();
    return value.isEmpty ? 'O' : value;
  }

  bool get ehConvidado => tipoNormalizado == 'C';
}

class TotpMfaArgs {
  const TotpMfaArgs({this.metodo = 'totp'});

  final String metodo;

  bool get ehEmail => metodo.trim().toLowerCase() == 'email';
}

class AreaConvidadoArgs {
  const AreaConvidadoArgs({
    required this.convidado,
    required this.evento,
  });

  final Convidado convidado;
  final Evento evento;
}

class GerenciarPresentesArgs {
  const GerenciarPresentesArgs({required this.eventoId});

  final String eventoId;
}
