import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/disponibilidade_cardapio_dialog.dart';

const item = CardapioItem(
    idItem: 'i', idEvento: 'e', idCardapio: 'c', nome: 'Arroz', unidade: 'kg');
void main() {
  testWidgets(
      'disponibilidade só grava comprado finito e dirige o estoque ao controle central',
      (tester) async {
    DisponibilidadeCardapio? salvo;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DisponibilidadeCardapioDialog(
                item: item,
                unidade: 'kg',
                estado: 'cru',
                onSalvar: (v) async {
                  salvo = v;
                }))));
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.first, '-1');
    expect(tester.widget<TextFormField>(campos.first).controller!.text, '0');
    await tester.enterText(campos.first, '');
    await tester.enterText(campos.first, 'NaN');
    expect(tester.widget<TextFormField>(campos.first).controller!.text, '');
    await tester.tap(find.text('Salvar disponibilidade'));
    await tester.pumpAndSettle();
    expect(salvo, isNull);
    expect(find.text('Informe zero ou uma quantidade válida'), findsOneWidget);
    // A validação também protege alterações programáticas, que não usam máscara.
    tester.widget<TextFormField>(campos.first).controller!.text = '-1';
    await tester.tap(find.text('Salvar disponibilidade'));
    await tester.pumpAndSettle();
    expect(salvo, isNull);
    await tester.enterText(campos.first, '3,5');
    expect(tester.widget<TextFormField>(campos.last).enabled, false);
    await tester.tap(find.text('Salvar disponibilidade'));
    await tester.pumpAndSettle();
    expect(salvo!.comprado, 3.5);
    expect(salvo!.estoque, 0);
    expect(salvo!.estado, 'cru');
    expect(salvo!.nome, 'Arroz');
  });
  testWidgets(
      'falha de gravação mantém formulário e confirmação acessível com teclado e fonte ampliada',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(1.4),
                viewInsets: EdgeInsets.only(bottom: 240)),
            child: Scaffold(
                body: DisponibilidadeCardapioDialog(
                    item: item,
                    estado: 'cru',
                    onSalvar: (_) async {
                      throw StateError('offline');
                    })))));
    expect(find.text('Salvar disponibilidade').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Salvar disponibilidade'));
    await tester.pumpAndSettle();
    expect(find.byType(DisponibilidadeCardapioDialog), findsOneWidget);
    expect(find.text('Salvar disponibilidade').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
