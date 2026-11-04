import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/components/acesso_atendimento.dart';

void main() {
  testWidgets('cartão abre o atendimento existente', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return Scaffold(
          body: AcessoAtendimento(
        onAbrir: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Conversa')),
                body: const Text('Conversa da cotação A')))),
        child: const SizedBox(
            width: 300, height: 120, child: Text('Decoração · cliente A')),
      ));
    })));
    await tester.tap(find.text('Decoração · cliente A'));
    await tester.pumpAndSettle();
    expect(find.text('Conversa da cotação A'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Decoração · cliente A'), findsOneWidget);
  });

  testWidgets('resposta e IA não disparam abertura do cartão', (tester) async {
    var aberturas = 0, respostas = 0, sugestoes = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AcessoAtendimento(
      onAbrir: () => aberturas++,
      child: Row(children: [
        TextButton(
            onPressed: () => respostas++, child: const Text('Responder')),
        TextButton(onPressed: () => sugestoes++, child: const Text('Gerar IA')),
      ]),
    ))));
    await tester.tap(find.text('Responder'));
    await tester.tap(find.text('Gerar IA'));
    expect(respostas, 1);
    expect(sugestoes, 1);
    expect(aberturas, 0);
  });

  testWidgets('cartão aceita navegação por teclado', (tester) async {
    var aberturas = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AcessoAtendimento(
      onAbrir: () => aberturas++,
      child: const Text('Atendimento'),
    ))));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(aberturas, 1);
  });
}
