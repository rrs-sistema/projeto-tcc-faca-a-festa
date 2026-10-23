import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/financeiro/alerta_financeiro.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('alertas agrupados colapsam a mesma causa e preservam eventos', () {
    final grupos = agruparAlertasFinanceiros(const [
      AlertaFinanceiro(
        tipo: TipoAlertaFinanceiro.consultaIncompleta,
        mensagem: 'Mesma causa',
        idEvento: 'e1',
      ),
      AlertaFinanceiro(
        tipo: TipoAlertaFinanceiro.consultaIncompleta,
        mensagem: 'Mesma causa',
        idEvento: 'e2',
      ),
      AlertaFinanceiro(
        tipo: TipoAlertaFinanceiro.consultaIncompleta,
        mensagem: 'Outra',
      ),
    ]);
    expect(grupos.length, 2);
    final mesma = grupos.firstWhere((g) => g.mensagem == 'Mesma causa');
    expect(mesma.quantidade, 2);
    expect(mesma.eventos, containsAll(['e1', 'e2']));
  });

  testWidgets('síntese 10k/4k/6k legível; fórmula só após Como é calculado',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    const r = ResumoFinanceiroFornecedor(
      idFornecedor: 'forn-1',
      contratado: 10000,
      recebido: 4000,
      aReceber: 6000,
      custoDiretoPrevisto: 5000,
      resultadoDiretoPrevisto: 5000,
      resultadoDiretoRealizado: 1000,
      completo: false,
      formulaResultado: 'resultado_direto = receita − custo',
    );

    var formulaAberta = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: FornecedorPremiumPalette.background,
          body: StatefulBuilder(
            builder: (context, setState) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Síntese', style: GoogleFonts.poppins(fontSize: 15)),
                  const SizedBox(height: 8),
                  PremiumMetricTile(
                    label: 'Contratado',
                    value: NumericInput.dinheiro(r.contratado),
                    icon: Icons.handshake_outlined,
                    color: FornecedorPremiumPalette.indigo,
                  ),
                  PremiumMetricTile(
                    label: 'Recebido',
                    value: NumericInput.dinheiro(r.recebido),
                    icon: Icons.payments_outlined,
                    color: FornecedorPremiumPalette.emerald,
                  ),
                  PremiumMetricTile(
                    label: 'A receber',
                    value: NumericInput.dinheiro(r.aReceber),
                    icon: Icons.schedule_outlined,
                    color: FornecedorPremiumPalette.amber,
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => formulaAberta = !formulaAberta),
                    child: const Text('Como é calculado'),
                  ),
                  if (formulaAberta) Text(r.formulaResultado),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contratado'), findsOneWidget);
    expect(find.text('Recebido'), findsOneWidget);
    expect(find.text('A receber'), findsOneWidget);
    expect(find.text('R\$ 10.000,00'), findsOneWidget);
    expect(find.text('R\$ 4.000,00'), findsOneWidget);
    expect(find.text('R\$ 6.000,00'), findsOneWidget);
    expect(find.textContaining('resultado_direto'), findsNothing);

    await tester.tap(find.text('Como é calculado'));
    await tester.pumpAndSettle();
    expect(find.textContaining('resultado_direto'), findsOneWidget);
  });
}
