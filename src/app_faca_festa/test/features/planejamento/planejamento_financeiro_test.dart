import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_faca_festa/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/planejamento_financeiro_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/planejamento_financeiro_page.dart';

class Store implements RecebimentoPendenteStore {
  final m = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>?> ler(String u) async => m[u];
  @override
  Future<void> salvar(String u, Map<String, dynamic> d) async {
    m[u] = d;
  }

  @override
  Future<void> limpar(String u, {String? chave}) async {
    if (chave == null || m[u]?['chave'] == chave) m.remove(u);
  }
}

Map<String, dynamic> fixture() => {
      'geradoEm': '2026-10-26T12:00:00Z',
      'filtros': {'situacao': 'todas'},
      'config': {'revisao': 0},
      'completo': false,
      'avisos': ['Resultado direto parcial: deduções ausentes'],
      'movimentoLiquidoCentavos': 60000,
      'variacaoProjetadaCentavos': 60000,
      'saldoInicialCentavos': null,
      'saldoProjetadoCentavos': null,
      'semPrevisaoCentavos': 199250,
      'resultados': [
        {
          'idEvento': 'e',
          'nomeEvento': 'Festa de aniversário',
          'situacao': 'parcial',
          'brutoCentavos': 315000,
          'comissaoDeducoesCentavos': 15750,
          'custosPrevistosCentavos': 100000,
          'custosIncorridosCentavos': 0,
          'outrasPrevistasCentavos': null,
          'outrasIncorridasCentavos': null,
          'resultadoDiretoPrevistoCentavos': 199250,
          'resultadoDiretoRealizadoCentavos': 0,
          'recebidoCentavos': 100000,
          'saldoPendenteCentavos': 199250
        }
      ],
      'contas': [],
      'movimentos': [],
      'csv': 'gerado_em;2026-10-26\r\ntipo;valorCentavos\r\ncaixa;60000'
    };

class Gateway implements CallableSessaoGateway {
  String? uid = 'f';
  final stream = StreamController<String?>.broadcast();
  bool falha = false, timeout = false;
  Map<String, dynamic>? payload;
  Completer<Map<String, dynamic>>? leitura;
  final chamadas = <Map<String, dynamic>>[];
  @override
  String? get usuario => uid;
  @override
  Stream<String?> get sessoes => stream.stream;
  @override
  Future<Map<String, dynamic>> chamar(String f, Map<String, dynamic> d) async {
    chamadas.add({'funcao': f, 'dados': Map<String, dynamic>.from(d)});
    if (f == 'consultarPlanejamentoFornecedorFn') {
      if (falha) throw Exception('consulta incompleta');
      return leitura?.future ?? Future.value(payload ?? fixture());
    }
    if (timeout) {
      timeout = false;
      throw TimeoutException('persistiu');
    }
    return {'ok': true};
  }

  void trocar(String? u) {
    uid = u;
    stream.add(u);
  }
}

class DbCusto extends Fake implements FirebaseFirestore {}

class RemoteCusto extends Fake implements FinanceiroFornecedorRemoteDatasource {
  bool falha = true;
  final chaves = <String>[], fatos = <String>{};
  @override
  Future<Map<String, dynamic>> registrarCusto(
      {required String idFornecedor,
      required String idEvento,
      required String chaveIdempotencia,
      required int valorCentavos,
      String tipo = 'outro',
      String origem = 'manual',
      int previstoRestanteCentavos = 0,
      int desembolsoCentavos = 0,
      bool reutilizavel = false,
      String? descricao,
      String? categoria,
      String? idServico,
      String? referenciaComprovante}) async {
    chaves.add(chaveIdempotencia);
    fatos.add(chaveIdempotencia);
    if (falha) {
      falha = false;
      throw TimeoutException('após persistência');
    }
    return {'ok': true};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader('Poppins_700')
          ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf')))
        .load();
    final font = FontLoader('FinanceiroPoppins');
    for (final file in [
      'Poppins-Regular.ttf',
      'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf'
    ]) {
      font.addFont(Future.value(ByteData.sublistView(
          await File('assets/fonts/$file').readAsBytes())));
    }
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('custo legado reabre e retoma a mesma chave após timeout', () async {
    final remote = RemoteCusto(), store = Store();
    FinanceiroFornecedorController criar() => FinanceiroFornecedorController(
        firestore: DbCusto(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remote,
        pendenciasCustos: store,
        pendencias: Store());
    final c = criar();
    expect(
        await c.registrarCustoManual(
            idEvento: 'e', valorCentavos: 40000, desembolsoCentavos: 40000),
        false);
    expect(store.m, isNotEmpty);
    c.onClose();
    final novo = criar();
    expect(await novo.retomarCustoPendente(), true);
    expect(remote.chaves.toSet().length, 1);
    expect(remote.fatos.length, 1);
    expect(store.m, isEmpty);
    novo.onClose();
  });

  test('timeout e reabertura mantêm identidade/payload', () async {
    final g = Gateway(),
        s = Store(),
        c = PlanejamentoFinanceiroController(gateway: g, store: s);
    await c.iniciar();
    g.timeout = true;
    expect(
        await c.comandar('comandarPlanejamentoFornecedorFn',
            {'acao': 'baixar', 'valorCentavos': 40000},
            geracao: c.geracao),
        false);
    final original = g.chamadas.last;
    c.onClose();
    final novo = PlanejamentoFinanceiroController(gateway: g, store: s);
    await novo.iniciar();
    expect(novo.pendente.value, isNotNull);
    expect(await novo.retomar(), true);
    expect(
        g.chamadas
            .where((x) => x['funcao'] == 'comandarPlanejamentoFornecedorFn')
            .last,
        original);
    novo.onClose();
    await g.stream.close();
  });
  test('consulta antiga não sobrevive troca de sessão', () async {
    final g = Gateway(),
        c = PlanejamentoFinanceiroController(gateway: g, store: Store());
    await c.iniciar();
    c.filtros['idEvento'] = 'privado';
    g.leitura = Completer();
    final f = c.carregar();
    g.trocar(null);
    await Future<void>.delayed(Duration.zero);
    g.leitura!.complete(fixture());
    await f;
    expect(c.dados.value, isNull);
    expect(c.filtros, isEmpty);
    c.onClose();
    await g.stream.close();
  });
  for (final largura in [360.0, 1280.0]) {
    testWidgets(
        'planejamento usa cartões pulsantes na carga inicial e na atualização em $largura',
        (t) async {
      await t.binding.setSurfaceSize(Size(largura, 1200));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final g = Gateway()..leitura = Completer<Map<String, dynamic>>();
      final c = PlanejamentoFinanceiroController(gateway: g, store: Store());
      await t.pumpWidget(
          MaterialApp(home: PlanejamentoFinanceiroPage(controller: c)));
      expect(find.byType(OperacaoSkeleton), findsNWidgets(3));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('Nenhuma conta neste filtro.'), findsNothing);
      expect(find.text(r'R$ 0,00'), findsNothing);
      expect(t.takeException(), isNull);
      g.leitura!.complete(fixture());
      await t.pumpAndSettle();
      expect(find.byType(OperacaoSkeleton), findsNothing);
      expect(find.text('Saldo estimado com previsões'), findsOneWidget);
      g.leitura = Completer<Map<String, dynamic>>();
      final atualizar = c.carregar();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(OperacaoSkeleton), findsNWidgets(3));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Saldo estimado com previsões'), findsNothing);
      g.leitura!.complete(fixture());
      await atualizar;
      await t.pumpAndSettle();
      expect(find.byType(OperacaoSkeleton), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.onClose();
      await g.stream.close();
    });
  }
  testWidgets(
      'resultado previsto e caixa separados; desconhecido não vira zero',
      (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway(),
        c = PlanejamentoFinanceiroController(gateway: g, store: Store());
    await t.pumpWidget(
        MaterialApp(home: PlanejamentoFinanceiroPage(controller: c)));
    await t.pumpAndSettle();
    expect(find.text('R\$ 600,00'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('valor-Pode sobrar (previsto)')),
            matching: find.text('R\$ 1.992,50')),
        findsOneWidget);
    expect(find.text('Saldo estimado com previsões'), findsOneWidget);
    expect(find.text('Faltam informações para completar a estimativa'),
        findsOneWidget);
    expect(
        find.descendant(
            of: find
                .byKey(const ValueKey('valor-Saldo estimado com previsões')),
            matching: find.text('Não informado')),
        findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('exportação usa exatamente o CSV da consulta autorizada',
      (t) async {
    final g = Gateway(),
        c = PlanejamentoFinanceiroController(gateway: g, store: Store());
    String? csv;
    await t.pumpWidget(MaterialApp(
        home: PlanejamentoFinanceiroPage(
            controller: c,
            onExportar: (s) async {
              csv = s;
            })));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Baixar planilha (CSV)'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Baixar planilha (CSV)'));
    await t.pumpAndSettle();
    expect(csv, fixture()['csv']);
    expect(g.chamadas.length, 1);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('filtros enviados com datas explícitas sem cálculo local',
      (t) async {
    final g = Gateway(),
        c = PlanejamentoFinanceiroController(gateway: g, store: Store());
    await t.pumpWidget(
        MaterialApp(home: PlanejamentoFinanceiroPage(controller: c)));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Filtrar por evento e período'), 200,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(
        t.element(find.text('Filtrar por evento e período')),
        alignment: .1);
    await t.pumpAndSettle();
    await t.tap(find.text('Filtrar por evento e período'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('filtro-evento')));
    await t.tap(find.byKey(const Key('filtro-evento')));
    await t.pumpAndSettle();
    await t.tap(find.text('Festa de aniversário').last);
    await t.pumpAndSettle();
    final dataInicial = find.widgetWithText(TextField, 'Data inicial');
    final dataFinal = find.widgetWithText(TextField, 'Data final');
    await t.enterText(dataInicial, '01/10/2026');
    await t.enterText(dataFinal, '30/09/2026');
    await t.ensureVisible(find.text('Aplicar filtros'));
    await t.tap(find.text('Aplicar filtros'));
    await t.pumpAndSettle();
    expect(
        find.text('A data final deve ser igual ou posterior à inicial.'),
        findsOneWidget);
    expect(g.chamadas, hasLength(1));

    await t.enterText(dataFinal, '31/10/2026');
    await t.pumpAndSettle();
    final leitura = Completer<Map<String, dynamic>>();
    g.leitura = leitura;
    await t.ensureVisible(find.text('Aplicar filtros'));
    await t.tap(find.text('Aplicar filtros'));
    await t.pump();
    expect(c.carregando.value, isTrue);
    expect(find.text('Atualizando…'), findsOneWidget);
    expect(find.byKey(const Key('filtro-evento')), findsOneWidget);
    leitura.complete(fixture());
    await t.pumpAndSettle();
    expect(g.chamadas.last['dados']['idEvento'], 'e');
    expect(g.chamadas.last['dados']['inicio'], '2026-10-01');
    expect(g.chamadas.last['dados']['fim'], '2026-10-31');
    expect(
        find.text('Festa de aniversário · 01/10/2026 a 31/10/2026'),
        findsOneWidget);

    await t.ensureVisible(find.text('Limpar filtros'));
    await t.tap(find.text('Limpar filtros'));
    await t.pumpAndSettle();
    expect(g.chamadas.last['dados'], isEmpty);
    expect(find.text('Todos os eventos · Todo o período'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('falha apaga resumo e permite retry', (t) async {
    final g = Gateway()..falha = true,
        c = PlanejamentoFinanceiroController(gateway: g, store: Store());
    await t.pumpWidget(
        MaterialApp(home: PlanejamentoFinanceiroPage(controller: c)));
    await t.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Entradas menos saídas'), findsNothing);
    g.falha = false;
    await t.tap(find.text('Tentar novamente'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Entradas menos saídas'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(find.text('Entradas menos saídas'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('formulário antigo invalidado ao trocar sessão', (t) async {
    final g = Gateway(),
        c = PlanejamentoFinanceiroController(gateway: g, store: Store());
    await t.pumpWidget(
        MaterialApp(home: PlanejamentoFinanceiroPage(controller: c)));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Informar saldo de partida'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Informar saldo de partida'));
    await t.pumpAndSettle();
    g.trocar(null);
    await t.pumpAndSettle();
    expect(find.text('Sessão alterada'), findsOneWidget);
    expect(find.text('Confirmar dados revisados'), findsNothing);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('responsivo em 360 pixels sem overflow', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway(),
        c = PlanejamentoFinanceiroController(gateway: g, store: Store());
    await t.pumpWidget(
        MaterialApp(home: PlanejamentoFinanceiroPage(controller: c)));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  for (final size in [const Size(390, 844), const Size(1280, 1200)]) {
    testWidgets('clareza e responsividade em $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final g = Gateway()
        ..payload = {
          ...fixture(),
          'contas': [
            {
              'tipo': 'receber',
              'id': 'ct',
              'idEvento': 'e',
              'idContrato': 'contrato-interno',
              'descricao': 'Decoração temática',
              'situacao': 'sem_previsao',
              'origem': 'contrato_sem_canal_definido',
              'data': null,
              'originalCentavos': 299250,
              'baixadoCentavos': 100000,
              'saldoCentavos': 199250,
              'autorizadoCentavos': 0,
              'confirmadoCentavos': 100000,
            }
          ]
        };
      final c = PlanejamentoFinanceiroController(gateway: g, store: Store());
      await t.pumpWidget(MaterialApp(
          theme: ThemeData(
              fontFamily: 'FinanceiroPoppins',
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF009688))),
          home: MediaQuery(
            data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(size.width < 500 ? 1.3 : 1)),
            child: RepaintBoundary(
                key: const Key('visual-financeiro'),
                child: PlanejamentoFinanceiroPage(controller: c)),
          )));
      await t.pumpAndSettle();
      await expectLater(
          find.byKey(const Key('visual-financeiro')),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/financeiro-ergonomia-${size.width < 500 ? 'celular' : 'desktop'}.png'));
      await t.scrollUntilVisible(
          find.text('Definir data e forma de recebimento'), 250,
          scrollable: find.byType(Scrollable).first);
      await t.pumpAndSettle();
      expect(find.textContaining('sem_previsao'), findsNothing);
      expect(find.textContaining('contrato_sem_canal_definido'), findsNothing);
      expect(find.textContaining('contrato-interno'), findsNothing);
      expect(find.text('Falta definir como você vai receber'), findsOneWidget);
      expect(find.text('Vencimento: Ainda não definido; não indica atraso'),
          findsOneWidget);
      await expectLater(
          find.byKey(const Key('visual-financeiro')),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/financeiro-ergonomia-contas-${size.width < 500 ? 'celular' : 'desktop'}.png'));
      await t.ensureVisible(find.text('Histórico e identificação'));
      await t.tap(find.text('Histórico e identificação'));
      await t.pumpAndSettle();
      expect(find.textContaining('contrato-interno'), findsOneWidget);
      expect(
          find.textContaining('Evento: Festa de aniversário'), findsOneWidget);

      g.payload = {
        ...fixture(),
        'resultados': [],
        'contas': [
          {
            'tipo': 'receber',
            'id': 'ct-quitado',
            'idEvento': 'evento-interno',
            'nomeEvento': 'Evento com recebimento quitado',
            'descricao': 'Serviço quitado',
            'situacao': 'paga',
            'origem': 'contrato_sem_canal_definido',
            'originalCentavos': 17765,
            'baixadoCentavos': 17765,
            'saldoCentavos': 0,
            'confirmadoCentavos': 17765,
          }
        ],
      };
      await c.carregar();
      await t.pumpAndSettle();
      final titulo = find.text('Serviço quitado');
      await t.scrollUntilVisible(titulo, 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Quitada'), findsOneWidget);
      expect(find.text('Já recebido'), findsOneWidget);
      expect(find.text('Definir data e forma de recebimento'), findsNothing);
      expect(find.text('Falta definir como você vai receber'), findsNothing);
      final historico = find.text('Histórico e identificação');
      await t.ensureVisible(historico);
      await t.pumpAndSettle();
      await t.tap(historico);
      await t.pumpAndSettle();
      expect(find.textContaining('Evento: Evento com recebimento quitado'),
          findsOneWidget);
      expect(find.textContaining('evento-interno'), findsNothing);
      t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
      await t.pumpAndSettle();
      await t.tap(find.text('Filtrar por evento e período'));
      await t.pumpAndSettle();
      final evento = find.byKey(const Key('filtro-evento'));
      final inicio = find.widgetWithText(TextField, 'Data inicial');
      final fim = find.widgetWithText(TextField, 'Data final');
      expect(evento, findsOneWidget);
      expect(inicio, findsOneWidget);
      expect(fim, findsOneWidget);
      if (size.width < 500) {
        expect(t.getTopLeft(fim).dy, greaterThan(t.getTopLeft(inicio).dy));
      } else {
        expect(t.getTopLeft(fim).dy, t.getTopLeft(evento).dy);
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.onClose();
      await g.stream.close();
    });
  }
}
