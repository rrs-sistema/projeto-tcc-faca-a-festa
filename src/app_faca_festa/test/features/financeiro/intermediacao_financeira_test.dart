import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/financeiro/intermediacao_financeira.dart';
import 'package:app_faca_festa/domain/services/intermediacao_financeira_service.dart';

void main() {
  const svc = IntermediacaoFinanceiraService();

  test('10k com 5% descontada: 9500 fornecedor sem cobrança duplicada', () {
    final d = svc.calcularDireitos(
      valorContratadoCentavos: 1000000,
      percentualBps: 500,
    );
    expect(d.direitoFornecedorPrevistoCentavos, 950000);
    expect(d.comissaoPrevistaCentavos, 50000);
    expect(d.precoClienteCentavos, 1000000);
  });

  test('parcial 4k sem política não libera repasse nem marca recebido fornecedor', () {
    final eleg = svc.avaliarElegibilidade(
      direitoFornecedorCentavos: 950000,
      alocadoCentavos: 400000,
      jaRepassadoCentavos: 0,
      jaAuthCentavos: 0,
      politicaAtiva: false,
    );
    expect(eleg.elegivelCentavos, 0);
    expect(eleg.estado, EstadoRepasse.elegivelPendente);
    expect(1000000 - 400000, 600000); // a receber cliente
  });

  test('política sintética teto 3k + confirmação manual', () {
    final eleg = svc.avaliarElegibilidade(
      direitoFornecedorCentavos: 950000,
      alocadoCentavos: 400000,
      jaRepassadoCentavos: 0,
      jaAuthCentavos: 0,
      politicaAtiva: true,
      permiteParcial: true,
      tetoParcialCentavos: 300000,
    );
    expect(eleg.elegivelCentavos, 300000);
    expect(svc.confirmarManual(EstadoRepasse.autorizado), EstadoRepasse.confirmado);
    final caixa = svc.conciliarCaixa(
      recebidoCentavos: 400000,
      alocadoCentavos: 400000,
      repassadoCentavos: 300000,
    );
    expect(caixa.residual, 100000);
    expect(caixa.ok, isTrue);
  });

  test('concorrência 6k: 4k+3k não passam juntos', () {
    final r = svc.concorrenciaAlocacao(
      disponivelCentavos: 600000,
      pedidoACentavos: 400000,
      pedidoBCentavos: 300000,
    );
    expect(r.aceitoA, isTrue);
    expect(r.aceitoB, isFalse);
    expect(svc.tentarAlocar(
      valorRecebimentoCentavos: 600000,
      jaAlocadoCentavos: 400000,
      pedidoCentavos: 300000,
    ), isNull);
  });

  test('chargeback após repasse preserva histórico', () {
    final c = svc.chargebackPosRepasse(
      valorChargebackCentavos: 200000,
      repassadoConfirmadoCentavos: 300000,
    );
    expect(c.repassePreservado, 300000);
    expect(c.recuperacaoPendente, 200000);
  });
}
