import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';
import 'package:app_faca_festa/data/models/fornecedor/avaliacao_servico_model.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/datasources/remote/gestao_reputacao_remote.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'package:app_faca_festa/data/local/cadastro_armazenamento.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/gestao_reputacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/widgets/gestao_reputacao_painel.dart';

class _Store implements RecebimentoPendenteStore {
  final dados = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>?> ler(String u) async => dados[u];
  @override
  Future<void> salvar(String u, Map<String, dynamic> d) async {
    dados[u] = d;
  }

  @override
  Future<void> limpar(String u, {String? chave}) async {
    if (chave == null || dados[u]?['chave'] == chave) dados.remove(u);
  }
}

Map<String, dynamic> pagina() => {
      'itens': [
        {
          'id': 'critica',
          'nota': 1,
          'comentario': 'O serviço atrasou; preciso de um posicionamento.',
          'data': '2026-10-20T15:00:00Z',
          'verificada': true,
          'tipo': 'fornecedor',
          'servico': 'Fornecedor',
          'contexto': 'Contratação verificada · referência 7aa01f93',
          'situacao': 'publicada',
          'resposta': null,
          'denuncia': null
        }
      ],
      'cursor': null,
      'resumo': {
        'quantidade': 4,
        'media': 3.0,
        'distribuicao': [
          for (final n in [1, 2, 3, 4, 5])
            {'nota': n, 'quantidade': n == 3 ? 0 : 1}
        ],
        'periodos': [
          {'periodo': '2026-09', 'quantidade': 2, 'media': 1.5},
          {'periodo': '2026-10', 'quantidade': 2, 'media': 4.5}
        ],
        'base':
            'Avaliações verificadas publicadas · n=4 · filtros selecionados. Sem dados não significa ausência de problemas.'
      }
    };

class _Gateway implements ReputacaoGateway {
  @override
  String? usuario = 'f';
  final eventos = StreamController<String?>.broadcast(sync: true);
  @override
  Stream<String?> get sessoes => eventos.stream;
  Map<String, dynamic> estado = pagina();
  bool falhar = false,
      timeoutDepois = false,
      timeoutAntes = false,
      moderar = false;
  Completer<Map<String, dynamic>>? bloqueio;
  final pedidos = <Map<String, dynamic>>[];
  final ops = <String, Map<String, dynamic>>{};
  int gravacoes = 0;
  Map<String, dynamic>? filaSalva;
  final historicoResposta = <Map<String, dynamic>>[];
  void trocar(String? u) {
    usuario = u;
    eventos.add(u);
  }

  @override
  Future<Map<String, dynamic>> chamar(String fn, Map<String, dynamic> d) async {
    pedidos.add({'funcao': fn, ...d});
    if (fn == 'consultarPermissaoReputacaoFn') return {'moderar': moderar};
    if (fn == 'consultarGestaoReputacaoFn') {
      if (bloqueio != null) return bloqueio!.future;
      if (falhar) {
        throw FirebaseFunctionsException(
            details: null, code: 'unavailable', message: 'Indisponível');
      }
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(estado)) as Map);
    }
    if (fn == 'listarFilaReputacaoFn' && filaSalva != null) {
      return Map<String, dynamic>.from(
          jsonDecode(jsonEncode(filaSalva)) as Map);
    }
    if (fn == 'listarFilaReputacaoFn') {
      return {
        'cursor': null,
        'itens': [
          {
            'id': 'abcdef12',
            'situacao': 'aberta',
            'versao': 1,
            'motivo': 'ofensa',
            'criado_em': '2026-10-20T15:00:00Z',
            'descricao': 'Descrição sintética para análise.',
            'avaliacao': {
              'nota': 1,
              'comentario': 'Comentário original preservado.'
            },
            'nota_interna': 'Somente moderadores autorizados',
            'historico': [
              {
                'acao': 'denunciar',
                'autor_id': 'f',
                'criado_em': '2026-10-20T15:00:00Z'
              }
            ]
          }
        ]
      };
    }
    if (fn == 'historicoRespostaReputacaoFn') {
      return {'itens': historicoResposta};
    }
    if (fn == 'decidirDenunciaReputacaoFn') {
      filaSalva = {
        'cursor': null,
        'itens': [
          {
            'id': 'abcdef12',
            'situacao': d['acao'] == 'encerrar' ? 'encerrada' : 'em_analise',
            'versao': 2,
            'motivo': 'ofensa',
            'criado_em': '2026-10-20T15:00:00Z',
            'descricao': 'Descrição sintética para análise.',
            'avaliacao': {
              'nota': 1,
              'comentario': 'Comentário original preservado.'
            },
            'fundamentacao_compartilhada': d['fundamentacao'],
            'nota_interna': d['notaInterna'],
            'historico': []
          }
        ]
      };
    }
    final k = d['chave'] as String? ?? '';
    if (ops.containsKey(k)) return ops[k]!;
    if (timeoutAntes) {
      timeoutAntes = false;
      throw FirebaseFunctionsException(
          message: 'Timeout sintético',
          details: null,
          code: 'deadline-exceeded');
    }
    if (fn == 'responderReputacaoFn') {
      final row = (estado['itens'] as List).first as Map;
      if ((row['resposta']?['versao'] ?? 0) != d['versaoEsperada']) {
        throw FirebaseFunctionsException(
            details: null,
            code: 'aborted',
            message: 'A resposta mudou. Recarregue antes de editar.');
      }
      gravacoes++;
      row['resposta'] = {
        'texto': d['texto'],
        'versao': (d['versaoEsperada'] as int) + 1,
        'data': '2026-10-26T15:00:00Z',
        'autorId': 'f'
      };
    }
    if (fn == 'responderReputacaoFn') {
      historicoResposta.add(Map<String, dynamic>.from(
          ((estado['itens'] as List).first as Map)['resposta'] as Map));
    }
    if (fn == 'denunciarReputacaoFn') {
      gravacoes++;
      ((estado['itens'] as List).first as Map)['denuncia'] = {
        'situacao': 'aberta',
        'fundamentacao': null
      };
    }
    ops[k] = {'versao': 1};
    if (timeoutDepois) {
      timeoutDepois = false;
      throw FirebaseFunctionsException(
          message: 'Timeout sintético',
          details: null,
          code: 'deadline-exceeded');
    }
    return ops[k]!;
  }
}

GestaoReputacaoController _criar(_Gateway g, _Store s, {bool mod = false}) =>
    GestaoReputacaoController(
        gateway: g, idFornecedor: 'f', moderacao: mod, store: s);
Future<void> montar(WidgetTester t, GestaoReputacaoController c,
    {bool mod = false, double escala = 1}) async {
  await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'ReputacaoNoto'),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(escala)),
          child: child!),
      home: Scaffold(
          body: SingleChildScrollView(
              child: GestaoReputacaoPainel(
                  idFornecedor: 'f', controller: c, moderacao: mod)))));
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final bytes = await File('assets/fonts/NotoSans-Regular.ttf').readAsBytes();
    final fonte = FontLoader('ReputacaoNoto')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await fonte.load();
    final icones = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icones.load();
  });
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  test(
      'persistência real separa intenção de reputação do recebimento e de outros usuários',
      () async {
    final dir = await Directory.systemTemp.createTemp('faca-festa-reputacao-');
    try {
      final a = CadastroArquivos(diretorio: dir),
          r = RecebimentoPendenteLocalStore(
              arquivos: a, namespace: 'reputacao_pendente_v1'),
          f = RecebimentoPendenteLocalStore(arquivos: a);
      await r.salvar('f', {
        'chave': 'r',
        'pedido': {'funcao': 'responderReputacaoFn'}
      });
      await f.salvar('f', {'chave': 'caixa', 'pedido': {}});
      expect(
          (await RecebimentoPendenteLocalStore(
                  arquivos: CadastroArquivos(diretorio: dir),
                  namespace: 'reputacao_pendente_v1')
              .ler('f'))?['chave'],
          'r');
      expect((await f.ler('f'))?['chave'], 'caixa');
      expect(await r.ler('outra'), isNull);
      await r.limpar('f', chave: 'antiga');
      expect(await r.ler('f'), isNotNull);
    } finally {
      expect(dir.absolute.path.startsWith(Directory.systemTemp.absolute.path),
          true);
      await dir.delete(recursive: true);
    }
  });
  test(
      'timeout pós-persistência retoma mesma operação em nova instância sem duplicar',
      () async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s);
    await c.iniciar();
    g.timeoutDepois = true;
    expect(await c.responder(c.itens.single, 'Resposta persistida'), false);
    expect(c.pendente.value, isNotNull);
    expect(g.gravacoes, 1);
    final chave = c.pendente.value!['chave'];
    expect(await c.responder(c.itens.single, 'Outro envio'), false);
    c.onClose();
    final reaberto = _criar(g, s);
    await reaberto.iniciar();
    expect(reaberto.pendente.value, isNull);
    expect(reaberto.itens.single.resposta!['texto'], 'Resposta persistida');
    expect(g.gravacoes, 1);
    expect(
        g.pedidos
            .where((d) => d['funcao'] == 'responderReputacaoFn')
            .map((d) => d['chave'])
            .toSet(),
        {chave});
    reaberto.onClose();
    await g.eventos.close();
  });
  test(
      'timeout antes do commit preserva intenção e CAS rejeita edição desatualizada',
      () async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s);
    await c.iniciar();
    g.timeoutAntes = true;
    final antigo = c.itens.single;
    expect(await c.responder(antigo, 'Resposta aguardando'), false);
    expect(g.gravacoes, 0);
    expect(await c.retomar(), true);
    expect(g.gravacoes, 1);
    expect(await c.responder(antigo, 'Edição antiga'), false);
    expect(c.erro.value, contains('mudou'));
    expect(c.pendente.value, isNull);
    expect(g.gravacoes, 1);
    c.onClose();
    await g.eventos.close();
  });
  test('filtro de período mantém limite temporal estável durante paginação',
      () async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s);
    await c.iniciar();
    c.dias.value = 30;
    g.estado['cursor'] = 'cursor';
    await c.filtrar();
    await c.carregar(mais: true);
    final p = g.pedidos
        .where((d) => d['funcao'] == 'consultarGestaoReputacaoFn')
        .toList();
    expect(p[p.length - 2]['de'], p.last['de']);
    expect(p.last['cursor'], 'cursor');
    expect(c.itens.length, 1);
    c.onClose();
    await g.eventos.close();
  });
  test('troca de sessão descarta consulta antiga e bloqueia comandos',
      () async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s);
    await c.iniciar();
    final a = c.itens.single;
    g.bloqueio = Completer();
    final carregar = c.carregar();
    g.trocar('f2');
    await pumpEventQueue();
    g.bloqueio!.complete(pagina());
    await carregar;
    expect(c.itens, isEmpty);
    expect(c.autorizado.value, false);
    expect(await c.responder(a, 'Sessão antiga'), false);
    expect(g.gravacoes, 0);
    c.onClose();
    await g.eventos.close();
  });
  testWidgets(
      'erro com retry, comentário, distribuição e resposta persistida após reabrir',
      (t) async {
    t.view.physicalSize = const Size(800, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final g = _Gateway()..falhar = true, s = _Store(), c = _criar(g, s);
    await montar(t, c);
    expect(find.text('Tentar novamente'), findsOneWidget);
    await expectLater(
        find.byKey(const Key('gestao-reputacao')),
        matchesGoldenFile(
            '../../../docs/evidencias_validacao/operacao-fornecedor/mensagens/reputacao-falha.png'));
    g.falhar = false;
    await t.tap(find.text('Tentar novamente'));
    await t.pumpAndSettle();
    expect(find.textContaining('Média da amostra: 3.00'), findsOneWidget);
    expect(find.textContaining('2026-09: 1.50'), findsOneWidget);
    expect(find.textContaining('O serviço atrasou'), findsOneWidget);
    await t.ensureVisible(find.text('Responder'));
    await t.tap(find.text('Responder'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('texto-reputacao')),
        'Reconhecemos o atraso e estamos à disposição.');
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.textContaining('Reconhecemos o atraso'), findsOneWidget);
    expect(g.gravacoes, 1);
    await t.pumpWidget(const SizedBox());
    final novo = _criar(g, s);
    await montar(t, novo);
    expect(find.textContaining('Reconhecemos o atraso'), findsOneWidget);
    await expectLater(
        find.byKey(const Key('gestao-reputacao')),
        matchesGoldenFile(
            '../../../docs/evidencias_validacao/operacao-fornecedor/mensagens/resposta-persistida.png'));
    expect(t.takeException(), isNull);
  });
  testWidgets('denúncia não apaga a crítica nem expõe notas internas',
      (t) async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s);
    await montar(t, c);
    await t.ensureVisible(find.text('Denunciar'));
    await t.tap(find.text('Denunciar'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('texto-reputacao')),
        'Solicito revisão fundamentada do comentário.');
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.textContaining('O serviço atrasou'), findsOneWidget);
    expect(find.text('Denúncia: aberta'), findsOneWidget);
    expect(find.textContaining('INTERNO'), findsNothing);
    expect(g.gravacoes, 1);
  });
  testWidgets('fila exige autorização específica', (t) async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s, mod: true);
    await montar(t, c, mod: true);
    expect(find.text('Permissão específica de moderação necessária.'),
        findsOneWidget);
    expect(c.casos, isEmpty);
  });
  testWidgets(
      'loading e semântica informam amostra sem ocultar indisponibilidade',
      (t) async {
    final g = _Gateway()..bloqueio = Completer(),
        s = _Store(),
        c = _criar(g, s);
    final handle = t.ensureSemantics();
    try {
      await t.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: 'ReputacaoNoto'),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: GestaoReputacaoPainel(
                      idFornecedor: 'f', controller: c)))));
      await t.pump();
      expect(find.byType(OperacaoSkeleton), findsOneWidget);
      expect(
          find.bySemanticsLabel('Carregando Suas avaliações'), findsOneWidget);
      expect(find.textContaining('Nenhuma avaliação encontrada'), findsNothing);
      expect(c.itens, isEmpty);
      g.bloqueio!.complete(pagina());
      await t.pumpAndSettle();
      expect(find.byType(OperacaoSkeleton), findsNothing);
      expect(find.bySemanticsLabel(RegExp('1 estrelas: 1 de 4 avaliações')),
          findsOneWidget);
    } finally {
      handle.dispose();
    }
  });
  test('resposta pública é separada da nota e não confere selo ao legado', () {
    final a = AvaliacaoServicoModel.fromMap({
      'nota': 1,
      'comentario': 'Crítica original',
      '_resposta_publica': {'texto': 'Resposta do fornecedor'}
    });
    expect(a.nota, 1);
    expect(a.comentario, 'Crítica original');
    expect(a.verificada, false);
    expect(a.respostaFornecedor, 'Resposta do fornecedor');
  });
  testWidgets('editar resposta envia versão corrente e preserva histórico',
      (t) async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s);
    await montar(t, c);
    await c.responder(c.itens.single, 'Resposta original pública');
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Editar resposta'));
    await t.tap(find.text('Editar resposta'));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const Key('texto-reputacao')), 'Resposta pública revisada');
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(
        g.pedidos
            .where((d) => d['funcao'] == 'responderReputacaoFn')
            .last['versaoEsperada'],
        1);
    await t.ensureVisible(find.text('Histórico da resposta'));
    await t.tap(find.text('Histórico da resposta'));
    await t.pumpAndSettle();
    expect(find.textContaining('Resposta original pública'), findsOneWidget);
    expect(find.textContaining('Resposta pública revisada'), findsWidgets);
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'fila registra decisão e mantém nota interna só no painel restrito',
      (t) async {
    final g = _Gateway()..moderar = true,
        s = _Store(),
        c = _criar(g, s, mod: true);
    await montar(t, c, mod: true);
    await t.ensureVisible(find.text('Analisar ou encerrar'));
    await t.tap(find.text('Analisar ou encerrar'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Encerrar com decisão').last);
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Ocultar publicação').last);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('texto-reputacao')),
        'Fundamentação compartilhável sintética.');
    await t.enterText(
        find.byType(TextFormField).last, 'Nota interna sintética restrita.');
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.textContaining('encerrada'), findsOneWidget);
    expect(
        g.pedidos.lastWhere(
            (d) => d['funcao'] == 'decidirDenunciaReputacaoFn')['decisao'],
        'ocultar');
    expect(t.takeException(), isNull);
  });
  testWidgets('vazio e envio desconhecido têm estados explícitos com retomada',
      (t) async {
    final g = _Gateway(), s = _Store(), c = _criar(g, s);
    await montar(t, c);
    g.timeoutDepois = true;
    await c.responder(c.itens.single, 'Resposta aguardando confirmação');
    await t.pumpAndSettle();
    expect(find.text('Retomar envio'), findsOneWidget);
    await t.ensureVisible(find.text('Retomar envio'));
    await t.tap(find.text('Retomar envio'));
    await t.pumpAndSettle();
    expect(g.gravacoes, 1);
    expect(find.text('Retomar envio'), findsNothing);
    g.estado = {
      'itens': [],
      'cursor': null,
      'resumo': {
        'quantidade': 0,
        'media': null,
        'distribuicao': [
          for (final n in [1, 2, 3, 4, 5]) {'nota': n, 'quantidade': 0}
        ],
        'periodos': [],
        'base': 'Sem dados não significa ausência de problemas.'
      }
    };
    await c.carregar();
    await t.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
        find.textContaining('Nenhuma avaliação encontrada.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('atalho sem resposta e restauração aplicam filtros reais',
      (t) async {
    final g = _Gateway(), c = _criar(g, _Store());
    await montar(t, c);
    await t.tap(find.text('Preciso responder'));
    await t.pumpAndSettle();
    expect(c.resposta.value, 'pendente');
    expect(g.pedidos.last['resposta'], 'pendente');
    await t.tap(find.text('Restaurar filtros'));
    await t.pumpAndSettle();
    expect(c.resposta.value, 'todas');
    expect(c.nota.value, 0);
    expect(c.dias.value, 0);
    expect(g.pedidos.last['resposta'], 'todas');
    expect(find.text('Restaurar filtros'), findsNothing);
  });
  for (final largura in [360.0, 1200.0]) {
    testWidgets('reputação com fonte ampliada em $largura', (t) async {
      await t.binding.setSurfaceSize(Size(largura, 1000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = _criar(_Gateway(), _Store());
      await montar(t, c, escala: 2);
      expect(t.takeException(), isNull);
      await t.ensureVisible(find.text('Responder'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
  for (final largura in [360.0, 1200.0]) {
    testWidgets('evidência visual responsiva em $largura', (t) async {
      t.view.physicalSize = Size(largura, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final g = _Gateway(), s = _Store(), c = _criar(g, s);
      await montar(t, c);
      expect(t.takeException(), isNull);
      await expectLater(
          find.byKey(const Key('gestao-reputacao')),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/mensagens/reputacao-${largura.toInt()}.png'));
    });
  }
  testWidgets('evidência visual da fila restrita', (t) async {
    t.view.physicalSize = const Size(1000, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final g = _Gateway()..moderar = true,
        s = _Store(),
        c = _criar(g, s, mod: true);
    await montar(t, c, mod: true);
    expect(find.textContaining('Restrito à moderação'), findsOneWidget);
    await expectLater(
        find.byKey(const Key('gestao-reputacao')),
        matchesGoldenFile(
            '../../../docs/evidencias_validacao/operacao-fornecedor/mensagens/fila-moderacao.png'));
    expect(t.takeException(), isNull);
  });
}
