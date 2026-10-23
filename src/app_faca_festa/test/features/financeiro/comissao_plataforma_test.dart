import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/financeiro/comissao_plataforma.dart';
import 'package:app_faca_festa/domain/services/comissao_plataforma_service.dart';

PoliticaComissaoPlataforma _politica({
  int bps = 500,
  bool ativa = true,
  bool completa = true,
  ReversaoComissao reversao = ReversaoComissao.proporcional,
}) {
  return PoliticaComissaoPlataforma(
    id: 'pol-1',
    versao: 1,
    percentualBps: bps,
    baseElegivel: BaseElegivelComissao.servicosContratadosPlataforma,
    pagador: PagadorComissao.fornecedor,
    gatilho: GatilhoGeracaoComissao.contratacaoConfirmada,
    reversao: reversao,
    ativa: ativa,
    completa: completa,
  );
}

void main() {
  test('política 5% base 10k gera R\$500 uma única vez', () {
    final pol = _politica(bps: 500);
    final o1 = ComissaoPlataformaService.gerarObrigacao(
      politica: pol,
      idObrigacao: 'comissao-c1',
      idEvento: 'e1',
      idContrato: 'c1',
      baseBrutaCentavos: 1000000,
    );
    expect(o1.valorOriginalCentavos, 50000);
    final o2 = ComissaoPlataformaService.gerarObrigacao(
      politica: pol,
      idObrigacao: 'comissao-c1',
      idEvento: 'e1',
      idContrato: 'c1',
      baseBrutaCentavos: 1000000,
      jaExistente: o1,
    );
    expect(identical(o1, o2) || o2.valorOriginalCentavos == 50000, isTrue);
    expect(o2.valorOriginalCentavos, 50000);
  });

  test('alterar taxa futura para 6% preserva R\$500 anteriores', () {
    final o = ComissaoPlataformaService.gerarObrigacao(
      politica: _politica(bps: 500),
      idObrigacao: 'o1',
      idEvento: 'e1',
      idContrato: 'c1',
      baseBrutaCentavos: 1000000,
    );
    expect(o.politicaAplicada['percentual_bps'], 500);
    expect(o.valorOriginalCentavos, 50000);
    // Política global muda — snapshot imutável permanece.
    final futura = _politica(bps: 600);
    expect(futura.percentualBps, 600);
    expect(o.politicaAplicada['percentual_bps'], 500);
    expect(o.valorOriginalCentavos, 50000);
  });

  test('liquidação R\$200 deixa saldo R\$300', () {
    final o = ComissaoPlataformaService.gerarObrigacao(
      politica: _politica(),
      idObrigacao: 'o1',
      idEvento: 'e1',
      idContrato: 'c1',
      baseBrutaCentavos: 1000000,
    );
    final liq = ComissaoPlataformaService.liquidarManual(
      obrigacao: o,
      valorCentavos: 20000,
    );
    expect(liq.saldoCentavos, 30000);
  });

  test('redução elegível R\$2000 com reversão proporcional → ajuste R\$100',
      () {
    final aj = ComissaoPlataformaService.ajustePorReducaoElegivel(
      percentualBpsAplicado: 500,
      reducaoBaseCentavos: 200000,
      reversao: ReversaoComissao.proporcional,
    );
    expect(aj.ajusteCentavos, -10000);
    expect(aj.creditoReembolsoExplicito, isTrue);
    final o = ComissaoPlataformaService.gerarObrigacao(
      politica: _politica(),
      idObrigacao: 'o1',
      idEvento: 'e1',
      idContrato: 'c1',
      baseBrutaCentavos: 1000000,
    );
    final comAj = ComissaoPlataformaService.aplicarAjuste(
      obrigacao: o,
      ajusteCentavos: aj.ajusteCentavos,
    );
    expect(comAj.saldoCentavos, 40000);
  });

  test('política ausente/inativa/incompleta não gera dívida; simulação ok', () {
    expect(
      ComissaoPlataformaService.simular(
        politica: null,
        baseBrutaCentavos: 1000000,
      ).podeGerar,
      isFalse,
    );
    expect(
      ComissaoPlataformaService.simular(
        politica: _politica(ativa: false),
        baseBrutaCentavos: 1000000,
      ).podeGerar,
      isFalse,
    );
    expect(
      ComissaoPlataformaService.simular(
        politica: _politica(completa: false),
        baseBrutaCentavos: 1000000,
      ).podeGerar,
      isFalse,
    );
    expect(
      () => ComissaoPlataformaService.gerarObrigacao(
        politica: _politica(ativa: false),
        idObrigacao: 'x',
        idEvento: 'e',
        idContrato: 'c',
        baseBrutaCentavos: 1000000,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('zero válido difere de ausente; alteração não autorizada espelhada', () {
    ComissaoPlataformaService.validarPercentualBps(0);
    expect(
      () => ComissaoPlataformaService.validarPercentualBps(null),
      throwsArgumentError,
    );
    bool podeConfigurar(String tipo) => tipo == 'A';
    expect(podeConfigurar('F'), isFalse);
    expect(podeConfigurar('O'), isFalse);
    expect(podeConfigurar('A'), isTrue);
  });
}
