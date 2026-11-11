import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/cotacao_chat.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/chat/chat_mensagens_page.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/chat/fornecedor_mensagens_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _Cotacoes extends Fake implements GerenciarCotacoes {
  final mensagens = StreamController<List<CotacaoMensagem>>.broadcast();
  final envio = Completer<void>();
  List<CotacaoConversa> conversas = [];
  List<CotacaoFornecedorResumo> fornecedores = [];
  String? cotacaoAberta;
  int envios = 0;
  int leituras = 0;
  @override
  Stream<List<CotacaoConversa>> observarConversasFornecedor(
          String fornecedor) =>
      Stream.value(conversas);

  @override
  Future<CotacaoConversa?> buscarConversaFornecedor({
    required String idCotacao,
    required String idFornecedor,
  }) async {
    cotacaoAberta = idCotacao;
    return conversas.singleWhere((conversa) =>
        conversa.idCotacao == idCotacao &&
        conversa.idFornecedor == idFornecedor);
  }

  @override
  Stream<List<CotacaoMensagem>> observarMensagens(
          {required String idCotacao, required String idFornecedor}) =>
      mensagens.stream;
  @override
  Stream<List<CotacaoFornecedorResumo>> observarFornecedoresDaCotacao(
          String idCotacao) =>
      Stream.value(fornecedores);
  @override
  Future<void> marcarMensagensComoLidas(
      {required String idCotacao,
      required String idFornecedor,
      required String idUsuario}) async {
    leituras++;
  }

  @override
  Future<void> enviarMensagem(
      {required String idCotacao,
      required String idFornecedor,
      required String idUsuario,
      required String nomeUsuario,
      required String mensagem}) {
    envios++;
    return envio.future;
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });
  tearDown(() => Get.reset());
  Future<_Cotacoes> abrir(WidgetTester tester,
      {List<CotacaoFornecedorResumo> fornecedores = const []}) async {
    final cotacoes = _Cotacoes()..fornecedores = fornecedores;
    await tester.pumpWidget(GetMaterialApp(
        home: ChatMensagensPage(
      idCotacao: 'c',
      idFornecedor: 'f',
      nomeFornecedor: 'Fornecedor',
      dataSolicitacao: DateTime(2026, 11, 4),
      cotacoes: cotacoes,
      theme: EventThemeController(),
      usuario: const Usuario(
          idUsuario: 'o', nome: 'Organizador', email: 'teste@example.test'),
    )));
    cotacoes.mensagens.add([]);
    await tester.pumpAndSettle();
    return cotacoes;
  }

  testWidgets('organizador vê fornecedor e serviços da conversa selecionada',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cotacoes = await abrir(tester, fornecedores: const [
      CotacaoFornecedorResumo(
        idFornecedor: 'outro',
        nomeFornecedor: 'Outro fornecedor',
        status: 'respondido',
        observacaoFornecedor: '',
        prazoEntrega: null,
        condicaoPagamento: null,
        servicos: [
          CotacaoServicoResumo(
              nome: 'Iluminação', quantidade: 1, valorEstimado: 0),
        ],
      ),
      CotacaoFornecedorResumo(
        idFornecedor: 'f',
        nomeFornecedor: 'Decora Festas Curitiba',
        status: 'respondido',
        observacaoFornecedor: '',
        prazoEntrega: null,
        condicaoPagamento: null,
        servicos: [
          CotacaoServicoResumo(
              nome: 'Arco floral para altar', quantidade: 1, valorEstimado: 0),
          CotacaoServicoResumo(
              nome: 'Arranjo de mesa', quantidade: 3, valorEstimado: 0),
        ],
      ),
    ]);
    expect(find.text('Decora Festas Curitiba'), findsOneWidget);
    expect(find.text('Arco floral para altar (×1)'), findsOneWidget);
    expect(find.text('Outro fornecedor'), findsNothing);
    await tester.tap(find.text('Ver os 2 serviços'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Arranjo de mesa (×3)'), findsOneWidget);
    expect(find.textContaining('Iluminação'), findsNothing);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cotacoes.mensagens.close();
  });

  testWidgets('fornecedor distingue dois pedidos do mesmo cliente na lista',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cotacoes = _Cotacoes()
      ..conversas = [
        for (final (id, dia, pedido) in [
          ('pedido-1', 20, 'Flores para a cerimônia'),
          ('pedido-2', 22, 'Arco floral para a recepção'),
        ])
          CotacaoConversa(
            idCotacao: id,
            idFornecedor: 'f',
            categoria: 'Decoração',
            idEvento: 'evento',
            nomeSolicitante: 'Ana Martins',
            dataSolicitacao: DateTime(2026, 10, dia),
            observacaoPedido: pedido,
            ultimaMensagem: 'Podemos conversar?',
            ultimaMensagemEm: DateTime(2026, 11, 10, 23, 4),
            naoLidas: 1,
          ),
      ];
    await tester.pumpWidget(GetMaterialApp(
      home: FornecedorMensagensPage(
        usuario: const Usuario(
          idUsuario: 'f',
          nome: 'Fornecedor',
          email: 'teste@example.test',
          tipo: 'F',
        ),
        mensagensNaoLidas: 2,
        theme: EventThemeController(),
        cotacoes: cotacoes,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Ana Martins'), findsNWidgets(2));
    expect(find.text('Decoração • Pedido em 20/10/2026'), findsOneWidget);
    expect(find.text('Pedido: Flores para a cerimônia'), findsOneWidget);
    expect(find.text('Podemos conversar?'), findsNWidgets(2));
    await tester.tap(find.text('Pedido: Arco floral para a recepção'));
    await tester.pump();
    cotacoes.mensagens.add([]);
    await tester.pumpAndSettle();
    expect(cotacoes.cotacaoAberta, 'pedido-2');
    expect(find.text('Ana Martins'), findsOneWidget);
    expect(find.text('Arco floral para a recepção'), findsOneWidget);
    expect(find.text('Pedido enviado em 22/10/2026 00:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cotacoes.mensagens.close();
  });

  testWidgets('bloqueia reenvio e preserva novo rascunho durante o envio',
      (tester) async {
    final cotacoes = await abrir(tester);
    await tester.enterText(find.byType(TextField), 'Primeira');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(cotacoes.envios, 1);
    expect(find.byIcon(Icons.send_rounded), findsNothing);
    await tester.enterText(find.byType(TextField), 'Próxima mensagem');
    cotacoes.envio.complete();
    await tester.pumpAndSettle();
    expect(find.text('Próxima mensagem'), findsOneWidget);
    expect(cotacoes.envios, 1);
    await tester.pumpWidget(const SizedBox());
    await cotacoes.mensagens.close();
  });
  testWidgets(
      'marca mensagem recebida com a conversa aberta e exibe leitura da própria',
      (tester) async {
    final cotacoes = await abrir(tester);
    cotacoes.mensagens.add([
      CotacaoMensagem(
          idUsuario: 'f',
          nomeUsuario: 'Fornecedor',
          mensagem: 'Recebida',
          enviadoEm: DateTime(2026, 11, 4),
          lido: false),
      CotacaoMensagem(
          idUsuario: 'o',
          nomeUsuario: 'Organizador',
          mensagem: 'Enviada',
          enviadoEm: DateTime(2026, 11, 4),
          lido: true),
    ]);
    await tester.pumpAndSettle();
    expect(cotacoes.leituras, 1);
    expect(find.byTooltip('Lida'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cotacoes.mensagens.close();
  });
}
