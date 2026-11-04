import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/cotacao_chat.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/chat/chat_mensagens_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _Cotacoes extends Fake implements GerenciarCotacoes {
  final mensagens = StreamController<List<CotacaoMensagem>>.broadcast();
  final envio = Completer<void>();
  int envios = 0;
  int leituras = 0;
  @override
  Stream<List<CotacaoMensagem>> observarMensagens(
          {required String idCotacao, required String idFornecedor}) =>
      mensagens.stream;
  @override
  Stream<List<CotacaoFornecedorResumo>> observarFornecedoresDaCotacao(
          String idCotacao) =>
      Stream.value([]);
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
  Future<_Cotacoes> abrir(WidgetTester tester) async {
    final cotacoes = _Cotacoes();
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
