import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';

void main() {
  testWidgets('consumo manual obrigatório e preço opcional', (tester) async {
    ItemEstimativaFinanceira? resultado;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        resultado = await showDialog<ItemEstimativaFinanceira>(
                            context: context,
                            builder: (_) =>
                                const CalculadoraRegraManualDialog());
                      },
                      child: const Text('Abrir')),
                ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um consumo maior que zero'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Água');
    final consumo =
        find.widgetWithText(TextFormField, 'Quantidade por convidado');
    await tester.ensureVisible(consumo);
    await tester.pumpAndSettle();
    await tester.enterText(consumo, '0,6');
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(resultado?.nome, 'Água');
    expect(resultado?.quantidadePorConvidadoEquivalente, .6);
    expect(resultado?.valorUnitarioMedio, 0);
  });

  testWidgets('regra de cardápio preserva unidade e público', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: CalculadoraRegraManualDialog(
      nome: 'Suco',
      unidade: UnidadeEstimativa.litro,
      publico: 'criancas',
      tipo: 'bebida',
    ))));
    final unidade = tester.widget<DropdownButtonFormField<UnidadeEstimativa>>(
        find.byType(DropdownButtonFormField<UnidadeEstimativa>));
    expect(unidade.onChanged, isNull);
    final nome = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(nome.initialValue, 'Suco');
    expect(find.textContaining('L por convidado equivalente'), findsOneWidget);
  });

  testWidgets('premissa inválida recolhida impede salvar sem exceção',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CalculadoraRegraManualDialog(
      inicial: ItemEstimativaFinanceira(
          id: 'teste',
          categoria: 'comida',
          nome: 'Arroz',
          tipoItem: 'comida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.quilo,
          quantidadePorConvidadoEquivalente: .1,
          valorUnitarioMedio: 0,
          premissas: const {'rendimento': 0}),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Revise composição e compra:'), findsOneWidget);
    expect(find.text('Regra de consumo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ações acessíveis em celular com teclado e texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          size: Size(360, 800),
          viewInsets: EdgeInsets.only(bottom: 280),
          textScaler: TextScaler.linear(1.3)),
      child: const CalculadoraRegraManualDialog(),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Usar no cálculo').hitTestable(), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.byTooltip('Fechar').hitTestable(), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Preço estimado'));
    await tester.pumpAndSettle();
    expect(find.text('Preço estimado').hitTestable(), findsOneWidget);
    final preco = find.byType(TextFormField).last;
    await tester.enterText(preco, '8,50');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final campoRect = tester.getRect(preco);
    final acaoRect = tester
        .getRect(find.byWidgetPredicate((widget) => widget is FilledButton));
    expect(campoRect.bottom, lessThan(acaoRect.top));
    expect(campoRect.top,
        greaterThan(tester.getRect(find.byType(SingleChildScrollView)).top));
    expect(tester.takeException(), isNull);
  });
}
