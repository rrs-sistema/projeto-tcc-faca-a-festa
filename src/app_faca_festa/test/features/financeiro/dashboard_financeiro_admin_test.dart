import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/financeiro/dashboard_financeiro_admin.dart';
import 'package:app_faca_festa/domain/services/dashboard_financeiro_admin_service.dart';

FatoComercialAdmin _c({
  required String evento,
  required String orc,
  required bool contratado,
  int valor = 0,
  int pago = 0,
  String? necessidade,
  String? fornecedor,
  String? servico,
}) {
  return FatoComercialAdmin(
    idEvento: evento,
    idOrcamento: orc,
    contratado: contratado,
    valorContratadoCentavos: contratado ? valor : 0,
    valorOportunidadeCentavos: contratado ? 0 : valor,
    pagoCentavos: pago,
    idNecessidade: necessidade,
    idFornecedor: fornecedor,
    idServico: servico ?? necessidade,
  );
}

void main() {
  test('dois eventos com três contratos cada: 2 eventos e 6 contratos', () {
    final fatos = <FatoComercialAdmin>[
      for (final e in ['e1', 'e2'])
        for (var i = 1; i <= 3; i++)
          _c(
            evento: e,
            orc: '$e-c$i',
            contratado: true,
            valor: 100000,
            fornecedor: 'f$i',
            necessidade: '$e-n$i',
          ),
    ];
    final d = DashboardFinanceiroAdminService.agregar(fatos: fatos);
    expect(d.qtdEventos, 2);
    expect(d.qtdContratos, 6);
    expect(d.qtdFornecedoresDistintos, 3);
  });

  test('R\$100k movimentados e R\$5k comissão ≠ R\$100k receita própria', () {
    final fatos = [
      _c(
        evento: 'e1',
        orc: 'c1',
        contratado: true,
        valor: 10000000,
        pago: 10000000,
      ),
    ];
    final comissoes = [
      const FatoComissaoAdmin(
        id: 'com1',
        status: 'recebida',
        valorOriginalCentavos: 500000,
        valorLiquidadoCentavos: 500000,
        idEvento: 'e1',
      ),
    ];
    final d = DashboardFinanceiroAdminService.agregar(
      fatos: fatos,
      comissoes: comissoes,
      politicaComissaoAtiva: true,
    );
    expect(d.pagamentosEventosCentavos, 10000000);
    expect(d.volumeContratadoCentavos, 10000000);
    expect(d.receitaPlataformaCentavos, 500000);
    expect(d.receitaPlataformaCentavos, isNot(d.pagamentosEventosCentavos));
  });

  test('reabrir/repetir agregação não altera totais', () {
    final fatos = [
      _c(evento: 'e1', orc: 'c1', contratado: true, valor: 1000, pago: 400),
      _c(evento: 'e1', orc: 'c2', contratado: true, valor: 2000, pago: 0),
    ];
    final a = DashboardFinanceiroAdminService.agregar(fatos: fatos);
    final b = DashboardFinanceiroAdminService.agregar(fatos: fatos);
    expect(a.qtdEventos, b.qtdEventos);
    expect(a.qtdContratos, b.qtdContratos);
    expect(a.volumeContratadoCentavos, b.volumeContratadoCentavos);
    expect(a.pagamentosEventosCentavos, b.pagamentosEventosCentavos);
    expect(a.linhasEvento.single.contratadoCentavos, 3000);
    expect(a.linhasEvento.single.pagoCentavos, 400);
  });

  test('alternativas da mesma necessidade não inflacionam previsão', () {
    final fatos = [
      _c(
        evento: 'e1',
        orc: 'a1',
        contratado: false,
        valor: 500000,
        necessidade: 'nec1',
      ),
      _c(
        evento: 'e1',
        orc: 'a2',
        contratado: false,
        valor: 700000,
        necessidade: 'nec1',
      ),
    ];
    final d = DashboardFinanceiroAdminService.agregar(fatos: fatos);
    expect(d.valorOportunidadesCentavos, 700000);
  });

  test('sem política: comissão não configurada; sem lucro líquido sem despesas',
      () {
    final d = DashboardFinanceiroAdminService.agregar(fatos: const []);
    expect(d.comissao.configurada, isFalse);
    expect(d.rotuloResultado, isNot(contains('lucro_liquido')));
  });

  test('linha por evento não duplica total ao listar contratos', () {
    final fatos = [
      _c(evento: 'e1', orc: 'c1', contratado: true, valor: 100, pago: 50),
      _c(evento: 'e1', orc: 'c2', contratado: true, valor: 200, pago: 100),
    ];
    final d = DashboardFinanceiroAdminService.agregar(fatos: fatos);
    expect(d.linhasEvento.length, 1);
    expect(d.linhasEvento.single.contratadoCentavos, 300);
    expect(d.volumeContratadoCentavos, 300);
  });
}
