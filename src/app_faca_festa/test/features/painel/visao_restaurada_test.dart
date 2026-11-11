import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/score_cotacao_fornecedor.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/datasources/remote/painel_fontes_disponiveis.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_ai_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/painel_operacional_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/solicitacoes_section.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/visao_operacional_fornecedor.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _Fornecedor extends Fake implements FornecedorController {
  @override
  final fornecedor = Rxn(Fornecedor(
    idFornecedor: 'f',
    idUsuario: 'f',
    razaoSocial: 'Fornecedor',
    telefone: '',
    email: '',
    dataCadastro: DateTime(2026),
  ));

  @override
  final ai = _Ia();
}

class _Ia extends Fake implements FornecedorAiController {
  @override
  final scoresCotacoes = <String, ScoreCotacaoFornecedor>{}.obs;

  @override
  bool isGerandoRespostaCotacaoAi(String idCotacao) => false;
}

class _Solicitacoes extends Fake implements SolicitacoesController {
  @override
  final solicitacoes = [
    Cotacao(
      id: 'q1',
      idEvento: 'e1',
      idUsuarioSolicitante: 'u1',
      nomeUsuarioSolicitante: 'Ana Martins',
      descricao: 'Decoração para festa de aniversário',
      dataCadastro: DateTime(2026, 10, 25, 9),
      status: StatusCotacao.pendente,
      fornecedores: const ['f'],
      servicos: const [],
    ),
  ].obs;

  @override
  final carregando = false.obs;

  @override
  final erro = ''.obs;

  @override
  void inicializar(String idFornecedor) {}
}

class _Cotacoes extends Fake implements GerenciarCotacoes {}

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
            'data_envio': '2026-10-19T12:00:00Z',
            'evidenciaCompleta': true,
            'mensagens': [
              {'id_usuario': 'f', 'enviado_em': '2026-10-26T21:42:00Z'}
            ]
          }
        ], 'f', DateTime.parse('2026-10-27T12:00:00Z')),
        'total': 3,
        'prioridade': {'idCotacao': 'q1', 'enviadoEm': '2026-10-25T12:00:00Z'}
      },
      'catalogo': 16,
      'contratos': 1,
      'estoque': 7,
      'proximoCompromisso': {
        'servico': 'Montagem de decoração',
        'inicio': '2026-10-29T13:00:00Z',
      },
      'reputacao': {'media': 4.4, 'quantidade': 5},
      'consultadoEm': '2026-10-27T12:00:00Z'
    };
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final peso in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900,
    ]) {
      GoogleFonts.poppins(fontWeight: peso);
    }
    await GoogleFonts.pendingFonts();
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
  testWidgets('alerta do painel atualiza sem nova consulta e abre as conversas',
      (t) async {
    final gateway = Gateway();
    var consultas = 0, aberturas = 0;
    final mensagens = RxnInt();
    final painel = PainelOperacionalController(
      gateway: gateway,
      consultarConsolidado: false,
      lerFontesDisponiveis: (_) async {
        consultas++;
        return fontes();
      },
    );
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VisaoOperacionalFornecedor(
            controller: painel,
            lerMensagensNaoLidas: () => mensagens.value,
            onMensagens: () => aberturas++,
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('Consultar mensagens'), findsOneWidget);
    expect(find.text('2 mensagens não lidas'), findsNothing);

    mensagens.value = 0;
    await t.pump();
    expect(find.text('Nenhuma mensagem não lida'), findsOneWidget);

    mensagens.value = 1;
    await t.pump();
    await t.tap(find.text('1 mensagem não lida'));
    expect(aberturas, 1);

    mensagens.value = 0;
    await t.pump();
    expect(find.text('Nenhuma mensagem não lida'), findsOneWidget);
    expect(consultas, 1);
    await t.pumpWidget(const SizedBox.shrink());
    painel.onClose();
    await gateway.stream.close();
  });

  testWidgets('fornecedor abre revisão de uma proposta já respondida',
      (t) async {
    addTearDown(Get.reset);
    final solicitacoes = _Solicitacoes();
    solicitacoes.solicitacoes[0] = solicitacoes.solicitacoes.single
        .copyWith(status: StatusCotacao.respondida);
    await t.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolicitacoesSection(
            fornecedorController: _Fornecedor(),
            solicitacoesController: solicitacoes,
            themeController: EventThemeController(),
            cotacoes: _Cotacoes(),
          ),
        ),
      ),
      getPages: [
        GetPage(
          name: '/jornada-atendimento',
          page: () {
            final args = Get.arguments as Map;
            return Scaffold(
              body: Text(
                  'Proposta ${args['idCotacao']} de ${args['idFornecedor']}'),
            );
          },
        ),
      ],
    ));
    await t.pumpAndSettle();
    final revisar = find.text('Revisar proposta');
    await t.ensureVisible(revisar);
    await t.tap(revisar);
    await t.pumpAndSettle();
    expect(find.text('Proposta q1 de f'), findsOneWidget);
  });

  test('resumo destaca a janela futura mais próxima de um contrato ativo', () {
    final agora = DateTime.utc(2026, 10, 27, 12);
    Map<String, dynamic> contrato(String nome, int dias,
            {String status = 'fechado', String? execucao}) =>
        {
          'nome': nome,
          'status': status,
          'estado_execucao': execucao,
          'agenda_operacional': {
            'janelas': [
              {
                'inicio': agora.add(Duration(days: dias)).toIso8601String(),
                'fim':
                    agora.add(Duration(days: dias, hours: 2)).toIso8601String(),
              },
            ],
          },
        };
    expect(
      proximoCompromissoDisponivel([
        contrato('Executado', 0, execucao: 'aceito'),
        contrato('Passado', -1),
        contrato('Cancelado', 1, status: 'cancelado'),
        contrato('Mais distante', 4),
        contrato('Próximo', 2),
      ], agora),
      {'servico': 'Próximo', 'inicio': '2026-10-29T12:00:00.000Z'},
    );
    expect(
        proximoCompromissoDisponivel([contrato('Distante', 8)], agora), isNull);
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
      final lista = SolicitacoesSection(
        fornecedorController: _Fornecedor(),
        solicitacoesController: _Solicitacoes(),
        themeController: EventThemeController(),
        cotacoes: _Cotacoes(),
      );
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
                      pedidos: lista,
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
      expect(find.text('≈ 7 d 10 h'), findsOneWidget);
      expect(find.text('4,4'), findsOneWidget);
      final pedidos = find.text('Lista de pedidos');
      expect(pedidos.hitTestable(), findsOneWidget);
      expect(find.text('1 pedido no total'), findsOneWidget);
      expect(find.text('1 novo aguardando resposta'), findsOneWidget);
      expect(t.getTopLeft(find.text('Ana Martins')).dy, lessThan(700));
      expect(t.getTopLeft(pedidos).dy,
          lessThan(t.getTopLeft(find.text('Acessos rápidos')).dy));
      expect(t.getTopLeft(pedidos).dy,
          lessThan(t.getTopLeft(find.text('Indicadores do negócio')).dy));
      expect(find.text('5 avaliações verificadas'), findsOneWidget);
      expect(find.text('Não foi possível carregar o painel'), findsNothing);
      await t.tap(find.text('Abrir atendimento'));
      expect(cotacao?['idCotacao'], 'q1');
      await t.tap(find.text('Próximo compromisso'));
      expect(rota, '/fornecedor/agenda');
      final reputacao = find.text('Reputação');
      await t.ensureVisible(reputacao);
      await t.tap(reputacao);
      expect(rota, '/fornecedor/reputacao');
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
      await t.pumpWidget(const SizedBox());
      c.onClose();
      await g.stream.close();
    });
  }
}
