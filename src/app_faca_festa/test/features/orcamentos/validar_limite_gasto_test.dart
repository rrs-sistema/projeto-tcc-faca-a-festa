import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/services/validar_limite_gasto.dart';

void main() {
  test('aceita entrada parcial quando o custo total já é o previsto', () {
    final resultado = ValidarLimiteGasto.avaliar(
      custo: 1650,
      pago: 650,
      limiteCategoria: 1650,
      totalPagoCategoria: 0,
      limiteEvento: 5000,
      totalPagoEvento: 500,
    );

    expect(resultado, isNull);
  });

  test('bloqueia quando a soma dos pagamentos passa do previsto', () {
    final resultado = ValidarLimiteGasto.avaliar(
      custo: 1650,
      pago: 650,
      limiteCategoria: 1650,
      totalPagoCategoria: 1200,
      limiteEvento: 5000,
      totalPagoEvento: 1200,
    );

    expect(resultado!.ok, isFalse);
    expect(resultado.mensagem, 'O valor pago excede o previsto da categoria.');
    expect(resultado.excedente, 200);
    expect(resultado.limite, 1650);
  });

  test('bloqueia custo total acima do previsto da categoria', () {
    final resultado = ValidarLimiteGasto.avaliar(
      custo: 2000,
      pago: 100,
      limiteCategoria: 1650,
      totalPagoCategoria: 0,
      limiteEvento: 5000,
      totalPagoEvento: 0,
    );

    expect(resultado!.mensagem,
        'O custo total é maior que o previsto da categoria.');
    expect(resultado.excedente, 350);
  });

  test('bloqueia quando o pagamento passa do orçamento do evento', () {
    final resultado = ValidarLimiteGasto.avaliar(
      custo: 1650,
      pago: 650,
      limiteCategoria: 1650,
      totalPagoCategoria: 0,
      limiteEvento: 5000,
      totalPagoEvento: 4500,
    );

    expect(resultado!.mensagem, 'O valor pago excede o orçamento do evento.');
    expect(resultado.excedente, 150);
    expect(resultado.limite, 5000);
  });
}
