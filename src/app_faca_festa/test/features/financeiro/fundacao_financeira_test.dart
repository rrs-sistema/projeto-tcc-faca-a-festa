import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';
import 'package:app_faca_festa/domain/entities/financeiro/contrato_financeiro.dart';
import 'package:app_faca_festa/domain/entities/financeiro/liquidacao_financeira.dart';
import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_evento_service.dart';

void main() {
  const mapper = CompromissoPlanejamentoService();
  const resumo = ResumoFinanceiroEventoService();

  test('contrato 10000 e pagamento 3000: contratado, pago e saldo 7000', () {
    final c = mapper.mapear('buffet', {
      'custo_estimado': 10000,
      'valor_contratado': 10000,
      'status': 'fechado',
      'orcamento_fechado': true,
    }, gastos: [
      {'custo': 10000, 'pago': 3000}
    ])!;
    final r = resumo.calcular([c]);
    expect(r.contratado, 10000);
    expect(r.pagoLiquido, 3000);
    expect(r.saldoDevido, 7000);
  });

  test('três propostas alternativas não somam dívida de 13500', () {
    final a = mapper.mapear('a', {
      'custo_estimado': 4000,
      'status': 'em_negociacao',
      'id_necessidade': 'buffet',
      'id_cotacao': 'cot-1',
    })!;
    final b = mapper.mapear('b', {
      'custo_estimado': 4500,
      'status': 'em_negociacao',
      'id_necessidade': 'buffet',
      'id_cotacao': 'cot-1',
    })!;
    final c = mapper.mapear('c', {
      'custo_estimado': 5000,
      'status': 'em_negociacao',
      'id_necessidade': 'buffet',
      'id_cotacao': 'cot-1',
    })!;
    final r = resumo.calcular([a, b, c]);
    expect(r.cotado, 5000);
    expect(r.contratado, 0);
    expect(r.saldoDevido, 0);
    expect(r.estimado, 5000);
  });

  test('não usa max(estimado, gasto, realizado) como contrato', () {
    final c = mapper.mapear('x', {
      'custo_estimado': 1000,
      'custo_real': 2000,
      'status': 'pendente',
    }, gastos: [
      {'custo': 9000, 'pago': 0}
    ])!;
    expect(c['contratado'], isFalse);
    expect(c['valor_contratado'], 0);
    expect(c['valor'], 1000);
    expect(c['despesas'], 9000);
  });

  test('cancelamento com retenção/reembolso preserva pagamento e explica saldo',
      () {
    final c = mapper.mapear('c', {
      'custo_estimado': 10000,
      'valor_contratado': 10000,
      'status': 'cancelado',
      'contrato_financeiro': {
        'estado_comercial': 'cancelado',
        'valor': {'centavos': 1000000, 'moeda': 'BRL'},
        'retencao': {'centavos': 50000, 'moeda': 'BRL'},
        'reembolso': {'centavos': 200000, 'moeda': 'BRL'},
      },
    }, gastos: [
      {'custo': 10000, 'pago': 4000}
    ])!;
    expect(c['pago'], 2000); // 4000 bruto - 2000 reembolso
    expect(c['retencao'], 500);
    expect(c['reembolso'], 2000);
    expect(c['contratado'], isFalse);
  });

  test('centavos e adaptação de legado sem migração silenciosa', () {
    expect(ValorMonetario.deReaisArredondado(10).centavos, 1000);
    expect(ValorMonetario.deReaisLegado(10.00)?.centavos, 1000);
    expect(ValorMonetario.deReaisLegado(10.001), isNull);
    final contrato = ContratoFinanceiro(
      id: 'c1',
      idEvento: 'e1',
      idOrcamento: 'o1',
      valor: ValorMonetario.centavos(1000000),
      estadoComercial: EstadoComercialContrato.contratado,
    );
    expect(contrato.saldoDevidoCentavos(pagoLiquidoCentavos: 300000), 700000);
  });

  test('excesso sobre saldo exige crédito/adiantamento explícito', () {
    expect(TipoLiquidacao.pagamento.permiteExcederSaldo, isFalse);
    expect(TipoLiquidacao.credito.permiteExcederSaldo, isTrue);
    expect(TipoLiquidacao.adiantamento.permiteExcederSaldo, isTrue);
  });

  test('flag legado pago sem despesa deixa financeiro incompleto', () {
    final r = resumo.calcular([
      mapper.mapear('c', {'custo_estimado': 6500, 'pago': true})!
    ]);
    expect(r.pagoLiquido, 0);
    expect(r.completo, isFalse);
  });
}
