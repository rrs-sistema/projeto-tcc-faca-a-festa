import 'dart:async';

/// Encerra a fonte e apaga o último valor quando a identidade muda.
/// Não reassina automaticamente: a nova sessão deve abrir uma nova consulta.
Stream<T> streamDaSessao<T>({
  required Stream<T> fonte,
  required Stream<String?> sessoes,
  required String? identidade,
  required T vazio,
}) {
  late StreamController<T> controller;
  StreamSubscription<T>? dados;
  StreamSubscription<String?>? auth;
  var encerrado = false;
  Future<void> encerrar() async {
    if (encerrado) return;
    encerrado = true;
    controller.add(vazio);
    await dados?.cancel();
    await auth?.cancel();
    await controller.close();
  }

  controller = StreamController<T>(onListen: () {
    auth = sessoes.listen((uid) {
      if (uid != identidade) unawaited(encerrar());
    });
    if (identidade == null) {
      unawaited(encerrar());
      return;
    }
    dados = fonte.listen((valor) {
      if (!encerrado) controller.add(valor);
    }, onError: (Object erro, StackTrace stack) {
      if (!encerrado) controller.addError(erro, stack);
    });
  }, onCancel: () async {
    encerrado = true;
    await dados?.cancel();
    await auth?.cancel();
  });
  return controller.stream;
}
