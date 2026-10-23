import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_comando_texto_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_contexto_card.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;
import 'calculadora_jornada_test.dart' show EventoQA, CardapioQA, MigracaoQA;
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'calculadora_composicao_test.dart' show AiQA;
import 'ajustes_manuais_persistencia_test.dart' show ajuste;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/widgets/cadastro_passos_bar.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_modal.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
  });
  tearDown(() => Get.reset());
  Future<CalculadoraFestaController> preparar() async {
    final c = CalculadoraFestaController(
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'festa',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    return c;
  }

  void tamanho(WidgetTester tester, Size size, double fonte, double teclado) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: teclado);
    tester.platformDispatcher.textScaleFactorTestValue = fonte;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
  }

  Future<void> capturar(WidgetTester tester, GlobalKey key, String nome) async {
    if (Platform.environment['CALCULADORA_QA_CAPTURE'] != '1') return;
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final imagem = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
      final arquivo = File('.dart_tool/qa-jornada10/$nome.png');
      await arquivo.parent.create(recursive: true);
      await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
      imagem.dispose();
    });
  }

  Future<void> abrir(
      WidgetTester tester, Widget dialog, GlobalKey captura) async {
    await tester.runAsync(() async {
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
          .load();
    });
    await tester.pumpWidget(GetMaterialApp(
        builder: (_, child) => RepaintBoundary(key: captura, child: child!),
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
      'preço e fechamento ficam utilizáveis em paisagem; falha preserva valor e permite tentar novamente',
      (tester) async {
    tamanho(tester, const Size(640, 360), 1.6, 150);
    final key = GlobalKey();
    var chamadas = 0;
    await abrir(
        tester,
        CalculadoraRegraManualDialog(
            inicial: ajuste('almoco', 5.75, 'seco'),
            onSalvar: (_) async {
              chamadas++;
              if (chamadas == 1) {
                throw StateError(
                    'Conexão indisponível. Seus valores foram mantidos.');
              }
            }),
        key);
    final preco = find.widgetWithText(TextFormField, 'Preço por kg');
    await tester.ensureVisible(preco);
    await tester.enterText(preco, '850');
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(preco), alignment: .5);
    await tester.pumpAndSettle();
    final campo = tester.getRect(preco),
        janela = tester.getRect(find.byType(SingleChildScrollView));
    expect(campo.top, greaterThanOrEqualTo(janela.top));
    expect(campo.bottom, lessThanOrEqualTo(janela.bottom));
    expect(find.byTooltip('Fechar').hitTestable(), findsOneWidget);
    await capturar(tester, key, 'preco-paisagem-teclado');
    await tester.ensureVisible(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(find.text('Usar no cálculo').hitTestable(), findsOneWidget);
    await capturar(tester, key, 'preco-acao-paisagem-teclado');
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(chamadas, 1);
    expect(
        tester.widget<TextFormField>(preco).controller!.text, contains('8,50'));
    await tester.ensureVisible(find.byKey(const Key('erro_salvar_regra')));
    await capturar(tester, key, 'preco-falha-retomavel');
    await tester.ensureVisible(find.text('Usar no cálculo'));
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(chamadas, 2);
    expect(find.byType(CalculadoraRegraManualDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'texto revisa e confirma com teclado; cancelar IA retorna ao mesmo pedido',
      (tester) async {
    tamanho(tester, const Size(320, 568), 1.6, 240);
    final c = await preparar(), key = GlobalKey();
    await abrir(tester, CalculadoraComandoTextoDialog(controller: c), key);
    await tester.enterText(find.byType(TextField), 'planeje para 30 adultos');
    await tester.ensureVisible(find.text('Interpretar com IA'));
    await tester.tap(find.text('Interpretar com IA'));
    await tester.pumpAndSettle();
    expect(find.text('Leitura inteligente'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'planeje para 30 adultos');
    await tester.ensureVisible(find.text('Preparar ajustes'));
    await tester.tap(find.text('Preparar ajustes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confira os ajustes'));
    await tester.pumpAndSettle();
    await capturar(tester, key, 'texto-revisao-teclado');
    expect(c.totalAdultos.value, 20);
    await tester.ensureVisible(find.text('Usar estes ajustes'));
    await tester.tap(find.text('Usar estes ajustes'));
    await tester.pumpAndSettle();
    expect(c.totalAdultos.value, 30);
    expect(find.byType(CalculadoraComandoTextoDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('editor aberto fixa a sessão antes da primeira interação',
      (tester) async {
    final c = await preparar();
    final key = GlobalKey();
    await abrir(tester, CalculadoraComandoTextoDialog(controller: c), key);
    await c.prepararCalculadora(
        idEvento: 'festa',
        tipoEvento: 'Formatura',
        base: BaseCalculoFesta.manual,
        adultosManuais: 12);
    await tester.enterText(find.byType(TextField), 'planeje para 30 adultos');
    await tester.tap(find.text('Preparar ajustes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('O evento ou a sessão mudou'), findsOneWidget);
    expect(find.text('Usar estes ajustes'), findsNothing);
    expect(c.totalAdultos.value, 12);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'resumo distingue verba zero, consulta falha e rascunho isolado do evento ativo',
      (tester) async {
    tamanho(tester, const Size(320, 568), 2, 0);
    final c = await preparar(), key = GlobalKey();
    c.atualizarOrcamentoDisponivel(0);
    c.verbaAlimentacao.value = 0;
    c.consultaFinanceiroIniciada.value = true;
    c.erroOrcamento.value = 'Consulta indisponível';
    var tentativas = 0;
    final evento = Evento(
        idEvento: 'outra',
        idUsuario: 'owner',
        idTipoEvento: 'festa',
        nomeEvento: 'Outro evento privado',
        localEvento: '',
        data: DateTime(2026, 10, 20));
    Future<void> mostrar() => tester.pumpWidget(GetMaterialApp(
        builder: (_, child) => RepaintBoundary(key: key, child: child!),
        home: Scaffold(
            body: SingleChildScrollView(
                child: CalculadoraContextoCard(
                    controller: c,
                    evento: evento,
                    onPublico: () {},
                    onEscolhas: () {},
                    onAtualizar: () {
                      tentativas++;
                    })))));
    await mostrar();
    await tester.pumpAndSettle();
    expect(find.textContaining('Outro evento privado'), findsNothing);
    await tester.tap(find.text('Contexto, verba e serviços'));
    await tester.pumpAndSettle();
    expect(find.textContaining('R\$\u00a00,00'), findsOneWidget);
    await tester.ensureVisible(find.text('Fontes que precisam de atenção'));
    await tester.tap(find.text('Fontes que precisam de atenção'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tentar atualizar fontes'));
    await tester.tap(find.text('Tentar atualizar fontes'));
    expect(tentativas, 1);
    await c.prepararCalculadora(
        idEvento: '',
        idSessao: 'isolado',
        permitirEstimativaSemEvento: true,
        tipoEvento: 'Formatura',
        base: BaseCalculoFesta.manual,
        adultosManuais: 12);
    await mostrar();
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Estimativa sem evento'), findsOneWidget);
    expect(find.textContaining('Outro evento privado'), findsNothing);
    await capturar(tester, key, 'contexto-rascunho-fonte-ampliada');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'falha ao guardar rascunho é visível e permite retomar sem perder os valores',
      (tester) async {
    tamanho(tester, const Size(320, 568), 1.4, 0);
    final calc = CalculadoraFestaController(
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    final menus = CardapioController(repository: CardapioQA()),
        tema = EventThemeController();
    Get.put(tema);
    addTearDown(calc.onClose);
    addTearDown(menus.onClose);
    var falhar = true, confirmados = 0;
    await tester.pumpWidget(GetMaterialApp(
        home: CalculadoraFestaScreen(
            idEvento: '',
            idRascunho: 'rascunho10',
            permitirEstimativaSemEvento: true,
            tipoEvento: 'Formatura',
            adultosIniciais: 12,
            calculadoraController: calc,
            eventoController: EventoQA(),
            themeController: tema,
            cardapioController: menus,
            fornecedorMigracaoAdminController: MigracaoQA(),
            persistirRascunho: (r) async {
              if (falhar) throw StateError('Disco indisponível');
              confirmados++;
              expect(r.adultos, 12);
            })));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tentar guardar novamente'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível guardar a estimativa'),
        findsOneWidget);
    expect(find.text('Estimativa guardada neste aparelho.'), findsNothing);
    expect(calc.totalAdultos.value, 12);
    expect(confirmados, 0);
    falhar = false;
    await tester.scrollUntilVisible(find.text('Tentar guardar novamente'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar guardar novamente'));
    await tester.pumpAndSettle();
    expect(confirmados, 1);
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Estimativa guardada neste aparelho.'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Estimativa guardada neste aparelho.'), findsOneWidget);
    expect(calc.idEventoAtual.value, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ações do cadastro crescem com fonte ampliada em tela estreita',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: CadastroPassosAcoes(
                    cor: Colors.green,
                    continuarLabel: 'Revisar e continuar',
                    onContinuar: () {},
                    onVoltar: () {})))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final botao = tester.getRect(find.byType(ElevatedButton));
    final texto = tester.getRect(find.text('Revisar e continuar'));
    expect(botao.contains(texto.topLeft) && botao.contains(texto.bottomRight),
        isTrue);
  });
  testWidgets('modal mantém campo e ação alcançáveis em paisagem com teclado',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CalculadoraModal(
                titulo: 'Planejamento de quantidades e preços',
                icone: Icons.edit,
                onFechar: () {},
                rodape: FilledButton(
                    onPressed: () {},
                    child: const Text('Aplicar ao planejamento')),
                child: const TextField(
                    decoration: InputDecoration(labelText: 'Preço por kg'))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '8,50');
    await tester.ensureVisible(find.text('Aplicar ao planejamento'));
    expect(find.text('Aplicar ao planejamento').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Fechar').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
