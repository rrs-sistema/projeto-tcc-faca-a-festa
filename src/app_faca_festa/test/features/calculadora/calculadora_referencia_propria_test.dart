import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_consumo_dialog.dart';
import 'calculadora_composicao_test.dart' show regraQA;
import 'calculadora_calibracao_test.dart' show observacao, arrozObservado;

void main() {
  testWidgets(
      'faixa da própria receita exige origem e persiste como informação do organizador',
      (tester) async {
    ItemEstimativaFinanceira? salvo;
    final inicial = regraQA('Arroz', consumo: .1, premissas: {
      'estado': 'cru',
      'papel_na_refeicao': 'acompanhamento',
      'receita': 'Arroz caseiro'
    });
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      salvo = await showDialog<ItemEstimativaFinanceira>(
                          context: ctx,
                          builder: (_) =>
                              CalculadoraRegraManualDialog(inicial: inicial));
                    },
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final referencia = find.text('Definir referência da minha receita');
    await tester.ensureVisible(referencia);
    await tester.pumpAndSettle();
    await tester.tap(referencia);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar minha referência'));
    await tester.pumpAndSettle();
    expect(find.text('Identifique a origem'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mínimo da receita'), '0,08');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Máximo da receita'), '0,12');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Origem ou anotação da referência'),
        'Medição da receita da família');
    await tester.tap(find.text('Usar minha referência'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(salvo!.premissas['origem'], 'referencia_organizador');
    expect(salvo!.premissas['consumo_min'], .08);
    expect(salvo!.premissas['consumo_max'], .12);
    expect(salvo!.premissas['referencia_contextual'], isNull);
    expect(salvo!.premissas['receita_referencia'], 'Arroz caseiro');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'revisão preenche somente medidas reais anteriores da mesma festa',
      (tester) async {
    final regra = arrozObservado();
    final anterior =
        observacao('festa', 3, regra: regra, sobra: .4, desperdicio: .1);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CalculadoraConsumoDialog(
                idEvento: 'festa',
                regra: regra,
                anterior: anterior,
                contexto: (_, {duracaoObservada}) => 'contexto',
                onSalvar: (_) async {}))));
    expect(find.text('3.0'), findsOneWidget);
    expect(find.text('0.4'), findsOneWidget);
    expect(find.textContaining('Último registro real'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
