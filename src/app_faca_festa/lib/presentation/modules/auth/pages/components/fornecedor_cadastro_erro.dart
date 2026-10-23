import 'package:firebase_core/firebase_core.dart';

String mensagemErroCadastroFornecedor(Object erro) {
  if (erro is StateError) return erro.message.toString();
  if (erro is FirebaseException) {
    switch (erro.code) {
      case 'permission-denied':
        return 'O servidor não autorizou esta edição. Confira a sessão de administrador e as permissões do cadastro.';
      case 'unauthenticated':
        return 'Sua sessão expirou. Entre novamente para salvar o cadastro.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Não foi possível confirmar o salvamento. Confira a conexão e tente novamente.';
      case 'aborted':
        return 'O cadastro mudou durante a edição. Reabra para revisar os dados atuais.';
      case 'not-found':
        return 'Um registro deste cadastro não foi encontrado. Reabra a edição para atualizar os dados.';
      default:
        return 'Não foi possível salvar o cadastro (código: ${erro.code}). Suas alterações continuam no formulário.';
    }
  }
  return 'Não foi possível salvar o cadastro. Suas alterações continuam no formulário. Consulte o erro registrado no console.';
}
