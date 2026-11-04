import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/datasources/remote/painel_fontes_disponiveis.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/painel_operacional_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/visao_operacional_fornecedor.dart';

class Gateway implements CallableSessaoGateway {
  String? uid = 'f';
  final stream = StreamController<String?>.broadcast();
  @override
  String? get usuario => uid;
  @override
  Stream<String?> get sessoes => stream.stream;
  @override
  Future<Map<String, dynamic>> chamar(
          String nome, Map<String, dynamic> dados) async =>
      throw FirebaseFunctionsException(
          code: 'unavailable', message: 'Fonte consolidada fora do ar');
}

Map<String, dynamic> fontes() => {
      'atendimentos': {
        'aguardando': 1,
        'mensagensNaoLidas': 2,
        'primeiraResposta': medirPrimeiraRespostaDisponivel([
          {
            'data_envio': '2026-10-25T12:00:00Z',
            'evidenciaCompleta': true,
            'mensagens': [
              {'id_usuario': 'f', 'enviado_em': '2026-10-25T13:00:00Z'}
            ]
          }
        ], 'f', DateTime.parse('2026-10-27T12:00:00Z')),
        'total': 3,
        'prioridade': {'idCotacao': 'q1', 'enviadoEm': '2026-10-25T12:00:00Z'}
      },
      'catalogo': 16,
      'contratos': 1,
      'estoque': 7,
      'reputacao': {'media': 4.4, 'quantidade': 45, 'verificada': false},
      'consultadoEm': '2026-10-27T12:00:00Z'
    };
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonte = FontLoader('PainelPoppins');
    for (final f in [
      'Poppins-Regular.ttf',
      'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf'
    ]) {
      fonte.addFont(Future.value(
          ByteData.sublistView(await File('assets/fonts/$f').readAsBytes())));
    }
    await fonte.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('resposta medida exclui sistema, cliente, reenvio e futuro', () {
    final agora = DateTime.parse('2026-10-27T12:00:00Z');
    final itens = <Map<String, dynamic>>[
      {
        'data_envio': '2026-10-25T12:00:00Z',
        'evidenciaCompleta': true,
        'mensagens': [
          {
            'id_usuario': 'f',
            'sistema': true,
            'enviado_em': '2026-10-25T12:01:00Z'
          },
          {'id_usuario': 'cliente', 'enviado_em': '2026-10-25T12:02:00Z'},
          {'id_usuario': 'f', 'enviado_em': '2026-10-25T13:00:00Z'},
          {'id_usuario': 'f', 'enviado_em': '2026-10-25T15:00:00Z'},
          {'id_usuario': 'f', 'enviado_em': '2026-10-28T12:00:00Z'}
        ],
        'propostas': [
          {'autor_id': 'f', 'criado_em': '2026-10-25T13:30:00Z'}
        ]
      },
      {'data_envio': '2026-10-26T12:00:00Z', 'evidenciaCompleta': true}
    ];
    final r = medirPrimeiraRespostaDisponivel(itens, 'f', agora)!;
    expect(r['media'], 1);
    expect(r['amostra'], 1);
    expect(r['semResposta'], 1);
    itens.first['evidenciaCompleta'] = false;
    expect(medirPrimeiraRespostaDisponivel(itens, 'f', agora), isNull);
  });
  test('contratações usam identidade, cancelamentos não inflam o total', () {
    expect(
        contarContratosDisponiveis([
          {
            'id': 'a',
            'status': 'fechado',
            'contrato_financeiro': {
              'id_contrato': 'c',
              'estado_comercial': 'contratado'
            }
          },
          {
            'id': 'b',
            'status': 'fechado',
            'contrato_financeiro': {
              'id_contrato': 'c',
              'estado_comercial': 'contratado'
            }
          },
          {'id': 'x', 'status': 'cancelado', 'orcamento_fechado': true},
          {'id': 'p', 'status': 'pendente'},
          {'id': 'l1', 'id_cotacao': 'q', 'status': 'fechado'},
          {'id': 'l2', 'id_cotacao': 'q', 'status': 'fechado'}
        ]),
        2);
  });
  test('reputação histórica não ganha verificação nem é somada à verificada',
      () {
    final legado = resumoReputacaoDisponivel(
        {'media_avaliacoes': 4.4, 'total_avaliacoes': 45})!;
    expect(legado['verificada'], false);
    expect(legado['quantidade'], 45);
    final atual = resumoReputacaoDisponivel({
      'media_avaliacoes': 4.4,
      'total_avaliacoes': 45,
      'reputacao_verificada': {'schema': 2, 'media': 4, 'quantidade': 3}
    })!;
    expect(atual['quantidade'], 3);
    expect(atual['verificada'], true);
    expect(
        resumoReputacaoDisponivel(
            {'media_avaliacoes': double.nan, 'total_avaliacoes': 45}),
        isNull);
  });
  test('pendência respeita cancelamento e não inventa data ausente', () {
    final r = resumoAtendimentosDisponiveis([
      {
        'id': 'cancelada',
        'status': 'aguardando',
        'cotacao': {'status': 'cancelada'}
      },
      {'id': 'ativa', 'estado_comercial': 'nova_solicitacao', 'cotacao': {}}
    ], naoLidas: null);
    expect(r['aguardando'], 1);
    expect(r['mensagensNaoLidas'], isNull);
    expect(r['prioridade']['enviadoEm'], isNull);
  });
  test('fonte direta antiga é descartada ao trocar de sessão', () async {
    final g = Gateway(), espera = Completer<Map<String, dynamic>>();
    final c = PainelOperacionalController(
        gateway: g, lerFontesDisponiveis: (_) => espera.future);
    final load = c.iniciar();
    g.uid = null;
    g.stream.add(null);
    await Future<void>.delayed(Duration.zero);
    espera.complete(fontes());
    await load;
    expect(c.fontesDisponiveis.value, isNull);
    c.onClose();
    await g.stream.close();
  });
  for (final largura in [360.0, 1280.0]) {
    testWidgets('visão rica resiste à falha consolidada em $largura',
        (t) async {
      await t.binding.setSurfaceSize(Size(largura, 1500));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final g = Gateway(),
          c = PainelOperacionalController(
              gateway: g,
              lerFontesDisponiveis: (_) async => fontes(),
              clock: () => DateTime.parse('2026-10-27T12:00:00Z'));
      String? rota;
      Map<String, dynamic>? cotacao;
      Widget app(double escala) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'PainelPoppins'),
          builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: VisaoOperacionalFornecedor(
                      controller: c,
                      onPedidos: () {},
                      onCatalogo: () {},
                      onPerfil: () {},
                      perfilCompleto: () => 92,
                      analiseIa: () => {'amostra': 3, 'quentes': 0},
                      onAtendimento: (q) => cotacao = q,
                      onNavegar: (r) => rota = r))));
      await t.pumpWidget(app(1));
      await t.pumpAndSettle();
      await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/restauracao/painel-${largura.toInt()}.png'));
      expect(find.text('16'), findsOneWidget);
      expect(find.text('1,0 h'), findsOneWidget);
      expect(find.text('4,4'), findsOneWidget);
      expect(find.textContaining('45 avaliações históricas · sem verificação'),
          findsOneWidget);
      expect(find.text('Não foi possível carregar o painel'), findsNothing);
      await t.tap(find.text('Abrir atendimento'));
      expect(cotacao?['idCotacao'], 'q1');
      await t.ensureVisible(find.text('Ver resumo'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ver resumo'));
      expect(rota, '/fornecedor/financeiro');
      await t.ensureVisible(find.text('Planejamento e relatórios'));
      await t.pumpAndSettle();
      await t.tap(find.text('Planejamento e relatórios'));
      expect(rota, '/fornecedor/planejamento');
      await t.pumpWidget(app(2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.onClose();
      await g.stream.close();
    });
  }
}
