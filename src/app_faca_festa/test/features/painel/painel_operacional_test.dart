import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/painel_operacional_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/painel_operacional_fornecedor.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_painel_ao_vivo.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_estatisticas.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';

const evidencia =
    String.fromEnvironment('EVIDENCIA_OPERACAO', defaultValue: 'mensagens');

Map<String, dynamic> fixture([bool falha = false]) => Map<String,
    dynamic>.from(jsonDecode(File(
        'test/fixtures/${falha ? 'painel_operacional_falha_emulador' : 'painel_operacional_emulador'}.json')
    .readAsStringSync()));

class Gateway implements CallableSessaoGateway {
  String? uid = 'f';
  final stream = StreamController<String?>.broadcast();
  Map<String, dynamic> d = fixture();
  bool falha = false;
  Completer<Map<String, dynamic>>? espera;
  @override
  String? get usuario => uid;
  @override
  Stream<String?> get sessoes => stream.stream;
  @override
  Future<Map<String, dynamic>> chamar(
      String fn, Map<String, dynamic> args) async {
    if (falha) throw Exception('rede');
    return espera?.future ?? Future.value(d);
  }

  void trocar(String? u) {
    uid = u;
    stream.add(u);
  }
}

class Usecase extends Fake implements GerenciarFornecedores {
  final espera = Completer<FornecedorEstatisticas>();
  @override
  Future<FornecedorEstatisticas> carregarEstatisticas(String uid) =>
      espera.future;
}

Widget tela(PainelOperacionalController c,
        {void Function(String, Map<String, dynamic>)? abrir,
        double escala = 1}) =>
    RepaintBoundary(
        key: const Key('evidencia'),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                fontFamily: "PainelPoppins",
                useMaterial3: true,
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
                scaffoldBackgroundColor: const Color(0xFFF6F7FB)),
            builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx)
                    .copyWith(textScaler: TextScaler.linear(escala)),
                child: child!),
            home: Scaffold(
                appBar: AppBar(title: const Text('Operação do fornecedor')),
                body: SafeArea(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: PainelOperacionalFornecedor(
                            controller: c,
                            onNavegar: abrir,
                            onAtendimentos: () {},
                            onCatalogo: () {},
                            onPerfil: () {}))),
                bottomNavigationBar: BottomAppBar(
                    child: Row(children: [
                  for (final nome in ['Pedidos', 'Catálogo', 'Avaliações'])
                    Expanded(
                        child: TextButton(onPressed: () {}, child: Text(nome)))
                ])))));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonte = FontLoader('PainelPoppins');
    for (final f in [
      'Poppins-Regular.ttf',
      'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf'
    ]) {
      final bytes = await File('assets/fonts/$f').readAsBytes();
      fonte.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await fonte.load();
    final icones = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icones.load();
  });

  test(
      'última leitura fica desatualizada após cinco minutos e falha não inventa total',
      () async {
    final g = Gateway();
    var agora = DateTime.parse(g.d['geradoEm']);
    final c = PainelOperacionalController(gateway: g, clock: () => agora);
    await c.iniciar();
    expect(c.desatualizado.value, false);
    g.falha = true;
    await c.carregar();
    c.verificarAtualizacao();
    expect(c.desatualizado.value, true);
    g.falha = false;
    await c.carregar();
    expect(c.desatualizado.value, false);
    agora = agora.add(const Duration(minutes: 6));
    c.verificarAtualizacao();
    expect(c.desatualizado.value, true);
    g.falha = true;
    await c.carregar();
    expect(c.dados.value!['atendimentos']['primeiraRespostaHoras'], 1);
    expect(c.erro.value, contains('Os dados exibidos são da última consulta'));
    expect(c.erro.value, isNot(contains('se disponíveis')));
    g.falha = false;
    g.d['geradoEm'] = agora.toIso8601String();
    await c.carregar();
    expect(c.desatualizado.value, false);
    c.onClose();
    await g.stream.close();
  });
  test('resultado de sessão anterior é descartado', () async {
    final g = Gateway(), c = PainelOperacionalController(gateway: g);
    await c.iniciar();
    g.espera = Completer();
    final load = c.carregar();
    g.trocar(null);
    await Future<void>.delayed(Duration.zero);
    g.espera!.complete(fixture());
    await load;
    expect(c.dados.value, isNull);
    c.onClose();
    await g.stream.close();
  });
  test('fachada antiga não sobrescreve estatística da nova sessão', () async {
    String usuario = 'f';
    final f = Fornecedor(
        idFornecedor: 'f',
        idUsuario: 'f',
        razaoSocial: 'F',
        telefone: '',
        email: '',
        dataCadastro: DateTime(2030));
    final fornecedor = Rx<Fornecedor?>(f), pendentes = 0.obs, media = 0.0.obs;
    final u = Usecase();
    final p = FornecedorPainelAoVivo(
        fornecedor: fornecedor,
        aptoParaOperar: false.obs,
        solicitacoesPendentes: pendentes,
        mensagensNaoLidas: 0.obs,
        avaliacaoMedia: media,
        servicosFornecedor: <FornecedorProdutoServico>[].obs,
        erro: ''.obs,
        usecase: () => u,
        usuarioEhFornecedor: () => true,
        usuarioAtual: () => usuario,
        aoAtualizar: (_) {},
        aoLimpar: () {});
    final load = p.atualizarEstatisticas();
    usuario = 'g';
    u.espera.complete(const FornecedorEstatisticas(
        solicitacoesPendentes: 99,
        servicosAtivos: [],
        mensagensNaoLidas: 99,
        avaliacaoMedia: 5));
    await load;
    expect(pendentes.value, 0);
    expect(media.value, 0);
    await p.cancelarEscutas();
  });
  testWidgets(
      'média com amostra convive com espera de 64h e clique/teclado abre registro certo',
      (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway(), c = PainelOperacionalController(gateway: g);
    String? rota;
    Map? args;
    await t.pumpWidget(tela(c, abrir: (r, a) {
      rota = r;
      args = a;
    }));
    await t.pumpAndSettle();
    expect(find.text('1,0 h'), findsOneWidget);
    expect(find.text('64 h corridas desde a solicitação'), findsOneWidget);
    expect(find.textContaining('1 resposta humana · 1 sem resposta'),
        findsOneWidget);
    final b = find.text('Abrir atendimento');
    await t.ensureVisible(b);
    Focus.of(t.element(b)).requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(rota, '/jornada-atendimento');
    expect(args!['idCotacao'], 'parada64');
    final semantics = t.ensureSemantics();
    expect(
        t
            .getSemantics(find.widgetWithText(TextButton, 'Abrir atendimento'))
            .label,
        contains('Abrir atendimento'));
    semantics.dispose();
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('falha financeira real da fixture não vira saldo zero',
      (t) async {
    final g = Gateway()..d = fixture(true),
        c = PainelOperacionalController(gateway: g);
    await t.pumpWidget(tela(c));
    await t.pumpAndSettle();
    expect(find.text('Indisponível'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNothing);
    expect(find.text('64 h corridas desde a solicitação'), findsOneWidget);
    expect(find.textContaining('Painel parcial'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('todos os alertas abrem seus registros canônicos', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway(), c = PainelOperacionalController(gateway: g);
    String? rota;
    Map? args;
    await t.pumpWidget(tela(c, abrir: (r, a) {
      rota = r;
      args = a;
    }));
    await t.pumpAndSettle();
    for (final x in g.d['fila']) {
      final label = 'Abrir ${const {
            'repasse_bloqueado': 'repasse',
            'avaliacao': 'avaliação',
            'vinculo': 'vínculo'
          }[x['tipo']] ?? x['tipo']}';
      final botao = find.text(label);
      await t.ensureVisible(botao);
      await t.tap(botao);
      await t.pumpAndSettle();
      expect(rota, x['rota']);
      expect(args, x['argumentos']);
    }
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('primeira consulta sem rede tem retry e não mostra valores seed',
      (t) async {
    await t.binding.setSurfaceSize(const Size(1280, 850));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway()..falha = true,
        c = PainelOperacionalController(gateway: g);
    await t.pumpWidget(tela(c));
    await t.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Não foi possível carregar o painel'), findsOneWidget);
    expect(find.textContaining('última consulta'), findsNothing);
    expect(find.text('1,0 h'), findsNothing);
    await expectLater(
        find.byKey(const Key('evidencia')),
        matchesGoldenFile(
            '../../../docs/evidencias_validacao/operacao-fornecedor/$evidencia-painel-falha.png'));
    g.falha = false;
    await t.tap(find.text('Tentar novamente'));
    await t.pumpAndSettle();
    expect(find.text('1,0 h'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('sem amostra não usa seed nem média zero', (t) async {
    final g = Gateway();
    g.d['fila'] = [];
    g.d['atendimentos']['primeiraRespostaHoras'] = null;
    g.d['atendimentos']['amostraRespostas'] = 0;
    g.d['atendimentos']['conversao'] = null;
    g.d['reputacao']['media'] = null;
    g.d['reputacao']['amostra'] = 0;
    final c = PainelOperacionalController(gateway: g);
    await t.pumpWidget(tela(c));
    await t.pumpAndSettle();
    expect(find.text('Sem amostra'), findsNWidgets(3));
    expect(find.text('0,0 h'), findsNothing);
    expect(
        find.textContaining('Nenhuma pendência identificada'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  for (final w in [360.0, 1280.0]) {
    testWidgets('fonte ampliada e rodapé sem esconder conteúdo em $w',
        (t) async {
      await t.binding.setSurfaceSize(Size(w, 1000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final g = Gateway(), c = PainelOperacionalController(gateway: g);
      await t.pumpWidget(tela(c, escala: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final fim = find.text('Comissões');
      await t.ensureVisible(fim);
      await t.pumpAndSettle();
      expect(t.getRect(fim).bottom,
          lessThanOrEqualTo(t.getRect(find.byType(BottomAppBar)).top));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.onClose();
      await g.stream.close();
    });
  }
  for (final tamanho in [const Size(360, 1100), const Size(1600, 1600)]) {
    testWidgets('evidência visual $tamanho', (t) async {
      await t.binding.setSurfaceSize(tamanho);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final g = Gateway(),
          c = PainelOperacionalController(
              gateway: g, clock: () => DateTime.parse(g.d['geradoEm']));
      await t.pumpWidget(tela(c));
      await t.pumpAndSettle();
      await expectLater(
          find.byKey(const Key('evidencia')),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/$evidencia-painel-${tamanho.width == 360 ? 'celular' : 'desktop'}.png'));
      if (tamanho.width == 360) {
        await Scrollable.ensureVisible(
            t.element(find.text('Indicadores do negócio')),
            alignment: 0);
        await t.pumpAndSettle();
        await expectLater(
            find.byKey(const Key('evidencia')),
            matchesGoldenFile(
                '../../../docs/evidencias_validacao/operacao-fornecedor/$evidencia-painel-celular-indicadores.png'));
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.onClose();
      await g.stream.close();
    });
  }
}
