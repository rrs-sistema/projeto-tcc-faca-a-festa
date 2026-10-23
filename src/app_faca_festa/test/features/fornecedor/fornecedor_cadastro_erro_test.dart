import 'package:app_faca_festa/presentation/modules/auth/pages/components/fornecedor_cadastro_erro.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exibe conflitos e validações sem atribuí-los à conexão', () {
    expect(mensagemErroCadastroFornecedor(StateError('Reabra a edição.')),
        'Reabra a edição.');
    final permissoes = mensagemErroCadastroFornecedor(FirebaseException(
        plugin: 'cloud_firestore', code: 'permission-denied'));
    expect(permissoes, contains('não autorizou'));
    expect(permissoes, isNot(contains('conexão')));
  });

  test('distingue sessão expirada, indisponibilidade e conflito', () {
    for (final entrada in {
      'unauthenticated': 'sessão expirou',
      'unavailable': 'conexão',
      'deadline-exceeded': 'confirmar',
      'aborted': 'Reabra',
      'not-found': 'não foi encontrado',
      'transaction_error': 'transaction_error',
    }.entries) {
      expect(
          mensagemErroCadastroFornecedor(
              FirebaseException(plugin: 'cloud_firestore', code: entrada.key)),
          contains(entrada.value));
    }
    expect(mensagemErroCadastroFornecedor(Exception('falha interna')),
        contains('console'));
  });
}
