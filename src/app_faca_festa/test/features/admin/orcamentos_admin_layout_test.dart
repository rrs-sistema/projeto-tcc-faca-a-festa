import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/orcamento_admin.dart';
import 'package:app_faca_festa/domain/repositories/orcamentos_admin_repository.dart';
import 'package:app_faca_festa/domain/usecases/carregar_orcamentos_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/orcamentos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/orcamentos_admin_list_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

OrcamentoAdmin _item(String id,
        {String evento = 'evento-1',
        double valor = 6500,
        double pago = 4200,
        double plano = 5500,
        String status = 'Pendente',
        String descricao = 'Decoração temática completa'}) =>
    OrcamentoAdmin(
        id: id,
        idEvento: evento,
        eventoNome: 'Celebração da família',
        tipoEvento: 'Aniversário',
        cidade: 'Curitiba · PR',
        dataEvento: DateTime(2027, 7, 11),
        categoria: descricao,
        custoEstimado: valor,
        pago: pago,
        status: status,
        custoTotalEvento: plano);

class _Repo implements OrcamentosAdminRepository {
  _Repo(this.itens);
  final List<OrcamentoAdmin> itens;
  @override
  Future<List<OrcamentoAdmin>> listarOrcamentosComEventoDetalhes() async =>
      itens;
}

const _captura = ValueKey('orcamentos-captura');
Future<OrcamentosAdminController> _abrir(
    WidgetTester tester, List<OrcamentoAdmin> itens,
    {double largura = 1440, double escala = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largura, largura < 600 ? 640 : 1080);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final c = OrcamentosAdminController(
      carregarOrcamentos: CarregarOrcamentosAdmin(_Repo(itens)));
  await tester.pumpWidget(RepaintBoundary(
      key: _captura,
      child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!),
          home: OrcamentosAdminListScreen(
              controller: c, themeController: EventThemeController()))));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _capturar(WidgetTester tester, String nome) async {
  if (!const bool.fromEnvironment('CAPTURAS_ORCAMENTOS')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captura));
  await tester.runAsync(() async {
    final imagem = await boundary.toImage();
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    final arquivo = File('.dart_tool/capturas-orcamentos/$nome.png');
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
    imagem.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final peso in {
      'regular': 'Regular',
      '500': 'Medium',
      '600': 'SemiBold',
      '700': 'Bold',
      '800': 'ExtraBold'
    }.entries) {
      await (FontLoader('Poppins_${peso.key}')
            ..addFont(
                rootBundle.load('assets/fonts/Poppins-${peso.value}.ttf')))
          .load();
    }
    await (FontLoader('Poppins')
          ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(Get.reset);

  test('eventos homônimos e sem ID não são unidos pelo nome', () {
    final grupos = GrupoOrcamentosAdmin.agrupar([
      _item('1'),
      _item('2', evento: 'evento-2'),
      _item('3', evento: ''),
      _item('4', evento: '')
    ]);
    expect(grupos.length, 4);
    expect(grupos.map((g) => g.chave).toSet().length, 4);
  });

  test(
      'percentual não oculta excedente e cancelados ficam fora do planejamento',
      () {
    final g = GrupoOrcamentosAdmin([
      _item('1', valor: 13386.40),
      _item('2', valor: 10000, status: 'Cancelado')
    ]);
    expect(g.estimadoCentavos, 1338640);
    expect(g.percentualPlanejado, closeTo(243.389, .001));
    expect(g.excedenteCentavos, 788640);
    expect(GrupoOrcamentosAdmin([_item('1', plano: 0)]).percentualPlanejado,
        isNull);
  });

  test('saldo por item não compensa pagamento excedente de outro item', () {
    final g = GrupoOrcamentosAdmin(
        [_item('1', valor: 100, pago: 150), _item('2', valor: 100, pago: 0)]);
    expect(g.saldoCentavos, 10000);
  });

  for (final largura in [360.0, 768.0, 1440.0]) {
    for (final escala in [1.0, 2.0]) {
      testWidgets(
          'orçamentos $largura escala $escala mantém valores e detalhe legíveis',
          (tester) async {
        await _abrir(tester,
            [_item('1', valor: 13386.40), _item('2', valor: 600, pago: 600)],
            largura: largura, escala: escala);
        await _capturar(tester, 'inicio-${largura.toInt()}-${escala.toInt()}');
        final abrir = find.byKey(const ValueKey('ver-itens-evento:evento-1'));
        await tester.scrollUntilVisible(abrir, 350,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(abrir);
        await tester.pumpAndSettle();
        final listaEventos =
            tester.state<ScrollableState>(find.byType(Scrollable).first);
        final posicaoEventos = listaEventos.position.pixels;
        expect(find.text('Ver detalhes'), findsNothing);
        await tester.tap(abrir);
        await tester.pumpAndSettle();
        expect(find.text('Itens do orçamento'), findsOneWidget);
        expect(find.byType(DataTable),
            largura == 1440 && escala == 1 ? findsOneWidget : findsNothing);
        await _capturar(tester, 'itens-${largura.toInt()}-${escala.toInt()}');
        final listaItens = find.descendant(
            of: find.byType(Dialog), matching: find.byType(Scrollable));
        final detalhes = find.text('Ver detalhes').first;
        await tester.scrollUntilVisible(detalhes, 350, scrollable: listaItens);
        await tester.ensureVisible(detalhes);
        await tester.pumpAndSettle();
        final posicaoItens =
            tester.state<ScrollableState>(listaItens).position.pixels;
        await tester.tap(detalhes);
        await tester.pumpAndSettle();
        expect(find.text('R\$ 13.386,40'), findsWidgets);
        expect(find.textContaining('R\$ 13386.40'), findsNothing);
        expect(find.text('Negociação: Pendente'), findsWidgets);
        await _capturar(tester, 'detalhe-${largura.toInt()}-${escala.toInt()}');
        await tester.tap(find.text('Voltar aos itens'));
        await tester.pumpAndSettle();
        expect(tester.state<ScrollableState>(listaItens).position.pixels,
            posicaoItens);
        await tester.tap(find.byTooltip('Fechar itens do orçamento'));
        await tester.pumpAndSettle();
        expect(find.text('Itens do orçamento'), findsNothing);
        expect(find.text('Ver detalhes'), findsNothing);
        expect(listaEventos.position.pixels, posicaoEventos);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'buscar um item não recalcula o planejamento com uma lista parcial',
      (tester) async {
    await _abrir(tester, [
      _item('1'),
      _item('2', valor: 600, pago: 600, descricao: 'Fotografia')
    ]);
    await tester.enterText(
        find.widgetWithText(TextField, 'Buscar na lista'), 'Fotografia');
    await tester.pumpAndSettle();
    expect(find.text('129,1% do planejamento'), findsOneWidget);
    final abrir = find.byKey(const ValueKey('ver-itens-evento:evento-1'));
    await tester.ensureVisible(abrir);
    await tester.pumpAndSettle();
    await tester.tap(abrir);
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Fotografia'),
        findsOneWidget);
    expect(find.text('Decoração temática completa'), findsNothing);
    expect(
        find.descendant(
            of: find.byType(Dialog),
            matching: find.text('1 de 2 itens · filtros ativos')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'modal lista somente os itens do evento selecionado entre homônimos',
      (tester) async {
    await _abrir(tester, [
      _item('1', valor: 13386.40),
      _item('2', evento: 'evento-2', plano: 0, descricao: 'Fotografia')
    ]);
    expect(find.byKey(const ValueKey('evento:evento-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('evento:evento-2')), findsOneWidget);
    expect(find.text('243,4% do planejamento'), findsOneWidget);
    expect(find.textContaining('Excedente de R\$ 7.886,40'), findsOneWidget);
    expect(find.text('Planejamento não definido'), findsOneWidget);
    await _capturar(tester, 'desktop-visao-geral');
    for (final (evento, item, outro) in [
      ('evento-1', 'Decoração temática completa', 'Fotografia'),
      ('evento-2', 'Fotografia', 'Decoração temática completa'),
    ]) {
      final abrir = find.byKey(ValueKey('ver-itens-evento:$evento'));
      await tester.ensureVisible(abrir);
      await tester.pumpAndSettle();
      await tester.tap(abrir);
      await tester.pumpAndSettle();
      expect(find.text(item), findsOneWidget);
      expect(find.text(outro), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(item), findsNothing);
    }
  });
}
