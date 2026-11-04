import 'dart:collection';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Argumentos das rotas de estoque e financeiro do fornecedor', () {
    test('extrai o ID do mapa enviado pelo painel, inclusive IdentityMap', () {
      final arguments = HashMap<String, dynamic>.identity()
        ..['idFornecedor'] = ' fornecedor-1 ';

      expect(FornecedorRouteArgs.idFornecedorOf(arguments), 'fornecedor-1');
      expect(
        FornecedorRouteArgs.idFornecedorOf({'idFornecedor': 'fornecedor-2'}),
        'fornecedor-2',
      );
    });

    test('preserva chamadas legadas com ID em texto', () {
      expect(
        FornecedorRouteArgs.idFornecedorOf(' fornecedor-1 '),
        'fornecedor-1',
      );
    });

    test('permite fallback da sessão sem argumento ou com ID inválido', () {
      for (final arguments in <Object?>[
        null,
        '',
        '   ',
        {},
        {'idFornecedor': null},
        {'idFornecedor': '   '},
        {'idFornecedor': {'id': 'fornecedor-1'}},
        {'idFornecedor': 123},
        123,
        ['fornecedor-1'],
      ]) {
        expect(FornecedorRouteArgs.idFornecedorOf(arguments), isNull);
      }
    });
  });
}
