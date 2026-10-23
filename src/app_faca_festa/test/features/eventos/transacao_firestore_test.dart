import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/services/transacao_firestore.dart';

void main() {
  test('erro de stream nativo chega ao cadastro sem reexecutar a gravação',
      () async {
    var tentativas = 0;
    final falha = StateError('commit recusado');
    final resultado = executarTransacaoFirestore(() {
      tentativas++;
      // Reproduz EventChannel falhando enquanto o Future nativo fica pendente.
      scheduleMicrotask(() => throw falha);
      return Completer<void>().future;
    });
    await expectLater(resultado, throwsA(same(falha)));
    expect(tentativas, 1);
  });

  test('mantém resultado e erro normal da transação', () async {
    expect(await executarTransacaoFirestore(() async => 42), 42);
    final falha = StateError('sem permissão');
    await expectLater(executarTransacaoFirestore(() async => throw falha),
        throwsA(same(falha)));
  });
}
