import 'package:cloud_functions/cloud_functions.dart';

String mensagemFalhaOperacional(Object erro, {required String recurso}) {
  if (erro is FirebaseFunctionsException) {
    if (erro.code == 'unauthenticated') {
      return 'Sua sessão expirou. Entre novamente para continuar.';
    }
    if (erro.code == 'permission-denied') {
      return 'Sua conta não tem permissão para acessar $recurso.';
    }
    if ([
      'invalid-argument',
      'failed-precondition',
      'aborted',
      'already-exists',
      'not-found'
    ].contains(erro.code)) {
      final mensagem = erro.message?.trim();
      if (mensagem != null &&
          mensagem.isNotEmpty &&
          !['internal', 'unknown', 'INTERNAL'].contains(mensagem)) {
        return mensagem;
      }
    }
  }
  return 'Tente novamente em instantes para consultar $recurso.';
}
