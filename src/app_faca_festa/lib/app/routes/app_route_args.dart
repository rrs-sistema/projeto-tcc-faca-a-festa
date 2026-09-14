import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/inspiracao.dart';

class AuthFluxoArgs {
  const AuthFluxoArgs({
    this.tipo = 'O',
    this.conviteToken = '',
  });

  final String tipo;
  final String conviteToken;

  static AuthFluxoArgs? maybeOf(Object? arguments) {
    return arguments is AuthFluxoArgs ? arguments : null;
  }

  static AuthFluxoArgs of(Object? arguments) {
    return maybeOf(arguments) ?? const AuthFluxoArgs();
  }

  String get tipoNormalizado {
    final value = tipo.trim().toUpperCase();
    return value.isEmpty ? 'O' : value;
  }

  bool get ehConvidado => tipoNormalizado == 'C';

  @override
  String toString() {
    return 'AuthFluxoArgs(tipo: $tipoNormalizado, convite: ${conviteToken.trim().isEmpty ? 'nao' : 'sim'})';
  }
}

class TotpMfaArgs {
  const TotpMfaArgs({this.metodo = 'totp'});

  final String metodo;

  static TotpMfaArgs? maybeOf(Object? arguments) {
    return arguments is TotpMfaArgs ? arguments : null;
  }

  bool get ehEmail => metodo.trim().toLowerCase() == 'email';
}

class AreaConvidadoArgs {
  const AreaConvidadoArgs({
    required this.convidado,
    required this.evento,
  });

  final Convidado convidado;
  final Evento evento;

  static AreaConvidadoArgs? maybeOf(Object? arguments) {
    return arguments is AreaConvidadoArgs ? arguments : null;
  }
}

class GerenciarPresentesArgs {
  const GerenciarPresentesArgs({required this.eventoId});

  final String eventoId;

  static GerenciarPresentesArgs? maybeOf(Object? arguments) {
    return arguments is GerenciarPresentesArgs ? arguments : null;
  }
}

class InspiracaoAdminFormArgs {
  const InspiracaoAdminFormArgs({this.inspiracao});

  final Inspiracao? inspiracao;

  static InspiracaoAdminFormArgs? maybeOf(Object? arguments) {
    return arguments is InspiracaoAdminFormArgs ? arguments : null;
  }
}
