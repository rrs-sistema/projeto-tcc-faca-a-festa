import 'dart:async';

/// Entrega também erros assíncronos do canal nativo ao chamador da transação.
/// No FlutterFire desktop, uma negativa no commit pode chegar no stream do
/// EventChannel sem completar o Future de runTransaction. O domínio precisa
/// receber essa falha para preservar o cadastro e oferecer nova tentativa.
/// Não repete comandos nem converte falha em sucesso.
Future<T> executarTransacaoFirestore<T>(Future<T> Function() iniciar) {
  final resposta = Completer<T>();
  final origem = Zone.current;
  void falhar(Object erro, StackTrace stack) {
    if (!resposta.isCompleted) {
      resposta.completeError(erro, stack);
    } else {
      origem.handleUncaughtError(erro, stack);
    }
  }

  runZonedGuarded(() async {
    try {
      final resultado = await iniciar();
      if (!resposta.isCompleted) resposta.complete(resultado);
    } catch (erro, stack) {
      falhar(erro, stack);
    }
  }, falhar);
  return resposta.future;
}
