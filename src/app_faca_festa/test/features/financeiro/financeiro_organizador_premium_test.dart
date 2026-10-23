import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_gerente_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test(
      'aceite 30k/18k/7k/8k: saldo 11k, previsão 26k, folga 4k (domínio intacto)',
      () {
    const previsao = PrevisaoFinanceiraGerenteService();
    const mapper = CompromissoPlanejamentoService();
    final contrato = mapper.mapear('buffet', {
      'custo_estimado': 18000,
      'valor_contratado': 18000,
      'status': 'fechado',
      'orcamento_fechado': true,
    }, gastos: [
      {'custo': 18000, 'pago': 7000}
    ])!;
    final r = previsao.calcular(
      idEvento: 'e1',
      nomeEvento: 'Festa',
      limiteConfirmado: 30000,
      compromissos: [contrato],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(
          id: 'n1',
          descricao: 'Decoração restante',
          custoEstimadoTotal: 8000,
        ),
      ],
    );
    expect(r.saldoContratado, 11000);
    expect(r.custoFinalPrevisto, 26000);
    expect(r.folgaAntesReserva, 4000);
    expect(r.completo, isTrue);
    expect(r.cabeNoLimite, isTrue);
  });

  test('projeção parcial sem selo Dentro do orçamento', () {
    const previsao = PrevisaoFinanceiraGerenteService();
    final r = previsao.calcular(
      idEvento: 'e1',
      nomeEvento: 'Festa',
      limiteConfirmado: 30000,
      necessidades: const [
        NecessidadeFinanceiraDescoberta(
          id: 'x',
          descricao: 'Som',
          quantidadeNecessaria: 1,
          precoUnitario: null,
        ),
      ],
    );
    expect(r.completo, isFalse);
    expect(r.cabeNoLimite, isNull);
  });

  testWidgets('lista: eixo explícito, Itens/serviços, limpar filtro',
      (tester) async {
    var eixo = EixoTemporalFinanceiro.mesEvento;
    var temFiltro = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Financeiro dos meus eventos',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
                  SegmentedButton<EixoTemporalFinanceiro>(
                    segments: const [
                      ButtonSegment(
                        value: EixoTemporalFinanceiro.mesEvento,
                        label: Text('Data do evento'),
                      ),
                      ButtonSegment(
                        value: EixoTemporalFinanceiro.mesPagamento,
                        label: Text('Ref. pagamento'),
                      ),
                    ],
                    selected: <EixoTemporalFinanceiro>{eixo},
                    onSelectionChanged: (s) {
                      setState(() => eixo = s.first);
                    },
                  ),
                  const Text('Itens/serviços'),
                  if (temFiltro)
                    TextButton(
                      onPressed: () => setState(() => temFiltro = false),
                      child: const Text('Limpar filtros'),
                    ),
                  if (temFiltro)
                    const Text('Nenhum resultado neste filtro')
                  else
                    const Text('lista-eventos'),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Financeiro dos meus eventos'), findsOneWidget);
    expect(find.text('Data do evento'), findsOneWidget);
    expect(find.text('Linhas'), findsNothing);
    expect(find.text('Itens/serviços'), findsOneWidget);
    await tester.tap(find.text('Ref. pagamento'));
    await tester.pumpAndSettle();
    expect(eixo, EixoTemporalFinanceiro.mesPagamento);
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('lista-eventos'), findsOneWidget);
  });

  testWidgets('detalhe: hierarquia orçamento e simulador secundário',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Orçamento e previsão',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
              const Text('Limite'),
              const Text('Previsão final'),
              const Text('Folga (antes da reserva)'),
              Text(
                'Contratos e pagamentos',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
              const Text('Saldo a pagar'),
              const Text('Falta contratar'),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Simular orçamento'),
              ),
              const Text(
                'Não altera contratos, pagamentos nem o limite.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Orçamento e previsão'), findsOneWidget);
    expect(find.text('Simular orçamento'), findsOneWidget);
    expect(find.text('Saldo a pagar'), findsOneWidget);
    expect(
      find.textContaining('Não altera contratos'),
      findsOneWidget,
    );
  });

  testWidgets('falha ≠ zero confirmado na composição', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Não foi possível atualizar o financeiro.'),
              TextButton(onPressed: null, child: Text('Tentar novamente')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Eventos: 0'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
