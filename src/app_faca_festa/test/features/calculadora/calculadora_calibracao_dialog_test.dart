import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/domain/services/consumo_observado_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_consumo_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';
import 'calculadora_calibracao_test.dart' show arrozObservado;

Finder campo(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label);
Future<void> preencher(WidgetTester tester, String label, String valor) async {
  final f = campo(label);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.enterText(f, valor);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'registro móvel valida entradas antes de salvar e conserva medidas reais',
      (tester) async {
    tester.view.physicalSize = const Size(420, 910);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RegistroConsumoCalculadora? salvo;
    final regra = arrozObservado();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<bool>(
                        context: ctx,
                        builder: (_) => CalculadoraConsumoDialog(
                            idEvento: 'evento',
                            regra: regra,
                            contexto: (r, {int? duracaoObservada}) =>
                                const ConsumoObservadoService().contexto(r, [r],
                                    duracaoHoras: duracaoObservada ?? 4),
                            onSalvar: (r) async {
                              salvo = r;
                            })),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar consumo e simulação'));
    await tester.pumpAndSettle();
    expect(salvo, isNull);
    expect(tester.takeException(), isNull);
    final dataConsumo = find.text('Informar data do consumo');
    await tester.ensureVisible(dataConsumo);
    await tester.tap(dataConsumo);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await preencher(tester, 'Adultos que realmente participaram', '10');
    await preencher(tester, 'Duração observada do serviço (horas)', '4');
    await preencher(tester, 'Total pronto disponibilizado (kg)', '3');
    await preencher(tester, 'Sobra pronta que não foi servida (kg)', '0,5');
    await preencher(tester, 'Desperdício medido nos pratos (kg)', '0,2');
    await tester.tap(find.text('Salvar consumo e simulação'));
    await tester.pumpAndSettle();
    expect(salvo?.consumidoPronto, closeTo(2.3, 1e-9));
    expect(salvo?.adultos, 10);
    expect(salvo?.regra.premissas['receita'], 'Arroz branco');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'referência contextual é aplicada por escolha e preserva contexto ao salvar',
      (tester) async {
    ItemEstimativaFinanceira? salvo;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      salvo = await showDialog<ItemEstimativaFinanceira>(
                          context: ctx,
                          builder: (_) => CalculadoraRegraManualDialog(
                                  inicial: arrozObservado().copyWith(
                                      premissas: {
                                    ...arrozObservado().premissas,
                                    'estado': 'cru'
                                  })));
                    },
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final buscar = find.text('Buscar referência para este contexto');
    await tester.ensureVisible(buscar);
    await tester.pumpAndSettle();
    await tester.tap(buscar);
    await tester.pumpAndSettle();
    expect(find.text('Usar 50 g'), findsOneWidget);
    expect(find.text('Usar 60 g'), findsOneWidget);
    await tester.tap(find.text('Usar 50 g'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(salvo?.quantidadePorConvidadoEquivalente, .05);
    expect(salvo?.premissas['consumo_max'], .06);
    expect(salvo?.premissas['papel_na_refeicao'], 'acompanhamento');
    expect(salvo?.premissas['ajustar_por_perfil'], isFalse);
    expect(tester.takeException(), isNull);
  });
}
