import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/data/datasources/remote/central_mediacao_remote.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/central_mediacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/central_mediacao_page.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/central_mediacao_detalhe_page.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/widgets/financeiro_contexto.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_repository.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_admin_snapshot.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/dashboard_financeiro_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart';

const _oportunidade = {
  'idOrcamento': 'oportunidade',
  'idEvento': 'evento',
  'nomeEvento': 'Celebração de aniversário da família',
  'nomeServico': 'Decoração temática completa',
  'nomeContratante': 'Organizadora de teste',
  'estadoComercial': 'oportunidade',
  'estadoExecucao': 'nao_iniciado',
  'valorContratadoCentavos': 165000,
  'aReceberClienteCentavos': 165000,
};
final _contrato = {
  ..._oportunidade,
  'idOrcamento': 'contrato',
  'estadoComercial': 'contratado',
  'nomeFornecedor': 'Fornecedor de decoração e organização de eventos',
  'comissao_centavos': 8250,
  'liquido_fornecedor_centavos': 156750,
  'casoAberto': true,
};

class _Remote extends Fake implements CentralMediacaoRemote {
  String? ultimoFiltro;
  String estadoDetalhe = 'oportunidade';
  @override
  Future<Map<String, dynamic>> consultarCentral(
      {String? busca,
      String? estadoComercial,
      String? estadoExecucao,
      bool? casoAberto,
      String? idResponsavel,
      String eixoTemporal = 'data_evento',
      String? periodoInicio,
      String? periodoFim,
      bool agruparPorEvento = false,
      int offset = 0,
      int limite = 50}) async {
    ultimoFiltro = estadoComercial;
    final linhas = [_oportunidade, _contrato]
        .where((m) =>
            estadoComercial == null ||
            estadoComercial.isEmpty ||
            m['estadoComercial'] == estadoComercial)
        .toList();
    return {
      'linhas': linhas,
      'paginacao': {'total_filtrado_amostra': linhas.length}
    };
  }

  @override
  Future<Map<String, dynamic>> consultarDetalhe(
          {required String idOrcamento}) async =>
      {
        'resumo': {..._oportunidade, 'estadoComercial': estadoDetalhe},
        'contratacao_servico': {
          'estado_comercial': estadoDetalhe,
          'nome_servico': 'Decoração temática completa'
        },
        'financeiro': {'valorContratadoCentavos': 165000},
      };
}

const _captura = ValueKey('ergonomia-captura');

class _Fornecedores extends Fake implements FornecedorRepository {
  @override
  Future<FornecedorAdminSnapshot> carregarSnapshotAdmin(
          {required bool incluirEnderecos}) async =>
      FornecedorAdminSnapshot(
          fornecedores: [
            Fornecedor(
                idFornecedor: 'fornecedor-id',
                idUsuario: 'usuario',
                razaoSocial: 'Decora Festas',
                telefone: '',
                email: '',
                dataCadastro: DateTime(2026))
          ],
          enderecos: [],
          categoriasFornecedor: [],
          categorias: [],
          subcategorias: [],
          servicosFornecedor: []);
}

Future<void> _abrir(
    WidgetTester tester, Widget tela, Size tamanho, double escala) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = tamanho;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(RepaintBoundary(
      key: _captura,
      child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Poppins',
              colorSchemeSeed: const Color(0xFF0F766E)),
          builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!),
          home: tela)));
  await tester.pumpAndSettle();
}

Future<void> _capturar(WidgetTester tester, String nome) async {
  if (!const bool.fromEnvironment('CAPTURAS_ERGONOMIA')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captura));
  await tester.runAsync(() async {
    final imagem = await boundary.toImage();
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    final arquivo = File('.dart_tool/capturas-ergonomia/$nome.png');
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
      final loader = FontLoader('Poppins_${peso.key}')
        ..addFont(rootBundle.load('assets/fonts/Poppins-${peso.value}.ttf'));
      await loader.load();
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

  for (final tamanho in [const Size(360, 1000), const Size(1366, 1000)]) {
    testWidgets('visão financeira $tamanho pesquisa fornecedor e aplica seu ID',
        (tester) async {
      Get.put<FornecedorRepository>(_Fornecedores());
      String? fornecedorConsultado;
      final controller = DashboardFinanceiroAdminController(consultarFn: (
          {required eixoTemporal,
          periodoInicio,
          periodoFim,
          idFornecedor,
          estado}) async {
        fornecedorConsultado = idFornecedor;
        return {
          'completo': true,
          'receitaPlataformaCentavos': 0,
          'volumeContratadoCentavos': 315000,
          'comissaoGeradasCentavos': 15750,
          'comissaoAReceberCentavos': 15750,
          'comissaoConfigurada': true,
          'qtdEventos': 1,
          'qtdContratos': 1,
          'qtdServicosDistintos': 1,
          'qtdFornecedoresDistintos': 1,
          'linhasEvento': [
            {
              'idEvento': 'evento',
              'nomeEvento': 'Celebração de aniversário da família',
              'status': 'pendente',
              'qtdContratos': 1,
              'contratadoCentavos': 315000,
              'pagoCentavos': 0,
              'saldoCentavos': 315000,
              'comissaoCentavos': 15750
            }
          ],
          'linhasContratacao': [
            {
              ..._contrato,
              'contratado': true,
              'valorContratadoCentavos': 315000
            }
          ]
        };
      });
      await _abrir(
          tester,
          DashboardFinanceiroAdminPage(
              controller: controller, themeController: EventThemeController()),
          tamanho,
          tamanho.width == 360 ? 2 : 1);
      await _capturar(tester, 'visao-financeira-${tamanho.width.toInt()}');
      final filtros = find.text('Filtrar consulta');
      await tester.scrollUntilVisible(filtros, 250,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(filtros);
      await tester.pumpAndSettle();
      final seletor = find.widgetWithText(TextFormField, 'Fornecedor');
      await tester.ensureVisible(seletor);
      await tester.tap(seletor);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Buscar fornecedor'), 'decora');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decora Festas'));
      await tester.pumpAndSettle();
      expect(controller.filtroFornecedor.value, 'fornecedor-id');
      expect(fornecedorConsultado, anyOf(isNull, ''));
      final aplicar = find.text('Aplicar filtros');
      await tester.ensureVisible(aplicar);
      await tester.tap(aplicar);
      await tester.pumpAndSettle();
      expect(fornecedorConsultado, 'fornecedor-id');
      if (tamanho.width > 1000) {
        final secao = find.text('Por contratação');
        await tester.scrollUntilVisible(secao, 300,
            scrollable: find.byType(Scrollable).first);
        await Scrollable.ensureVisible(tester.element(secao), alignment: 0);
        await tester.pumpAndSettle();
        await _capturar(tester, 'visao-tabela');
        expect(tester.getRect(find.text('Valor')).right,
            lessThan(tester.getRect(find.text('Situação').last).left));
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final largura in [360.0, 768.0, 1366.0, 1920.0]) {
    for (final escala in [1.0, 2.0]) {
      testWidgets(
          'lista $largura escala $escala distingue estimativa e contrato',
          (tester) async {
        final remote = _Remote();
        final controller = CentralMediacaoController(remote: remote);
        await _abrir(
            tester,
            CentralMediacaoPage(
                controller: controller,
                themeController: EventThemeController()),
            Size(largura, 1000),
            escala);
        await _capturar(tester, 'lista-${largura.toInt()}-${escala.toInt()}');
        final oportunidade =
            find.byKey(const ValueKey('contratacao-oportunidade'));
        await tester.scrollUntilVisible(oportunidade, 250,
            scrollable: find.byType(Scrollable).first);
        expect(
            find.descendant(
                of: oportunidade, matching: find.text('Valor estimado')),
            findsOneWidget);
        expect(
            find.descendant(
                of: oportunidade, matching: find.text('Cliente a pagar')),
            findsNothing);
        expect(
            find.descendant(
                of: oportunidade, matching: find.text('Recebido do cliente')),
            findsNothing);
        final contrato = find.byKey(const ValueKey('contratacao-contrato'));
        await tester.scrollUntilVisible(contrato, 250,
            scrollable: find.byType(Scrollable).first);
        expect(
            find.descendant(
                of: contrato, matching: find.text('Valor contratado')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('filtro explícito solicita apenas contratos', (tester) async {
    final remote = _Remote();
    final controller = CentralMediacaoController(remote: remote);
    await _abrir(
        tester,
        CentralMediacaoPage(
            controller: controller, themeController: EventThemeController()),
        const Size(1366, 1000),
        1);
    await tester.tap(find.text('Contratos'));
    await tester.pumpAndSettle();
    expect(remote.ultimoFiltro, 'contratado');
    expect(controller.linhas.length, 1);
    expect(controller.linhas.single.estadoComercial, 'contratado');
  });

  testWidgets('oportunidade no detalhe não apresenta dívida ou repasse',
      (tester) async {
    await _abrir(
        tester,
        CentralMediacaoDetalhePage(
            controller: CentralMediacaoController(remote: _Remote()),
            themeController: EventThemeController(),
            idOrcamento: 'oportunidade'),
        const Size(1366, 1000),
        1);
    await _capturar(tester, 'detalhe-oportunidade');
    expect(find.text('Valor estimado'), findsOneWidget);
    expect(find.text('A receber do cliente'), findsNothing);
    await tester.tap(find.text('Financeiro'));
    await tester.pumpAndSettle();
    expect(find.text('Aguardando contratação'), findsOneWidget);
    expect(find.text('Recebimentos e repasses'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final estado in ['Contratado', ' CONTRATADO ', 'contratado']) {
    testWidgets('detalhe normaliza estado $estado retornado pelo servidor',
        (tester) async {
      final remote = _Remote()..estadoDetalhe = estado;
      await _abrir(
          tester,
          CentralMediacaoDetalhePage(
              controller: CentralMediacaoController(remote: remote),
              themeController: EventThemeController(),
              idOrcamento: 'contrato'),
          const Size(1366, 1000),
          1);
      expect(find.text('Contratação confirmada'), findsOneWidget);
      expect(find.text('Valor contratado'), findsOneWidget);
      expect(find.text('Valor estimado'), findsNothing);
      expect(find.text('Próximo passo: confirmar a contratação'), findsNothing);
      await tester.tap(find.text('Financeiro'));
      await tester.pumpAndSettle();
      expect(find.text('Aguardando contratação'), findsNothing);
      expect(find.text('Recebimentos e repasses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ajuda abre por ação explícita em tela estreita e texto ampliado',
      (tester) async {
    await _abrir(
        tester,
        const Scaffold(
            body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: FinanceiroAjuda(itens: ajudaFinanceira))),
        const Size(360, 1000),
        2);
    await tester.tap(find.text('Como funciona esta tela'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo do fornecedor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
