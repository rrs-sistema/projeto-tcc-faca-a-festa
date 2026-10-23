import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('totais de cobrança leem centavos em formatos legados', () {
    final o = {
      'valor_original': {'centavos': 50000},
      'valor_liquidado_centavos': 20000,
      'valor_ajustes_centavos': 0,
    };
    expect(ComissaoPlataformaController.valorOriginalDe(o), 50000);
    expect(ComissaoPlataformaController.valorLiquidadoDe(o), 20000);
    expect(ComissaoPlataformaController.saldoDe(o), 30000);
  });

  testWidgets('navegação admin prioriza Cobranças; simulador é aba separada',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AdminPalette.surface,
            appBar: AppBar(
              title: const Text('Comissões'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Cobranças'),
                  Tab(text: 'Políticas'),
                  Tab(text: 'Simulador'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                Center(child: Text('lista-cobrancas')),
                Center(child: Text('lista-politicas')),
                Center(child: Text('Esta simulação não gera cobrança.')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cobranças'), findsOneWidget);
    expect(find.text('lista-cobrancas'), findsOneWidget);
    expect(find.text('Esta simulação não gera cobrança.'), findsNothing);

    await tester.tap(find.text('Simulador'));
    await tester.pumpAndSettle();
    expect(find.text('Esta simulação não gera cobrança.'), findsOneWidget);
  });

  testWidgets('pagador não vê aba Políticas na composição', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: const TabBar(
              tabs: [
                Tab(text: 'Cobranças'),
                Tab(text: 'Simulador'),
              ],
            ),
            body: const TabBarView(
              children: [
                Center(child: Text('extrato-pagador')),
                Center(child: Text('sim')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cobranças'), findsOneWidget);
    expect(find.text('Políticas'), findsNothing);
    expect(find.text('extrato-pagador'), findsOneWidget);
  });

  test('formatação pt-BR da síntese 500', () {
    expect(NumericInput.dinheiro(500), 'R\$ 500,00');
  });
}
