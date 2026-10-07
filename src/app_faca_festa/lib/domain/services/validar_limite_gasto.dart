import 'package:app_faca_festa/domain/entities/orcamento_validacao_resultado.dart';

/// O previsto da categoria já existe no item. Cada lançamento registra um
/// pagamento em cima desse valor, então o limite vale para a soma do que foi
/// pago — não para somar de novo o custo total a cada entrada.
class ValidarLimiteGasto {
  const ValidarLimiteGasto._();

  static OrcamentoValidacaoResultado? avaliar({
    required double custo,
    required double pago,
    required double limiteCategoria,
    required double totalPagoCategoria,
    required double limiteEvento,
    required double totalPagoEvento,
  }) {
    if (limiteCategoria <= 0) {
      return OrcamentoValidacaoResultado.erro(
        'A categoria não possui custo previsto.',
      );
    }

    if (_centavos(custo) > _centavos(limiteCategoria)) {
      return OrcamentoValidacaoResultado.excedeuCategoria(
        excedente: _diferenca(custo, limiteCategoria),
        limite: limiteCategoria,
      );
    }

    final pagoCategoria = totalPagoCategoria + pago;
    if (_centavos(pagoCategoria) > _centavos(limiteCategoria)) {
      return OrcamentoValidacaoResultado.excedeuPagamentoCategoria(
        excedente: _diferenca(pagoCategoria, limiteCategoria),
        limite: limiteCategoria,
      );
    }

    if (limiteEvento <= 0) {
      return OrcamentoValidacaoResultado.erro(
        'O evento não possui orçamento estimado definido.',
      );
    }

    final pagoEvento = totalPagoEvento + pago;
    if (_centavos(pagoEvento) > _centavos(limiteEvento)) {
      return OrcamentoValidacaoResultado.excedeuEvento(
        excedente: _diferenca(pagoEvento, limiteEvento),
        limite: limiteEvento,
      );
    }

    return null;
  }

  static int _centavos(double valor) => (valor * 100).round();

  static double _diferenca(double total, double limite) =>
      (_centavos(total) - _centavos(limite)) / 100;
}
