import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_comando_texto_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_revisao_pos_evento_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_ficha_tecnica_dialog.dart';
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;
import 'calculadora_composicao_test.dart' show AiQA;
import 'plano_execucao_test.dart' show itemExec;

class RepoRevisao extends RepoJornada {
  bool falhar = false;
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) {
    if (falhar) throw StateError('Conexão interrompida');
    return super.alterarOperacaoEvento(id, acao);
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
  });
  tearDown(() => Get.reset());
  Future<CalculadoraFestaController> preparar(RepoJornada repo) async {
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    await c.prepararCalculadora(
        idEvento: 'evento',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    c.atualizarCardapio([itemExec('almoco')],
        titulo: 'Almoço', disponivel: true);
    return c;
  }

  void telaPequena(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.resetViewInsets();
    });
  }

  Future<void> abrir(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        showDialog<void>(context: ctx, builder: (_) => dialog),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'texto revê conjunto, permite corrigir e aplica sem erro em tela pequena',
      (tester) async {
    telaPequena(tester);
    final c = await preparar(RepoJornada());
    addTearDown(c.onClose);
    await abrir(tester, CalculadoraComandoTextoDialog(controller: c));
    await tester.enterText(find.byType(TextField),
        'planeje para 30 adultos e 8 crianças; duração 6 horas');
    await tester.tap(find.text('Preparar ajustes'));
    await tester.pumpAndSettle();
    expect(c.totalAdultos.value, 20);
    expect(find.textContaining('Público manual da festa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'planeje para 37 adultos');
    await tester.pump();
    expect(find.text('Usar estes ajustes'), findsNothing);
    await tester.tap(find.text('Preparar ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar estes ajustes'));
    await tester.pumpAndSettle();
    expect(c.totalAdultos.value, 37);
    expect(find.byType(CalculadoraComandoTextoDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('texto fica acessível com teclado e fonte ampliada',
      (tester) async {
    telaPequena(tester);
    final c = await preparar(RepoJornada());
    addTearDown(c.onClose);
    await abrir(tester, CalculadoraComandoTextoDialog(controller: c));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'planeje para 30 adultos');
    await tester.pumpAndSettle();
    expect(find.text('Preparar ajustes').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Fechar').hitTestable(), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    final campo = tester.getRect(find.byType(TextField));
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    expect(campo.top, greaterThanOrEqualTo(viewport.top));
    expect(campo.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'revisão mantém erro e respostas para retomar, persiste encerramento qualitativo',
      (tester) async {
    telaPequena(tester);
    final repo = RepoRevisao();
    final c = await preparar(repo);
    addTearDown(c.onClose);
    await abrir(tester,
        CalculadoraRevisaoPosEventoDialog(controller: c, onMedir: (_) {}));
    await tester.tap(find.text('Concluir revisão'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Avalie cada item'), findsOneWidget);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sobrou').last);
    await tester.pumpAndSettle();
    repo.falhar = true;
    await tester.tap(find.text('Concluir revisão'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Conexão interrompida'), findsOneWidget);
    expect(repo.operacao['revisao_pos_evento'], isNull);
    repo.falhar = false;
    await tester.tap(find.text('Concluir revisão'));
    await tester.pumpAndSettle();
    expect(repo.operacao['revisao_pos_evento']['almoco']['itens']['arroz'],
        'sobrou');
    expect(
        repo.operacao['revisao_pos_evento']['almoco']['status'], 'concluida');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'colar receita prepara ficha editável e rejeita texto sem medidas',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await abrir(
        tester,
        const CalculadoraFichaTecnicaDialog(
            prato: 'Minha receita', unidade: 'kg', estado: 'pronto'));
    await tester.tap(find.text('Colar receita com medidas'));
    await tester.pumpAndSettle();
    final campo = find.widgetWithText(TextField, 'Receita com medidas');
    await tester.enterText(campo, 'Rende 2 kg pronto\num pouco de arroz');
    await tester.tap(find.text('Preparar ficha'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ingrediente não interpretado'), findsOneWidget);
    await tester.enterText(
        campo, 'Rende 2,5 kg pronto\n500 g arroz (seco)\n1 L água (pronto)');
    await tester.tap(find.text('Preparar ficha'));
    await tester.pumpAndSettle();
    expect(find.text('arroz'), findsOneWidget);
    expect(find.text('água'), findsOneWidget);
    expect(find.text('2,5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
