import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/datasources/remote/jornada_atendimento_remote.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/jornada_atendimento.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/jornada_atendimento_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/pages/jornada_atendimento_page.dart';

class _Store implements RecebimentoPendenteStore {
  final ops = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>?> ler(String u) async => ops[u];
  @override
  Future<void> salvar(String u, Map<String, dynamic> o) async {
    ops[u] = o;
  }

  @override
  Future<void> limpar(String u, {String? chave}) async {
    if (chave == null || ops[u]?['chave'] == chave) ops.remove(u);
  }
}

Map<String, dynamic> _dados() => {
      'idCotacao': 'q',
      'idFornecedor': 'f',
      'idEvento': 'ev',
      'idOrcamento': null,
      'idContrato': null,
      'papel': 'fornecedor',
      'estadoComercial': 'nova_solicitacao',
      'estadoExecucao': null,
      'execucaoRevisao': 0,
      'cliente': {'nome': 'Cliente autorizado', 'id': 'c'},
      'evento': {
        'data': '2026-11-01T12:00:00Z',
        'local': 'Local compartilhado'
      },
      'proposta': null,
      'propostas': [],
      'condicoesAceitas': null,
      'escopo': 'Escopo inicial',
      'aviso': null,
      'motivo': null,
      'proxima': {
        'acao': 'Revisar e enviar proposta',
        'responsavel': 'fornecedor',
        'prazo': null
      },
      'chatAberto': true,
      'historico': [],
      'mediacoes': [],
      'prazoAgendado': null
    };

class _Gateway implements JornadaGateway {
  @override
  String? usuario = 'f';
  final auth = StreamController<String?>.broadcast(sync: true);
  @override
  Stream<String?> get sessoes => auth.stream;
  Map<String, dynamic> estado = _dados();
  final pedidos = <Map<String, dynamic>>[],
      ops = <String, Map<String, dynamic>>{};
  bool falha = false, timeoutDepois = false;
  String codigoFalha = 'unavailable';
  Completer<Map<String, dynamic>>? bloqueio;
  void trocar(String? u) {
    usuario = u;
    auth.add(u);
  }

  void propor({int versao = 1}) {
    estado['proposta'] = {
      'versao': versao,
      'assinatura': 'assinatura-$versao',
      'brutoCentavos': 200000,
      'descontoCentavos': 10000,
      'liquidoCentavos': 190000,
      'validade': '2026-11-20T12:00:00Z',
      'prazoEntrega': null,
      'escopo': 'Buffet conforme escopo',
      'condicoes': 'Sinal e saldo',
      'itens': [
        {'nome': 'Buffet', 'quantidade': 20}
      ]
    };
    estado['propostas'] = [estado['proposta']];
    estado['estadoComercial'] = 'proposta_enviada';
  }

  void contratar() {
    if (estado['proposta'] == null) propor();
    estado['estadoComercial'] = 'ganho';
    estado['estadoExecucao'] = 'nao_iniciado';
    estado['idOrcamento'] = 'orc-estavel';
    estado['idContrato'] = 'orc-estavel';
    estado['condicoesAceitas'] = estado['proposta'];
  }

  @override
  Future<Map<String, dynamic>> chamar(String fn, Map<String, dynamic> d) async {
    pedidos.add({'funcao': fn, ...d});
    if (fn == 'consultarJornadaAtendimentoFn') {
      if (!['f', 'c'].contains(usuario)) {
        throw FirebaseFunctionsException(
            code: 'permission-denied', message: 'Sem vínculo', details: null);
      }
      if (bloqueio != null) return bloqueio!.future;
      if (falha) {
        throw FirebaseFunctionsException(
            code: codigoFalha, message: 'internal', details: null);
      }
      estado['papel'] = usuario == 'f' ? 'fornecedor' : 'cliente';
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(estado)) as Map);
    }
    final key = (d['chave'] ?? d['chaveIdempotencia']) as String;
    if (ops.containsKey(key)) return ops[key]!;
    if (fn == 'responderCotacao') {
      if (d['versaoEsperada'] != (estado['proposta']?['versao'] ?? 0)) {
        throw FirebaseFunctionsException(
            code: 'aborted',
            message: 'Proposta mudou. Recarregue.',
            details: null);
      }
      propor(versao: (d['versaoEsperada'] as int) + 1);
    }
    if (fn == 'fecharCotacao') {
      if (d['versaoProposta'] != estado['proposta']['versao']) {
        throw FirebaseFunctionsException(
            code: 'aborted', message: 'A versão vigente mudou.', details: null);
      }
      contratar();
    }
    if (fn == 'executarJornadaAtendimentoFn') {
      estado['estadoExecucao'] = {
        'agendar': 'agendado',
        'iniciar': 'em_execucao',
        'informar_entrega': 'entrega_informada',
        'aceitar': 'aceito',
        'contestar': 'contestado'
      }[d['acao']];
      estado['execucaoRevisao'] = (estado['execucaoRevisao'] as int) + 1;
    }
    if (fn == 'abrirCasoMediacaoParte') {
      estado['mediacoes'] = [
        {'id': 'caso-existente', 'estado': 'aberto'}
      ];
    }
    ops[key] = {'ok': true, 'idOrcamento': 'orc-estavel'};
    if (timeoutDepois) {
      timeoutDepois = false;
      throw FirebaseFunctionsException(
          code: 'deadline-exceeded', message: 'Timeout', details: null);
    }
    return ops[key]!;
  }
}

JornadaAtendimentoController _controller(_Gateway g, _Store s) =>
    JornadaAtendimentoController(
        idCotacao: 'q',
        idFornecedor: 'f',
        gateway: g,
        store: s,
        clock: () => DateTime.utc(2026, 10, 26));
Future<void> _montar(WidgetTester t, JornadaAtendimentoController c,
    {VoidCallback? chat, VoidCallback? fin}) async {
  await t.pumpWidget(GetMaterialApp(
      home: JornadaAtendimentoPage(
          idCotacao: 'q',
          idFornecedor: 'f',
          controller: c,
          onConversa: chat,
          onFinanceiro: fin)));
  await t.pumpAndSettle();
}

Future<void> _manifestar(WidgetTester t, String acao) async {
  await t.ensureVisible(find.text(acao));
  await t.tap(find.text(acao));
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const Key('jornada-motivo')),
      'Manifestação explícita sintética');
  await t.tap(find.text('Confirmar registro'));
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader('Poppins_700')
          ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf')))
        .load();
    final font = FontLoader('JornadaPoppins');
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
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  test('legado separa ganho de entrega e perda não vira contrato', () {
    Cotacao c(StatusCotacao s) => Cotacao(
        id: 'q',
        idEvento: 'e',
        idUsuarioSolicitante: 'c',
        nomeUsuarioSolicitante: 'Cliente',
        dataCadastro: DateTime(2026),
        status: s,
        fornecedores: [],
        servicos: []);
    expect(estadoComercialCotacao(c(StatusCotacao.concluida)), 'ganho');
    expect(entregaAceitaCotacao(c(StatusCotacao.concluida)), false);
    expect(estadoComercialCotacao(c(StatusCotacao.perdeuCotacao)), 'perdido');
  });
  test('reabertura retoma operação sem duplicar contratação', () async {
    final g = _Gateway()..propor(), s = _Store(), c = _controller(g, s);
    await c.iniciar();
    g.timeoutDepois = true;
    expect(
        await c.comandar('fecharCotacao', {
          'idCotacao': 'q',
          'idFornecedor': 'f',
          'versaoProposta': 1,
          'assinaturaProposta': 'assinatura-1'
        }),
        false);
    final key = c.pendente.value!['chave'];
    c.onClose();
    final novo = _controller(g, s);
    await novo.iniciar();
    expect(novo.pendente.value, isNotNull);
    expect(await novo.retomar(), true);
    expect(g.ops.length, 1);
    expect(novo.dados.value!['idContrato'], 'orc-estavel');
    expect(
        g.pedidos
            .where((d) => d['funcao'] == 'fecharCotacao')
            .map((d) => d['chave'])
            .toSet(),
        {key});
    novo.onClose();
    await g.auth.close();
  });
  test('intenção de outro atendimento não é executada silenciosamente',
      () async {
    final g = _Gateway(), s = _Store();
    await s.salvar('f', {
      'chave': 'x',
      'pedido': {
        'idCotacao': 'outra',
        'idFornecedor': 'f',
        'funcao': 'responderCotacao',
        'dados': {}
      }
    });
    final c = _controller(g, s);
    await c.iniciar();
    expect(c.pendenteNestaJornada, false);
    expect(await c.retomar(), false);
    expect(g.pedidos.where((d) => d['funcao'] == 'responderCotacao'), isEmpty);
    c.onClose();
    await g.auth.close();
  });
  test('resultado tardio de consulta não cruza sessão', () async {
    final g = _Gateway(), s = _Store(), c = _controller(g, s);
    await c.iniciar();
    g.bloqueio = Completer();
    final f = c.carregar();
    g.trocar(null);
    await pumpEventQueue();
    g.bloqueio!.complete(_dados());
    await f;
    expect(c.dados.value, isNull);
    c.onClose();
    await g.auth.close();
  });
  testWidgets(
      'proposta exige revisão humana, versão, preço, desconto e validade',
      (t) async {
    final g = _Gateway(), s = _Store(), c = _controller(g, s);
    await _montar(t, c);
    expect(g.pedidos.where((d) => d['funcao'] == 'responderCotacao'), isEmpty);
    await t.ensureVisible(find.text('Preparar proposta'));
    await t.tap(find.text('Preparar proposta'));
    await t.pumpAndSettle();
    for (final e in {
      'preco': '2.000,00',
      'desconto': '100,00',
      'escopo': 'Buffet conforme escopo revisado',
      'condicoes': 'Sinal e saldo acordados'
    }.entries) {
      final f = find.byKey(Key('jornada-${e.key}'));
      await t.ensureVisible(f);
      await t.enterText(f, e.value);
    }
    await t.tap(find.text('Enviar proposta'));
    await t.pumpAndSettle();
    final r = g.pedidos.singleWhere((d) => d['funcao'] == 'responderCotacao');
    expect(r['valorBrutoCentavos'], 200000);
    expect(r['descontoCentavos'], 10000);
    expect(r['versaoEsperada'], 0);
    expect(r['validade'], isNotEmpty);
    expect(DateTime.parse(r['validade']).isUtc, isTrue);
    expect(find.text('Proposta versão 1'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'compromisso navega preparação, execução, entrega e aceite com mesma identidade',
      (t) async {
    final g = _Gateway()..contratar(), s = _Store(), c = _controller(g, s);
    var chat = 0, fin = 0;
    await _montar(t, c, chat: () => chat++, fin: () => fin++);
    await _manifestar(t, 'Preparar e agendar');
    expect(c.dados.value!['estadoExecucao'], 'agendado');
    await _manifestar(t, 'Iniciar execução');
    await _manifestar(t, 'Informar entrega');
    expect(find.text('Registrar aceite da entrega'), findsNothing);
    g.trocar('c');
    await t.pumpAndSettle();
    await _manifestar(t, 'Registrar aceite da entrega');
    expect(c.dados.value!['estadoExecucao'], 'aceito');
    expect(c.dados.value!['idContrato'], 'orc-estavel');
    await t.ensureVisible(find.text('Conversar'));
    await t.tap(find.text('Conversar'));
    await t.ensureVisible(find.text('Financeiro deste contrato'));
    await t.tap(find.text('Financeiro deste contrato'));
    expect(chat, 1);
    expect(fin, 1);
    expect(
        g.pedidos
            .where((d) => d['funcao'] == 'executarJornadaAtendimentoFn')
            .every((d) => d['idOrcamento'] == 'orc-estavel'),
        true);
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'cliente aceita exatamente a versão revisada no diálogo; revisão concorrente é rejeitada',
      (t) async {
    final g = _Gateway()
          ..propor()
          ..usuario = 'c',
        s = _Store(),
        c = _controller(g, s);
    await _montar(t, c);
    await t.ensureVisible(find.text('Revisar e contratar versão 1'));
    await t.tap(find.text('Revisar e contratar versão 1'));
    await t.pumpAndSettle();
    expect(find.textContaining('Sinal e saldo'), findsWidgets);
    g.propor(versao: 2);
    await t.tap(find.text('Confirmar contratação desta versão'));
    await t.pumpAndSettle();
    expect(
        g.pedidos
            .lastWhere((d) => d['funcao'] == 'fecharCotacao')['versaoProposta'],
        1);
    expect(find.text('A versão vigente mudou.'), findsOneWidget);
    expect(g.estado['idContrato'], isNull);
  });
  testWidgets(
      'proposta expirada não oferece aceite e perda não mostra compromisso',
      (t) async {
    final g = _Gateway()
      ..propor()
      ..usuario = 'c';
    g.estado['proposta']['validade'] = '2026-10-01T00:00:00Z';
    final s = _Store(), c = _controller(g, s);
    await _montar(t, c);
    expect(find.textContaining('Proposta expirada'), findsOneWidget);
    expect(find.textContaining('Revisar e contratar versão'), findsNothing);
    g.estado['estadoComercial'] = 'perdido';
    g.estado['motivo'] = {'codigo': 'preco', 'descricao': 'Motivo registrado'};
    g.estado['proposta'] = null;
    await c.carregar();
    await t.pumpAndSettle();
    expect(find.text('Financeiro deste contrato'), findsNothing);
    expect(
        find.textContaining('Motivo de encerramento: preco'), findsOneWidget);
  });
  testWidgets('pós-aceite abre mediação existente sem editar preço contratado',
      (t) async {
    final g = _Gateway()..contratar(), s = _Store(), c = _controller(g, s);
    await _montar(t, c);
    expect(find.text('Revisar proposta'), findsNothing);
    await _manifestar(t, 'Solicitar alteração/cancelamento');
    final p =
        g.pedidos.lastWhere((d) => d['funcao'] == 'abrirCasoMediacaoParte');
    expect(p['idOrcamento'], 'orc-estavel');
    expect(c.dados.value!['condicoesAceitas']['liquidoCentavos'], 190000);
    expect(find.textContaining('caso-existente'), findsOneWidget);
  });
  testWidgets('troca de sessão descarta formulário e bloqueia comando antigo',
      (t) async {
    final g = _Gateway()
          ..propor()
          ..usuario = 'c',
        s = _Store(),
        c = _controller(g, s);
    await _montar(t, c);
    await t.ensureVisible(find.text('Revisar e contratar versão 1'));
    await t.tap(find.text('Revisar e contratar versão 1'));
    await t.pumpAndSettle();
    g.trocar('x');
    await t.pumpAndSettle();
    expect(find.text('Sessão alterada'), findsOneWidget);
    expect(find.text('Confirmar contratação desta versão'), findsNothing);
    expect(g.pedidos.where((d) => d['funcao'] == 'fecharCotacao'), isEmpty);
  });
  for (final largura in [360.0, 1280.0]) {
    testWidgets('carregamento da jornada mantém tema e cartões em $largura',
        (t) async {
      await t.binding.setSurfaceSize(Size(largura, 1100));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final tema = Get.put(EventThemeController());
      final g = _Gateway()..bloqueio = Completer<Map<String, dynamic>>();
      final c = _controller(g, _Store());
      await t.pumpWidget(GetMaterialApp(
        home: JornadaAtendimentoPage(
            idCotacao: 'q', idFornecedor: 'f', controller: c),
      ));
      // A primeira imagem já deve representar a consulta, antes de seu retorno.
      expect(find.byType(OperacaoSkeleton), findsNWidgets(2));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.widget<FestaAppBar>(find.byType(FestaAppBar)).themeController,
          same(tema));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(const Key('estado-comercial')), findsNothing);
      expect(find.text('Preparar proposta'), findsNothing);
      expect(t.takeException(), isNull);
      g.bloqueio!.complete(_dados());
      await t.pumpAndSettle();
      expect(find.byType(OperacaoSkeleton), findsNothing);
      expect(find.byKey(const Key('estado-comercial')), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await g.auth.close();
    });
  }
  testWidgets('falha de consulta tem retry sem fabricar compromisso',
      (t) async {
    final g = _Gateway()..falha = true, s = _Store(), c = _controller(g, s);
    await _montar(t, c);
    expect(find.text('Não foi possível abrir a jornada'), findsOneWidget);
    expect(find.text('internal'), findsNothing);
    expect(find.byKey(const Key('estado-execucao')), findsNothing);
    g.falha = false;
    await t.tap(find.text('Tentar novamente'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('estado-comercial')), findsOneWidget);
  });
  testWidgets('serviço não publicado é identificado sem liberar ações',
      (t) async {
    final g = _Gateway()
      ..falha = true
      ..codigoFalha = 'not-found';
    final c = _controller(g, _Store());
    await _montar(t, c);
    expect(find.textContaining('serviço da jornada não foi encontrado'),
        findsOneWidget);
    expect(c.codigoErroConsulta.value, 'not-found');
    expect(c.dados.value, isNull);
    expect(find.byKey(const Key('estado-execucao')), findsNothing);
    expect(
        await c.comandar('executarJornadaAtendimentoFn', {'acao': 'aceitar'}),
        false);
    expect(
        g.pedidos.where((p) => p['funcao'] == 'executarJornadaAtendimentoFn'),
        isEmpty);
  });
  for (final size in [const Size(390, 1000), const Size(1280, 1100)]) {
    testWidgets('próximo passo e ações legíveis em $size', (t) async {
      await t.binding.setSurfaceSize(size);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = _controller(_Gateway(), _Store());
      await t.pumpWidget(GetMaterialApp(
        theme: ThemeData(
            fontFamily: 'JornadaPoppins',
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF009688))),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width < 500 ? 1.3 : 1)),
            child: child!),
        home: RepaintBoundary(
            key: const Key('visual-jornada'),
            child: JornadaAtendimentoPage(
                idCotacao: 'q', idFornecedor: 'f', controller: c)),
      ));
      await t.pumpAndSettle();
      expect(find.text('AGORA É COM VOCÊ'), findsOneWidget);
      expect(find.text('Quem faz: Você'), findsOneWidget);
      expect(find.text('Sem prazo de retorno combinado'), findsOneWidget);
      expect(
          find.ancestor(
              of: find.text('Preparar proposta'),
              matching: find.byWidgetPredicate((w) => w is FilledButton)),
          findsOneWidget);
      expect(find.text('Estados independentes'), findsNothing);
      expect(find.textContaining('Contrato: q'), findsNothing);
      await expectLater(
          find.byKey(const Key('visual-jornada')),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/jornada-ergonomia-${size.width < 500 ? 'celular' : 'desktop'}.png'));
      await t.ensureVisible(find.text('O que o cliente precisa'));
      await t.pumpAndSettle();
      expect(find.text('Escopo inicial'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
  for (final size in [const Size(390, 1000), const Size(1280, 1100)]) {
    testWidgets('formulário de proposta claro e validado em $size', (t) async {
      await t.binding.setSurfaceSize(size);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final g = _Gateway(), c = _controller(g, _Store());
      await t.pumpWidget(GetMaterialApp(
        theme: ThemeData(
            fontFamily: 'JornadaPoppins',
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF009688))),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width < 500 ? 1.2 : 1)),
            child: child!),
        home: JornadaAtendimentoPage(
            idCotacao: 'q', idFornecedor: 'f', controller: c),
      ));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Preparar proposta'));
      await t.tap(find.text('Preparar proposta'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('jornada-preco')), '1.000,00');
      await t.enterText(find.byKey(const Key('jornada-desconto')), '100,00');
      await t.pumpAndSettle();
      expect(find.text('Total da proposta: R\$ 900,00'), findsOneWidget);
      expect(find.textContaining('offset'), findsNothing);
      expect(find.textContaining('IANA'), findsNothing);
      await expectLater(
          find.byType(AlertDialog),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/proposta-formulario-${size.width < 500 ? 'celular' : 'desktop'}.png'));
      await t.ensureVisible(find.byKey(const Key('jornada-validade')));
      await t.tap(find.byKey(const Key('jornada-validade')));
      await t.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await t.tap(find.text('OK').last);
      await t.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await t.tap(find.text('OK').last);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('jornada-desconto')));
      await t.enterText(find.byKey(const Key('jornada-desconto')), '1.100,00');
      await t.tap(find.text('Enviar proposta'));
      await t.pumpAndSettle();
      expect(find.text('O desconto não pode superar o valor da proposta.'),
          findsOneWidget);
      expect(
          g.pedidos.where((p) => p['funcao'] == 'responderCotacao'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
