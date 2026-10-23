import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_faca_festa/data/datasources/remote/comissao_plataforma_remote_datasource.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/comissao_plataforma_page.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/widgets/comissao_modal.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class _Functions extends Fake implements FirebaseFunctions {}

class _Gateway extends Fake implements FinanceiroCallableGateway {
  bool falhaConsulta = false;
  bool falhaRegistro = false;
  int escritas = 0;
  int? valorRegistrado;
  final obrigacao = <String, dynamic>{
    'id_obrigacao': 'cobranca-123',
    'id_evento': 'evento-456',
    'id_contrato': 'contrato-789',
    'valor_original_centavos': 15750,
    'valor_liquidado_centavos': 0,
    'base_elegivel_centavos': 315000,
    'politica_aplicada': {'percentual_bps': 500},
    'status': 'a_vencer',
  };

  @override
  Future<Map<String, dynamic>> call(String name,
      [Map<String, dynamic>? data,
      Duration timeout = const Duration(seconds: 90)]) async {
    if (name == 'liquidarComissaoManual') {
      escritas++;
      if (falhaRegistro) throw Exception('Falha no registro de teste');
      valorRegistrado = data!['valorCentavos'] as int;
      obrigacao['valor_liquidado_centavos'] = valorRegistrado;
      return {'saldoCentavos': 15750 - valorRegistrado!};
    }
    if (falhaConsulta) throw Exception('Consulta indisponível');
    return {
      'obrigacoes': [obrigacao],
      'politicas': <Map<String, dynamic>>[]
    };
  }
}

const _capturaKey = ValueKey('captura-comissoes');

Future<ComissaoPlataformaController> _abrir(
    WidgetTester tester, _Gateway gateway,
    {Size size = const Size(1440, 1000),
    double escala = 1,
    bool admin = false}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  final c = ComissaoPlataformaController(
    remote: ComissaoPlataformaRemoteDatasource(
        functions: _Functions(), gateway: gateway),
    usuarioAtual: () => 'usuario-teste',
    ehAdmin: () => admin,
  );
  await tester.pumpWidget(RepaintBoundary(
    key: _capturaKey,
    child: GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          fontFamily: 'Poppins',
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF4F46E5)),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(escala)),
          child: child!),
      home: ComissaoPlataformaPage(
          controller: c, themeController: EventThemeController()),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _detalhes(WidgetTester tester) async {
  final botao = find.text('Ver detalhes');
  if (botao.evaluate().isEmpty) {
    await tester.scrollUntilVisible(botao, 260,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(botao);
  await tester.pumpAndSettle();
  await tester.tap(botao);
  await tester.pumpAndSettle();
}

Future<void> _capturar(WidgetTester tester, String nome) async {
  if (!const bool.fromEnvironment('CAPTURAS_COMISSOES')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_capturaKey));
  await tester.runAsync(() async {
    final imagem = await boundary.toImage();
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.dart_tool/capturas-comissoes/$nome.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    imagem.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final variant in {
      'regular': 'Regular',
      '500': 'Medium',
      '600': 'SemiBold',
      '700': 'Bold',
      '800': 'ExtraBold'
    }.entries) {
      final loader = FontLoader('Poppins_${variant.key}');
      loader.addFont(
          rootBundle.load('assets/fonts/Poppins-${variant.value}.ttf'));
      await loader.load();
    }
    final regular = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    await regular.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(Get.reset);

  testWidgets('desktop: tabela ocupa o painel e detalhe abre centralizado',
      (tester) async {
    final gateway = _Gateway();
    await _abrir(tester, gateway);
    final painel =
        tester.getRect(find.byKey(const ValueKey('comissoes-tabela')));
    final tabela = tester.getRect(find.byType(DataTable));
    expect(tabela.width, closeTo(painel.width - 2, 2));
    expect(find.text('Saldo das comissões'), findsOneWidget);
    expect(find.text('Políticas'), findsNothing);
    await _capturar(tester, 'desktop-extrato');
    await _detalhes(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.getCenter(find.byType(Dialog)).dx, closeTo(720, 1));
    expect(find.text('Taxa desta contratação'), findsOneWidget);
    expect(find.text('5%'), findsWidgets);
    expect(find.text('Registrar recebimento'), findsNothing);
    await _capturar(tester, 'desktop-detalhe');
    await tester.tap(find.text('Fechar detalhes'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(gateway.escritas, 0);
    expect(tester.takeException(), isNull);
  });

  for (final escala in [1.0, 2.0]) {
    testWidgets(
        'celular 360px, fonte $escala: detalhe rola e fechar permanece acessível',
        (tester) async {
      await _abrir(tester, _Gateway(),
          size: const Size(360, 800), escala: escala);
      expect(find.byType(DataTable), findsNothing);
      await _detalhes(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(ComissaoModal), findsOneWidget);
      final fechar = find.text('Fechar detalhes');
      expect(tester.getRect(fechar).bottom, lessThan(800));
      if (escala == 1) await _capturar(tester, 'celular-detalhe');
      await tester.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(fechar);
      await tester.pumpAndSettle();
      expect(find.byType(ComissaoModal), findsNothing);
    });
  }

  testWidgets('simulador valida entrada e não altera o extrato',
      (tester) async {
    final gateway = _Gateway();
    final c = await _abrir(tester, gateway);
    await tester.tap(find.text('Simular comissão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calcular comissão'));
    await tester.pumpAndSettle();
    expect(find.text('Informe uma taxa de 0 a 100%.'), findsOneWidget);
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '5');
    await tester.enterText(campos.at(1), '10.000,00');
    await tester.tap(find.text('Calcular comissão'));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 500,00'), findsOneWidget);
    expect(c.totalAReceberCentavos, 15750);
    expect(gateway.escritas, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin: teclado não cobre ação e erro de registro mantém modal',
      (tester) async {
    final gateway = _Gateway()..falhaRegistro = true;
    await _abrir(tester, gateway, size: const Size(390, 844), admin: true);
    await _detalhes(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final campo = find.descendant(
        of: find.byType(ComissaoModal), matching: find.byType(TextField));
    await tester.ensureVisible(campo);
    await tester.enterText(campo, '0');
    final registrar = find.text('Registrar recebimento');
    expect(tester.getRect(registrar).bottom, lessThan(544));
    await tester.tap(registrar);
    await tester.pumpAndSettle();
    expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
    expect(gateway.escritas, 0);
    await tester.enterText(campo, '25,00');
    await tester.tap(registrar);
    await tester.pumpAndSettle();
    expect(gateway.escritas, 1);
    expect(find.byType(ComissaoModal), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(ComissaoModal),
            matching: find.textContaining('Falha no registro de teste')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro inicial não vira saldo zero ou nenhuma cobrança',
      (tester) async {
    await _abrir(tester, _Gateway()..falhaConsulta = true);
    expect(find.text('Extrato indisponível'), findsOneWidget);
    expect(find.text('Nenhuma comissão encontrada'), findsNothing);
    expect(find.byKey(const ValueKey('comissoes-saldo')), findsNothing);
  });

  testWidgets('paisagem: diálogo continua utilizável em altura de 390px',
      (tester) async {
    await _abrir(tester, _Gateway(), size: const Size(844, 390));
    await _detalhes(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.getRect(find.text('Fechar detalhes')).bottom, lessThan(390));
    await tester.drag(
        find.byType(SingleChildScrollView).last, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Fechar detalhes'));
    await tester.pumpAndSettle();
    expect(find.byType(ComissaoModal), findsNothing);
  });

  testWidgets(
      'admin: recebimento parcial usa centavos e fecha após confirmação',
      (tester) async {
    final gateway = _Gateway();
    final c = await _abrir(tester, gateway, admin: true);
    await _detalhes(tester);
    final campo = find.descendant(
        of: find.byType(ComissaoModal), matching: find.byType(TextField));
    await tester.ensureVisible(campo);
    await tester.pumpAndSettle();
    await tester.enterText(campo, '25,50');
    await tester.tap(find.text('Registrar recebimento'));
    await tester.pumpAndSettle();
    expect(gateway.escritas, 1);
    expect(gateway.valorRegistrado, 2550);
    expect(c.totalAReceberCentavos, 13200);
    expect(find.byType(ComissaoModal), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('crédito mantém sinal e taxa ausente não é inventada',
      (tester) async {
    final gateway = _Gateway();
    gateway.obrigacao['valor_liquidado_centavos'] = 20000;
    gateway.obrigacao.remove('politica_aplicada');
    await _abrir(tester, gateway);
    expect(find.text('Saldo em crédito'), findsOneWidget);
    await _detalhes(tester);
    expect(find.text('Crédito no extrato'), findsOneWidget);
    expect(find.text('Não informada'), findsOneWidget);
    expect(find.textContaining('-42,50'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
