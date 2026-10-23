import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/dashboard_financeiro_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

Map<String, dynamic> _fixturePreenchido() => {
      'volumeContratadoCentavos': 10000000,
      'comissaoGeradasCentavos': 500000,
      'comissaoRecebidasCentavos': 200000,
      'comissaoAReceberCentavos': 300000,
      'receitaPlataformaCentavos': 200000,
      'comissaoConfigurada': true,
      'completo': true,
      'qtdEventos': 2,
      'qtdContratos': 3,
      'qtdServicosDistintos': 2,
      'qtdFornecedoresDistintos': 1,
      'qtdOportunidades': 0,
      'linhasEvento': [
        {
          'idEvento': 'evt-100',
          'status': 'contratado',
          'qtdContratos': 2,
          'qtdServicos': 1,
          'contratadoCentavos': 8000000,
          'pagoCentavos': 4000000,
          'saldoCentavos': 4000000,
          'comissaoCentavos': 400000,
        },
        {
          'idEvento': 'evt-200',
          'status': 'contratado',
          'qtdContratos': 1,
          'qtdServicos': 1,
          'contratadoCentavos': 2000000,
          'pagoCentavos': 2000000,
          'saldoCentavos': 0,
          'comissaoCentavos': 100000,
        },
      ],
    };

Map<String, dynamic> _fixtureVazio() => {
      'volumeContratadoCentavos': 0,
      'comissaoGeradasCentavos': 0,
      'comissaoRecebidasCentavos': 0,
      'comissaoAReceberCentavos': 0,
      'receitaPlataformaCentavos': 0,
      'comissaoConfigurada': true,
      'completo': true,
      'qtdEventos': 0,
      'qtdContratos': 0,
      'qtdServicosDistintos': 0,
      'qtdFornecedoresDistintos': 0,
      'qtdOportunidades': 0,
      'linhasEvento': <Map<String, dynamic>>[],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  test('filtros pendentes bloqueiam alinhamento com exportação', () async {
    final c = DashboardFinanceiroAdminController(
      consultarFn: ({
        required eixoTemporal,
        periodoInicio,
        periodoFim,
        idFornecedor,
        estado,
      }) async =>
          _fixturePreenchido(),
    );
    await c.carregar();
    expect(c.filtrosPendentes.value, isFalse);
    expect(c.exportarCsv(), contains('evt-100'));

    c.eixoTemporal.value = 'data_contratacao';
    c.marcarFiltroAlterado();
    expect(c.filtrosPendentes.value, isTrue);
  });

  test('CSV usa o recorte da última consulta', () async {
    var eixoUsado = '';
    final c = DashboardFinanceiroAdminController(
      consultarFn: ({
        required eixoTemporal,
        periodoInicio,
        periodoFim,
        idFornecedor,
        estado,
      }) async {
        eixoUsado = eixoTemporal;
        return _fixturePreenchido();
      },
    );
    c.eixoTemporal.value = 'data_contratacao';
    await c.carregar();
    expect(eixoUsado, 'data_contratacao');
    expect(c.eixoAplicado, 'data_contratacao');
    expect(c.exportarCsv().split('\n').length, greaterThan(2));
  });

  testWidgets('síntese distingue volume contratado de comissão', (tester) async {
    final theme = EventThemeController();
    final c = DashboardFinanceiroAdminController(
      consultarFn: ({
        required eixoTemporal,
        periodoInicio,
        periodoFim,
        idFornecedor,
        estado,
      }) async =>
          _fixturePreenchido(),
    );

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        home: DashboardFinanceiroAdminPage(
          controller: c,
          themeController: theme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visão financeira'), findsWidgets);
    expect(find.text('Movimentado em contratos'), findsOneWidget);
    expect(find.text('Comissão gerada'), findsOneWidget);
    expect(find.text('Não é receita da plataforma'), findsOneWidget);
    expect(find.text(NumericInput.dinheiro(100000)), findsOneWidget);
    expect(find.text(NumericInput.dinheiro(5000)), findsWidgets);
    expect(find.byTooltip('Copiar CSV'), findsOneWidget);
    expect(find.text('Baixar relatório'), findsNothing);
    expect(find.text('Data do evento'), findsWidgets);
    expect(find.textContaining('Recorte pela data do evento'), findsWidgets);
  });

  testWidgets('vazio distinto de falha de consulta', (tester) async {
    final theme = EventThemeController();
    final c = DashboardFinanceiroAdminController(
      consultarFn: ({
        required eixoTemporal,
        periodoInicio,
        periodoFim,
        idFornecedor,
        estado,
      }) async =>
          _fixtureVazio(),
    );
    await c.carregar();
    expect(c.resumo.value?['qtdEventos'], 0);

    // Altura generosa: ListView descarta filhos fora do cache e o finder falharia.
    await tester.binding.setSurfaceSize(const Size(390, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        home: DashboardFinanceiroAdminPage(
          controller: c,
          themeController: theme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum evento neste recorte'), findsOneWidget);
    expect(find.textContaining('não significa ausência'), findsNothing);

    c.erro.value = 'permission-denied';
    c.sincronizado.value = false;
    await tester.pump();
    expect(find.textContaining('Falha na consulta'), findsOneWidget);
  });

  testWidgets('erro sem resumo não aparece como lista vazia de eventos',
      (tester) async {
    final theme = EventThemeController();
    final c = DashboardFinanceiroAdminController(
      consultarFn: ({
        required eixoTemporal,
        periodoInicio,
        periodoFim,
        idFornecedor,
        estado,
      }) async {
        throw Exception('falha-sintetica');
      },
    );

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        home: DashboardFinanceiroAdminPage(
          controller: c,
          themeController: theme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('falha-sintetica'), findsOneWidget);
    expect(find.text('Nenhum evento neste recorte'), findsNothing);
    expect(find.text('Movimentado em contratos'), findsNothing);
  });
}
