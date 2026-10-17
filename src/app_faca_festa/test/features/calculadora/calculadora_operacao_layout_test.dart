import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_operacao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_integridade_ponta_a_ponta_test.dart' show controller;
import 'calculadora_operacao_evento_test.dart' show RepoOperacao;

class RepoDemorado extends RepoOperacao {
  final liberar = Completer<void>();
  int chamadas = 0;
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) async {
    chamadas++;
    await liberar.future;
    return super.alterarOperacaoEvento(id, acao);
  }
}

void main() {
  Future<CalculadoraFestaController> abrir(WidgetTester tester,
      {RepoOperacao? repo, bool publico = false}) async {
    final c = controller(repo: repo ?? RepoOperacao());
    c.idCardapioAtual = 'almoco';
    c.operacaoEvento.clear();
    addTearDown(c.onClose);
    await tester.pumpWidget(GetMaterialApp(
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => publico
                            ? CalculadoraOperacaoDialog(controller: c)
                            : CalculadoraEstoqueDialog(controller: c)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return c;
  }

  void telaPequena(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
  }

  testWidgets('estoque usa uma janela e voltar ou cancelar não cadastram lote',
      (tester) async {
    final c = await abrir(tester);
    expect(find.text('Seu estoque começa aqui'), findsOneWidget);
    await tester.tap(find.text('Cadastrar lote'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Novo lote'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Rascunho');
    await tester.tap(find.byTooltip('Voltar ao estoque'));
    await tester.pumpAndSettle();
    expect(find.text('Seu estoque começa aqui'), findsOneWidget);
    expect(c.operacaoEvento['lotes'], isNull);
    await tester.tap(find.text('Cadastrar lote'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(c.operacaoEvento['lotes'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'voltar do Android retorna ao estoque sem empilhar ou descartar a janela',
      (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Cadastrar lote'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Seu estoque começa aqui'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'lote valida e salva decimal com teclado e texto ampliado em 320 px',
      (tester) async {
    telaPequena(tester);
    final repo = RepoOperacao();
    await abrir(tester, repo: repo);
    await tester.tap(find.text('Cadastrar lote'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Identifique o lote'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Arroz');
    await tester.enterText(find.byType(TextFormField).at(1), '1,5');
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Salvar').hitTestable(),
        findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect((repo.dados['lotes'] as Map).values.single['total'], 1.5);
    expect(find.text('1,5 kg livres'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('público mantém salvar acessível com teclado em tela pequena',
      (tester) async {
    telaPequena(tester);
    final repo = RepoOperacao();
    await abrir(tester, repo: repo, publico: true);
    await tester.ensureVisible(find.text('Usar público da festa'));
    await tester.tap(find.text('Usar público da festa'));
    await tester.pumpAndSettle();
    final adultos = find.byKey(const ValueKey('publico-adultos'));
    await tester.ensureVisible(adultos);
    await tester.enterText(adultos, '12');
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pumpAndSettle();
    expect(find.text('Salvar ajustes').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Salvar ajustes'));
    await tester.pumpAndSettle();
    expect(repo.dados['refeicoes']['almoco']['publico']['adultos'], 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mudança concorrente mantém rascunho e pede reabrir o formulário',
      (tester) async {
    final repo = RepoOperacao();
    final c = await abrir(tester, repo: repo);
    await tester.tap(find.text('Cadastrar lote'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Arroz');
    c.operacaoEvento['revisao'] = 1;
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('O estoque mudou'), findsOneWidget);
    expect(repo.dados, isEmpty);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Arroz');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('salvamento em andamento bloqueia saída e envio duplicado',
      (tester) async {
    final repo = RepoDemorado();
    await abrir(tester, repo: repo);
    await tester.tap(find.text('Cadastrar lote'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Arroz');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();
    expect(repo.chamadas, 1);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Salvando...'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
            .onPressed,
        isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Novo lote'), findsOneWidget);
    repo.liberar.complete();
    await tester.pumpAndSettle();
    expect(find.text('Novo lote'), findsNothing);
    expect(repo.chamadas, 1);
    expect(tester.takeException(), isNull);
  });
}
