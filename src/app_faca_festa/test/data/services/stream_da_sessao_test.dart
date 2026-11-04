import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/services/stream_da_sessao.dart';

void main() {
  test(
      'troca de sessão limpa o valor, cancela a fonte e ignora resultado antigo',
      () async {
    var cancelada = false;
    final fonte = StreamController<List<int>>(onCancel: () {
      cancelada = true;
    });
    final auth = StreamController<String?>();
    final valores = <List<int>>[];
    final sub = streamDaSessao(
        fonte: fonte.stream,
        sessoes: auth.stream,
        identidade: 'a',
        vazio: <int>[]).listen(valores.add);
    fonte.add([1]);
    await Future<void>.delayed(Duration.zero);
    auth.add('b');
    await Future<void>.delayed(Duration.zero);
    fonte.add([99]);
    await Future<void>.delayed(Duration.zero);
    expect(valores, [
      [1],
      <int>[]
    ]);
    expect(cancelada, isTrue);
    await sub.cancel();
    await fonte.close();
    await auth.close();
  });
  test('cancelamento da tela cancela dados e autenticação', () async {
    var dadosCancelados = false, authCancelada = false;
    final fonte = StreamController<int>(onCancel: () {
      dadosCancelados = true;
    });
    final auth = StreamController<String?>(onCancel: () {
      authCancelada = true;
    });
    final sub = streamDaSessao(
            fonte: fonte.stream,
            sessoes: auth.stream,
            identidade: 'a',
            vazio: 0)
        .listen((_) {});
    await sub.cancel();
    expect(dadosCancelados && authCancelada, isTrue);
    await fonte.close();
    await auth.close();
  });
}
