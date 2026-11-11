import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'dart:async';
import 'package:app_faca_festa/data/services/functions/diagnostico_consulta_financeira.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_faca_festa/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/financeiro_fornecedor_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

// Test double for the SDK boundary; integration is exercised against the emulator.
// ignore: subtype_of_sealed_class
class _Query extends Fake implements CollectionReference<Map<String, dynamic>> {
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
          {bool includeMetadataChanges = false,
          ListenSource source = ListenSource.defaultSource}) =>
      const Stream.empty();
  @override
  Query<Map<String, dynamic>> where(Object field,
          {Object? isEqualTo,
          Object? isNotEqualTo,
          Object? isLessThan,
          Object? isLessThanOrEqualTo,
          Object? isGreaterThan,
          Object? isGreaterThanOrEqualTo,
          Object? arrayContains,
          Iterable<Object?>? arrayContainsAny,
          Iterable<Object?>? whereIn,
          Iterable<Object?>? whereNotIn,
          bool? isNull}) =>
      this;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Doc();
}

// ignore: subtype_of_sealed_class
class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Query();
}

class _Db extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Query();
}

class _Pendencias implements RecebimentoPendenteStore {
  Map<String, dynamic>? op;
  @override
  Future<Map<String, dynamic>?> ler(String usuario) async => op;
  @override
  Future<void> salvar(String usuario, Map<String, dynamic> valor) async {
    op = valor;
  }

  @override
  Future<void> limpar(String usuario, {String? chave}) async {
    if (chave == null || op?['chave'] == chave) op = null;
  }
}

class _Remote extends Fake implements FinanceiroFornecedorRemoteDatasource {
  bool falhar = false, dois = false, credito = false, legado = false;
  final pedidos = <Map<String, dynamic>>[];
  double recebido = 0;
  final filtrosConsultados = <String?>[];
  bool incluirEventos = true;
  int consultasEventos = 0;
  @override
  Future<Map<String, dynamic>> consultarEventosDoPlanejamento() async {
    consultasEventos++;
    return {
      'resultados': [
        {'idEvento': 'e', 'nomeEvento': 'Festa de aniversário'}
      ]
    };
  }

  @override
  Future<Map<String, dynamic>> registrarRecebimento(
      {required String idFornecedor,
      required String idEvento,
      required String chaveIdempotencia,
      required int valorCentavos,
      String tipo = 'recebimento',
      bool execucaoConfirmada = false,
      String? idOrcamento,
      String? motivo,
      List<Map<String, dynamic>>? alocacoes,
      String? referenciaRecebimento}) async {
    pedidos.add({
      'alocacoes': alocacoes,
      'valorCentavos': valorCentavos,
      'execucaoConfirmada': execucaoConfirmada,
      'tipo': tipo,
      'referenciaRecebimento': referenciaRecebimento
    });
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> consultarResumo(
      {required String idFornecedor,
      String? idEvento,
      double? saldoInicial,
      double? comissao,
      double? taxas,
      double? tributos}) async {
    filtrosConsultados.add(idEvento);
    if (falhar) throw StateError('Indisponível');
    if (legado) {
      return {
        'ok': true,
        'contratado': 3150,
        'recebido': 0,
        'aReceber': 3150,
        'contratos': []
      };
    }
    final resultado = <String, dynamic>{
      if (incluirEventos)
        'eventos': [
          {'idEvento': 'e', 'nomeEvento': 'Festa de aniversário'},
          {'idEvento': 'outro', 'nomeEvento': 'Confraternização'}
        ],
      'origem': 'contratos_repasses',
      'liquidoPrevisto': 2992.5,
      'comissaoContratada': 157.5,
      'repasseAutorizado': 0,
      'contratado': 3150,
      'recebido': recebido,
      'aReceber': 2992.5 - recebido,
      'completo': false,
      'contratos': [
        {
          'id': 'c',
          'idOrcamento': 'orc-c',
          'idEvento': 'e',
          'nomeServico': 'Buffet sintético',
          'valorContratado': 3150,
          'comissao': 157.5,
          'liquidoPrevisto': 2992.5,
          'recebido': recebido,
          'aReceber': 2992.5 - recebido,
          'situacao': 'parcial',
          'revisao': 'r1'
        }
      ]
    };
    if (dois) {
      (resultado['contratos'] as List).add({
        'id': 'c2',
        'idEvento': 'e',
        'nomeServico': 'Decoração sintética',
        'valorContratado': 3000,
        'liquidoPrevisto': 3000,
        'recebido': 0
      });
    }
    if (credito) {
      resultado['aReceber'] = 0;
      resultado['creditoExcedente'] = 507.5;
      final contrato = (resultado['contratos'] as List).first as Map;
      contrato['saldoContrato'] = -507.5;
      contrato['recebido'] = 3500;
    }
    return resultado;
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => Get.reset());
  test(
      'resposta da versão publicada antiga recebe diagnóstico e mantém valores ausentes',
      () async {
    final remoto = _Remote()..legado = true;
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remoto,
        pendencias: _Pendencias(),
        pendenciasCustos: _Pendencias());
    await c.iniciar();
    expect(c.resumo.value, isNull);
    expect(c.vendas, isEmpty);
    expect(c.diagnosticoConsulta.value?.codigo, 'versao-incompativel');
    expect(c.erro.value, contains('precisa ser atualizado'));
    remoto.legado = false;
    await c.iniciar();
    expect(c.resumo.value!.aReceber, 2992.5);
    expect(c.diagnosticoConsulta.value, isNull);
    c.onClose();
  });
  test('diagnóstico diferencia política, serviço, timeout e versão', () {
    expect(
        diagnosticarConsultaFinanceira(const RespostaFinanceiraIncompativel())
            .codigo,
        'versao-incompativel');
    expect(
        diagnosticarConsultaFinanceira(const FinanceiroCallableException(
                'failed-precondition', 'Comissão ausente'))
            .mensagem,
        'Comissão ausente');
    expect(
        diagnosticarConsultaFinanceira(
                const FinanceiroCallableException('not-found'))
            .codigo,
        'not-found');
    expect(diagnosticarConsultaFinanceira(TimeoutException('limite')).codigo,
        'deadline-exceeded');
    expect(
        diagnosticarConsultaFinanceira(
                const FinanceiroCallableException('permission-denied'))
            .codigo,
        'permission-denied');
  });
  test(
      'nomes autorizados são recuperados para resumos antigos e limpos na saída',
      () async {
    final remote = _Remote()..incluirEventos = false;
    final c = FinanceiroFornecedorController(
        pendencias: _Pendencias(),
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remote);
    await c.iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(c.nomeEvento('e'), 'Festa de aniversário');
    expect(remote.consultasEventos, 1);
    c.aplicarFiltroEvento('e');
    await c.iniciar();
    expect(c.nomeEvento('e'), 'Festa de aniversário');
    expect(remote.consultasEventos, 1);
    c.aoTrocarSessao();
    expect(c.nomesEventos, isEmpty);
    c.onClose();
  });

  for (final largura in [360.0, 1200.0]) {
    testWidgets('filtro mostra nomes e envia somente o ID interno em $largura',
        (t) async {
      t.view.physicalSize = Size(largura, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final remote = _Remote();
      final c = FinanceiroFornecedorController(
          pendencias: _Pendencias(),
          firestore: _Db(),
          idFornecedor: 'f',
          usuarioAtual: () => 'f',
          remote: remote);
      await t.pumpWidget(GetMaterialApp(
          home: FinanceiroFornecedorPage(
              controller: c, themeController: EventThemeController())));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Filtrar evento'));
      await t.pumpAndSettle();
      expect(find.text('ID do evento'), findsNothing);
      await t.tap(find.byKey(const ValueKey('filtro-evento-financeiro')));
      await t.pumpAndSettle();
      await t.tap(find.text('Festa de aniversário').last);
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pumpAndSettle();
      expect(c.filtroEventoId.value, 'e');
      expect(remote.filtrosConsultados.last, 'e');
      expect(find.text('Filtro: Festa de aniversário'), findsOneWidget);
      expect(c.eventosConhecidosIds, contains('outro'));
      await t.tap(find.text('Limpar filtro'));
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pumpAndSettle();
      expect(remote.filtrosConsultados.last, isNull);
      expect(find.text('Mostrando todos os eventos'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.onClose();
    });
  }

  test('saldo líquido da entidade usa a projeção, mantendo o bruto', () {
    const v = VendaFornecedorFato(
        id: 'c',
        idEvento: 'e',
        valorContratado: 3150,
        liquidoPrevisto: 2992.5,
        recebidoConfirmado: 1000);
    expect(v.aReceber, 1992.5);
    expect(v.valorContratado, 3150);
  });
  test('comissão separa retenção e pagamento sem duplicar saldo', () {
    final o = <String, dynamic>{
      'valor_original': {'centavos': 15750},
      'valor_liquidado': {'centavos': 10000},
      'liquidado_por_retencao_repasse_centavos': 5263,
      'saldo_centavos': 5750,
      'status': 'a_vencer',
      'politica_aplicada': {'pagador': 'fornecedor'}
    };
    expect(ComissaoPlataformaController.retidaDe(o), 5263);
    expect(ComissaoPlataformaController.separadaDe(o), 4737);
    expect(ComissaoPlataformaController.saldoDe(o), 5750);
    expect(ComissaoPlataformaController.statusApresentacaoDe(o),
        'retencao_prevista');
  });
  for (final largura in [360.0, 1200.0]) {
    testWidgets(
        'resumo e lista mostram líquido e acompanham repasse em $largura',
        (tester) async {
      tester.view.physicalSize = Size(largura, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final remote = _Remote();
      final c = FinanceiroFornecedorController(
          pendencias: _Pendencias(),
          firestore: _Db(),
          idFornecedor: 'f',
          usuarioAtual: () => 'f',
          remote: remote);
      await tester.pumpWidget(GetMaterialApp(
          home: FinanceiroFornecedorPage(
              controller: c, themeController: EventThemeController())));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.resumo.value!.aReceber, 2992.5);
      expect(c.contratosListados.single.aReceber, 2992.5);
      expect(find.textContaining('2.992,50'), findsWidgets);
      remote.recebido = 1000;
      await tester.runAsync(() => c.iniciar());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.resumo.value!.aReceber, 1992.5);
      expect(c.contratosListados.single.aReceber, 1992.5);
      expect(find.textContaining('1.992,50'), findsWidgets);
      expect(tester.takeException(), isNull);
      c.onClose();
    });
  }
  testWidgets('indisponibilidade apaga valores e não exibe zero',
      (tester) async {
    final remote = _Remote()..falhar = true;
    final c = FinanceiroFornecedorController(
        pendencias: _Pendencias(),
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remote);
    await tester.pumpWidget(GetMaterialApp(
        home: FinanceiroFornecedorPage(
            controller: c, themeController: EventThemeController())));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.resumo.value, isNull);
    expect(c.vendas, isEmpty);
    expect(find.text('Consulta indisponível'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNothing);
    c.onClose();
  });
  testWidgets(
      'formulário exige distribuição válida, envia centavos sem presumir execução',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final remoto = _Remote()..dois = true;
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remoto,
        pendencias: _Pendencias());
    await tester.pumpWidget(GetMaterialApp(
        home: FinanceiroFornecedorPage(
            controller: c, themeController: EventThemeController())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Registrar despesa ou recebimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lançar recebimento próprio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Distribuir entre contratos'));
    await tester.pumpAndSettle();
    Finder campo(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    await tester.enterText(campo('Identificador do evento'), 'e');
    await tester.pumpAndSettle();
    await tester.enterText(campo('Valor (R\$)'), '500,00');
    await tester.enterText(campo('Buffet sintético'), '200,00');
    await tester.enterText(campo('Decoração sintética'), '301,00');
    await tester.tap(find.text('Registrar recebimento externo'));
    await tester.pumpAndSettle();
    expect(find.text('As alocações excedem o recebimento.'), findsOneWidget);
    expect(remoto.pedidos, isEmpty);
    await tester.enterText(campo('Decoração sintética'), '300,00');
    await tester.tap(find.text('Registrar recebimento externo'));
    await tester.pumpAndSettle();
    expect(remoto.pedidos.single['alocacoes'], [
      {'idContrato': 'c', 'valorCentavos': 20000},
      {'idContrato': 'c2', 'valorCentavos': 30000}
    ]);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(remoto.pedidos.single['execucaoConfirmada'], false);
    expect(tester.takeException(), isNull);
    c.onClose();
  });
  testWidgets('destaca o repasse recebido e abre o contrato selecionado',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: _Remote()..recebido = 2992.5,
        pendencias: _Pendencias());
    await tester.pumpWidget(GetMaterialApp(
      home: FinanceiroFornecedorPage(
          controller: c, themeController: EventThemeController()),
      getPages: [
        GetPage(
          name: '/acompanhamento-fornecedor',
          page: () => Scaffold(
              body: Text('Contrato ${(Get.arguments as Map)['idOrcamento']}')),
        ),
      ],
    ));
    await tester.pumpAndSettle();
    final servico = find.text('Buffet sintético');
    await tester.ensureVisible(servico);
    await tester.pumpAndSettle();
    expect(find.text('Repasse quitado'), findsOneWidget);
    expect(find.text('Repasse recebido'), findsOneWidget);
    expect(find.text('Já recebido'), findsOneWidget);
    expect(find.text('R\$ 2.992,50'), findsWidgets);
    expect(find.text('A receber'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(servico);
    await tester.pumpAndSettle();
    expect(find.text('Contrato orc-c'), findsOneWidget);
    c.onClose();
  });

  testWidgets('crédito excedente permanece visível no resumo e contrato',
      (tester) async {
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: _Remote()..credito = true,
        pendencias: _Pendencias());
    await tester.pumpWidget(GetMaterialApp(
        home: FinanceiroFornecedorPage(
            controller: c, themeController: EventThemeController())));
    await tester.pumpAndSettle();
    expect(c.contratosListados.single.aReceber, -507.5);
    expect(find.textContaining('Crédito excedente'), findsWidgets);
    expect(find.text('Repasse quitado'), findsNothing);
    c.onClose();
  });
  testWidgets('estorno parcial reverte explicitamente a alocação original',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final remoto = _Remote();
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remoto,
        pendencias: _Pendencias());
    await tester.pumpWidget(GetMaterialApp(
        home: FinanceiroFornecedorPage(
            controller: c, themeController: EventThemeController())));
    await tester.pumpAndSettle();
    c.recebimentos.assignAll(const [
      RecebimentoCaixaFato(
          id: 'original',
          idEvento: 'e',
          valorCentavos: 50000,
          alocacoes: {'c': 50000})
    ]);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Estornar'), 300);
    await tester.tap(find.text('Estornar'));
    await tester.pumpAndSettle();
    Finder campo(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    await tester.enterText(campo('Valor do estorno'), '125,00');
    await tester.enterText(campo('Reverter Buffet sintético'), '125,00');
    await tester.tap(find.text('Confirmar estorno'));
    await tester.pumpAndSettle();
    expect(remoto.pedidos.single['tipo'], 'estorno');
    expect(remoto.pedidos.single['referenciaRecebimento'], 'original');
    expect(remoto.pedidos.single['valorCentavos'], 12500);
    expect(remoto.pedidos.single['alocacoes'], [
      {'idContrato': 'c', 'valorCentavos': 12500}
    ]);
    expect(tester.takeException(), isNull);
    c.onClose();
  });
}
