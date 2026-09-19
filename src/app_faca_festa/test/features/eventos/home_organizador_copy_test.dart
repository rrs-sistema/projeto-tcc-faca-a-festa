import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';

void main() {
  group('HomeOrganizadorCopy', () {
    test('resume convidados sem lista', () {
      expect(HomeOrganizadorCopy.convidadosValor(0, 0), '0 na lista');
    });

    test('resume convidados confirmados', () {
      expect(HomeOrganizadorCopy.convidadosValor(3, 12), '3 de 12');
    });

    test('pedidos de preço no plural', () {
      expect(HomeOrganizadorCopy.cotacoesValor(0), 'Nenhum pedido');
      expect(HomeOrganizadorCopy.cotacoesValor(1), '1 pedido');
      expect(HomeOrganizadorCopy.cotacoesValor(4), '4 pedidos');
    });

    test('percentual de orçamento', () {
      expect(HomeOrganizadorCopy.orcamentoPercentual(0.42), '42%');
    });
  });
}
