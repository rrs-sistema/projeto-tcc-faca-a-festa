import 'package:app_faca_festa/presentation/modules/fornecedor/sections/header_section.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/fornecedor_home_screen.dart';
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

class _Conta extends Fake implements AppController {
  int saidas = 0;
  @override
  Future<void> logoutFornecedor() async {
    saidas++;
  }
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
      String nome, Map<String, dynamic> dados) async {
    if (nome == 'consultarDemandaLatenteFornecedor') {
      return {
        'geradoEm': '2026-10-27T12:00:00Z',
        'totalEventos': 2,
        'totalSemCotacao': 2,
        'buckets': [
          {
            'tipoNome': 'Formatura',
            'cidade': 'Curitiba',
            'quantidade': 2,
            'semCotacao': 2,
            'proximos90Dias': 1,
            'convidadosMedios': 35,
          },
        ],
        'criterio': 'teste',
      };
    }
    throw FirebaseFunctionsException(
        code: 'unavailable', message: 'Fonte consolidada fora do ar');
  }
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
    expect(find.text('Nenhuma mensagem não lida'), findsNothing);

    mensagens.value = 1;
    await t.pump();
    await t.tap(find.text('1 mensagem não lida'));
    expect(aberturas, 1);

    mensagens.value = 0;
    await t.pump();
    expect(find.text('Nenhuma mensagem não lida'), findsNothing);
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
  List<Cotacao> pedidos(int quantidade) => List.generate(
      quantidade,
      (i) => Cotacao(
            id: 'q$i',
            idEvento: 'e$i',
            idUsuarioSolicitante: 'u$i',
            nomeUsuarioSolicitante: 'Cliente $i',
            categoriaNome: i.isEven ? 'Decoração' : 'Buffet',
            descricao: 'Descrição completa do pedido $i',
            dataCadastro: DateTime(2026, 10, 1).add(Duration(days: i)),
            status: StatusCotacao.pendente,
            fornecedores: const ['f'],
            servicos: const [],
          ));

  Widget lista(_Solicitacoes solicitacoes,
          {bool resumo = false, VoidCallback? verTodos}) =>
      GetMaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SolicitacoesSection(
          fornecedorController: _Fornecedor(),
          solicitacoesController: solicitacoes,
          themeController: EventThemeController(),
          cotacoes: _Cotacoes(),
          resumido: resumo,
          onVerTodos: verTodos,
        ))),
      );

  testWidgets('resumo limita cinco pendências e prioriza as mais antigas',
      (t) async {
    addTearDown(Get.reset);
    final dados = _Solicitacoes();
    dados.solicitacoes.assignAll(pedidos(8).reversed);
    dados.solicitacoes
        .add(pedidos(1).single.copyWith(status: StatusCotacao.cancelada));
    var aberturas = 0;
    await t.pumpWidget(lista(dados, resumo: true, verTodos: () => aberturas++));
    await t.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('pedido-q$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('pedido-q5')), findsNothing);
    expect(t.getTopLeft(find.text('Cliente 0')).dy,
        lessThan(t.getTopLeft(find.text('Cliente 1')).dy));
    expect(find.text('Gerar IA'), findsNothing);
    await t.ensureVisible(find.text('Ver todos os pedidos'));
    await t.tap(find.text('Ver todos os pedidos'));
    expect(aberturas, 1);
  });

  testWidgets('gestão pagina vinte pedidos, busca e combina filtros',
      (t) async {
    addTearDown(Get.reset);
    final dados = _Solicitacoes()..solicitacoes.assignAll(pedidos(45));
    await t.pumpWidget(lista(dados));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('pedido-q44')), findsOneWidget);
    expect(find.byKey(const ValueKey('pedido-q25')), findsOneWidget);
    expect(find.byKey(const ValueKey('pedido-q24')), findsNothing);
    await t.ensureVisible(find.byTooltip('Próxima página'));
    await t.tap(find.byTooltip('Próxima página'));
    await t.pumpAndSettle();
    expect(find.text('Página 2 de 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('pedido-q24')), findsOneWidget);
    expect(find.byKey(const ValueKey('pedido-q44')), findsNothing);
    await t.ensureVisible(find.byType(TextField));
    await t.enterText(find.byType(TextField), 'Cliente 0');
    await t.pumpAndSettle();
    expect(find.text('Página 1 de 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('pedido-q0')), findsOneWidget);
    expect(find.byKey(const ValueKey('pedido-q1')), findsNothing);
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Buffet').last);
    await t.pumpAndSettle();
    expect(find.text('Nenhum pedido neste filtro'), findsOneWidget);
    expect(find.byKey(const ValueKey('pedido-q0')), findsNothing);
  });

  testWidgets('detalhes preservam descrição completa e assistência de IA',
      (t) async {
    addTearDown(Get.reset);
    await t.pumpWidget(lista(_Solicitacoes()));
    await t.pumpAndSettle();
    expect(find.text('Gerar IA'), findsNothing);
    await t.ensureVisible(find.text('Detalhes'));
    await t.tap(find.text('Detalhes'));
    await t.pumpAndSettle();
    expect(find.text('Detalhes do pedido'), findsOneWidget);
    expect(find.text('Gerar IA'), findsOneWidget);
    expect(find.text('Decoração para festa de aniversário'), findsWidgets);
    await t.tap(find.byTooltip('Fechar detalhes'));
    await t.pumpAndSettle();
    expect(find.text('Detalhes do pedido'), findsNothing);
  });

  for (final largura in [360.0, 768.0, 1280.0]) {
    testWidgets('cabeçalho organiza identidade e conta em $largura', (t) async {
      await t.binding.setSurfaceSize(Size(largura, 600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final fornecedor = _Fornecedor();
      fornecedor.fornecedor.value = fornecedor.fornecedor.value!.copyWith(
        razaoSocial: 'Decora Festas Curitiba',
        email: 'decorafestas@gmail.com',
        aptoParaOperar: true,
        categorias: const [
          FornecedorCategoriaResumo(nomeCategoria: 'Decoração')
        ],
      );
      final conta = _Conta();
      Widget app(double escala) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'PainelPoppins'),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(escala)),
                child: child!),
            home: Scaffold(
                backgroundColor: const Color(0xFFF6F7FB),
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: HeaderSection(
                        controller: fornecedor, appController: conta))),
          );
      await t.pumpWidget(app(1));
      await t.pumpAndSettle();
      await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/reorganizacao/cabecalho-${largura.toInt()}.png'));
      expect(find.text('Operacional'), findsOneWidget);
      expect(find.text('Área de atendimento'), findsOneWidget);
      expect(find.text('Comunicados'), findsOneWidget);
      await t.tap(find.text('Minha conta'));
      await t.pumpAndSettle();
      expect(find.text('Privacidade e dados'), findsOneWidget);
      expect(find.text('Preferências de notificações'), findsOneWidget);
      expect(find.text('Auditoria dos serviços'), findsOneWidget);
      await t.tap(find.text('Sair da conta'));
      await t.pumpAndSettle();
      expect(conta.saidas, 0);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(conta.saidas, 0);
      await t.pumpWidget(app(2));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Minha conta'));
      await t.tap(find.text('Minha conta'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Sair da conta'));
      await t.tap(find.text('Sair da conta'));
      await t.pumpAndSettle();
      await t.tap(find.text('Sair'));
      await t.pumpAndSettle();
      expect(conta.saidas, 1);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('navegação mantém cinco destinos acessíveis com texto ampliado',
      (t) async {
    var destino = -1;
    for (final largura in [360.0, 1280.0]) {
      await t.binding.setSurfaceSize(Size(largura, 800));
      for (final escala in [1.0, 2.0]) {
        await t.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!),
          home: Scaffold(
              bottomNavigationBar: FornecedorNavegacao(
            compacto: largura >= 1040,
            ativo: 0,
            onVisaoGeral: () => destino = 0,
            onPedidos: () => destino = 1,
            onCatalogo: () => destino = 2,
            onAcessosRapidos: () => destino = 3,
            onAvaliacoes: () => destino = 4,
          )),
        ));
        await t.pumpAndSettle();
        for (final item in [
          'Visão geral',
          'Pedidos',
          'Catálogo',
          'Acessos rápidos',
          'Avaliações'
        ].asMap().entries) {
          await t.tap(find.text(item.value));
          expect(destino, item.key);
        }
        expect(t.takeException(), isNull);
      }
    }
    await t.binding.setSurfaceSize(null);
  });

  for (final largura in [360.0, 1280.0]) {
    testWidgets('painel reorganizado resiste à falha consolidada em $largura',
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
        resumido: true,
        clock: () => DateTime.parse('2026-10-27T12:00:00Z'),
        onVerTodos: () {},
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
              '../../../docs/evidencias_validacao/operacao-fornecedor/reorganizacao/painel-${largura.toInt()}.png'));
      expect(find.text('16'), findsNothing);
      expect(find.text('≈ 7 d 10 h'), findsOneWidget);
      expect(find.text('4,4'), findsOneWidget);
      final pedidos = find.text('Pedidos que precisam de resposta');
      expect(pedidos, findsOneWidget);
      expect(find.text('1 pedido no total'), findsNothing);
      expect(find.text('1 novo aguardando resposta'), findsOneWidget);
      expect(t.getTopLeft(pedidos).dy,
          lessThan(t.getTopLeft(find.text('Acessos rápidos')).dy));
      expect(t.getTopLeft(find.text('Indicadores do negócio')).dy,
          lessThan(t.getTopLeft(pedidos).dy));
      expect(t.getTopLeft(pedidos).dy,
          lessThan(t.getTopLeft(find.text('Oportunidades na sua região')).dy));
      expect(find.text('5 avaliações verificadas'), findsOneWidget);
      expect(find.text('Não foi possível carregar o painel'), findsNothing);
      await t.ensureVisible(find.text('Responder pedido'));
      await t.tap(find.text('Responder pedido'));
      expect(cotacao?['idCotacao'], 'q1');
      await t.ensureVisible(find.text('Abrir agenda'));
      await t.tap(find.text('Abrir agenda'));
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
