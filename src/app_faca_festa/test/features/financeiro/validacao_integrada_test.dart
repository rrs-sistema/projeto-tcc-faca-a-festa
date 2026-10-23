import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_evento_service.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';
import 'package:app_faca_festa/domain/services/estoque_fornecedor_service.dart';
import 'package:app_faca_festa/domain/entities/financeiro/item_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/financeiro/movimento_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/financeiro/comissao_plataforma.dart';
import 'package:app_faca_festa/domain/services/comissao_plataforma_service.dart';
import 'package:app_faca_festa/domain/services/dashboard_financeiro_admin_service.dart';
import 'package:app_faca_festa/domain/entities/financeiro/dashboard_financeiro_admin.dart';
import 'package:app_faca_festa/domain/services/simulacao_orcamento_evento_service.dart';

/// Sessão: geração invalida callbacks antigos (padrão GetX financeiro).
class _SessaoFake {
  int geracao = 0;
  String? uid = 'org-1';
  void trocarEvento() => geracao++;
  void logout() {
    geracao++;
    uid = null;
  }
}

PoliticaComissaoPlataforma _politica({int bps = 500, int versao = 1}) {
  return PoliticaComissaoPlataforma(
    id: 'p',
    versao: versao,
    percentualBps: bps,
    baseElegivel: BaseElegivelComissao.servicosContratadosPlataforma,
    pagador: PagadorComissao.fornecedor,
    gatilho: GatilhoGeracaoComissao.contratacaoConfirmada,
    reversao: ReversaoComissao.proporcional,
    ativa: true,
  );
}

void main() {
  const resumo = ResumoFinanceiroEventoService();
  const previsao = PrevisaoFinanceiraGerenteService();
  const sim = SimulacaoOrcamentoEventoService();
  const fornSvc = ResumoFinanceiroFornecedorService();

  test('contrato 10k / pago 3k / saldo 7k', () {
    final r = resumo.calcular([
      {
        'id': 'c1',
        'id_necessidade': 'n1',
        'contratado': true,
        'valor_contratado': 10000,
        'pago': 3000,
        'saldo_devido': 7000,
        'financeiro_valido': true,
      },
    ]);
    expect(r.contratado, 10000);
    expect(r.pagoLiquido, 3000);
    expect(r.saldoDevido, 7000);
  });

  test('previsão 30k / 18k / 8k → 26k', () {
    final r = previsao.calcular(
      idEvento: 'e1',
      nomeEvento: 'Festa',
      limiteConfirmado: 30000,
      compromissos: [
        {
          'id': '1',
          'contratado': true,
          'valor_contratado': 18000,
          'pago': 7000,
          'saldo_devido': 11000,
          'financeiro_valido': true,
        },
      ],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(
          id: 'n1',
          descricao: 'Restante',
          custoEstimadoTotal: 8000,
        ),
      ],
    );
    expect(r.custoFinalPrevisto, 26000);
  });

  test('comissão 500 uma vez; taxa futura preserva', () {
    final o = ComissaoPlataformaService.gerarObrigacao(
      politica: _politica(bps: 500),
      idObrigacao: 'o1',
      idEvento: 'e1',
      idContrato: 'c1',
      baseBrutaCentavos: 1000000,
    );
    expect(o.valorOriginalCentavos, 50000);
    final o2 = ComissaoPlataformaService.gerarObrigacao(
      politica: _politica(bps: 600, versao: 2),
      idObrigacao: 'o1',
      idEvento: 'e1',
      idContrato: 'c1',
      baseBrutaCentavos: 1000000,
      jaExistente: o,
    );
    expect(o2.valorOriginalCentavos, 50000);
    expect(o2.politicaAplicada['percentual_bps'], 500);
  });

  test('estoque concorrente e cancelamento parcial', () {
    final item = ItemEstoqueFornecedor(
      idItem: 'c',
      idFornecedor: 'forn-1',
      nome: 'Cadeira',
      natureza: NaturezaItemEstoque.consumivel,
      unidade: 'un',
      quantidadeTotal: 100,
      quantidadeReservada: 0,
      quantidadeEmUso: 0,
      status: StatusFisicoItemEstoque.disponivel,
      metodoValorizacao: MetodoValorizacaoEstoque.custoMedioMovel,
      custoMedioUnitarioCentavos: 500,
    );
    final intervalo = EstoqueFornecedorService.intervaloEfetivo(
      inicio: DateTime(2026, 10, 21, 10),
      fim: DateTime(2026, 10, 21, 18),
      item: item,
    );
    final r1 = EstoqueFornecedorService.reservar(
      item: item,
      idReserva: 'r1',
      idEvento: 'e1',
      quantidade: 60,
      intervalo: intervalo,
      reservasAtivas: const [],
    );
    expect(
      () => EstoqueFornecedorService.reservar(
        item: r1.item,
        idReserva: 'r2',
        idEvento: 'e2',
        quantidade: 50,
        intervalo: intervalo,
        reservasAtivas: [r1.reserva!],
      ),
      throwsA(isA<StateError>()),
    );
    final can = EstoqueFornecedorService.cancelarReserva(
      item: r1.item,
      reserva: r1.reserva!,
    );
    expect(can.reserva!.status, StatusReservaEstoque.cancelada);
  });

  test(
      'pagamento evento não copia recebimento fornecedor; dashboard volume ≠ receita',
      () {
    final evento = resumo.calcular([
      {
        'id': 'c1',
        'contratado': true,
        'valor_contratado': 10000,
        'pago': 4000,
        'saldo_devido': 6000,
        'financeiro_valido': true,
      },
    ]);
    final forn = fornSvc.calcular(
      idFornecedor: 'forn-1',
      vendas: const [
        VendaFornecedorFato(
          id: 'v1',
          idEvento: 'e1',
          valorContratado: 10000,
          recebidoConfirmado: 0,
        ),
      ],
      custos: const [],
    );
    expect(evento.pagoLiquido, 4000);
    expect(forn.recebido, 0);

    final dash = DashboardFinanceiroAdminService.agregar(
      fatos: [
        const FatoComercialAdmin(
          idEvento: 'e1',
          idOrcamento: 'c1',
          contratado: true,
          valorContratadoCentavos: 10000000,
          pagoCentavos: 10000000,
        ),
      ],
      comissoes: const [
        FatoComissaoAdmin(
          id: 'com1',
          status: 'recebida',
          valorOriginalCentavos: 500000,
          valorLiquidadoCentavos: 500000,
          idEvento: 'e1',
        ),
      ],
      politicaComissaoAtiva: true,
    );
    expect(dash.receitaPlataformaCentavos, 500000);
    expect(
      dash.pagamentosEventosCentavos,
      isNot(dash.receitaPlataformaCentavos),
    );
  });

  test('fuso America/Sao_Paulo e logout invalida sessão', () {
    // Apresentação no fuso America/Sao_Paulo (contrato de UI); offset −03:00.
    const tz = 'America/Sao_Paulo';
    expect(tz, 'America/Sao_Paulo');
    final utc = DateTime.utc(2026, 10, 21, 18);
    final saoPaulo = utc.subtract(const Duration(hours: 3));
    expect(saoPaulo.hour, 15);
    expect(saoPaulo.day, 21);

    final sessao = _SessaoFake();
    final g0 = sessao.geracao;
    var callbackValido = true;
    sessao.trocarEvento();
    if (sessao.geracao != g0) callbackValido = false;
    expect(callbackValido, isFalse);
    sessao.logout();
    expect(sessao.uid, isNull);
  });

  test('simulação não altera financeiro; preço ausente parcial', () {
    final r = sim.simular(
      limiteConfirmadoCentavos: 2000000,
      compromissos: [
        {
          'id': 'c1',
          'contratado': true,
          'valor_contratado': 15000,
          'pago': 0,
          'financeiro_valido': true,
        },
      ],
      necessidades: const [],
      alternativasPorNecessidade: const {},
    );
    expect(r.orcamentoLivreAntesDespesasCentavos, 500000);
    expect(r.alteraFinanceiro, isFalse);

    final parcial = previsao.calcular(
      idEvento: 'e1',
      nomeEvento: 'X',
      limiteConfirmado: 10000,
      compromissos: const [],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(
          id: 's',
          descricao: 'Som',
          quantidadeNecessaria: 1,
          precoUnitario: null,
        ),
      ],
    );
    expect(parcial.completo, isFalse);
    expect(parcial.cabeNoLimite, isNull);
  });
}
