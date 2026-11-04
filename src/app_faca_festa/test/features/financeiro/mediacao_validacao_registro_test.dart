import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/central_mediacao_detalhe_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/data/datasources/remote/central_mediacao_remote.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/central_mediacao_controller.dart';
import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';

class _Remote extends Fake implements CentralMediacaoRemote {
  int chamadas = 0;
  String? enviado;
  bool falhar = false;

  @override
  Future<Map<String, dynamic>> consultarDetalhe(
          {required String idOrcamento}) async =>
      {
        'resumo': {
          'idEvento': 'evento',
          'estadoComercial': 'Contratado',
          'nomeServico': 'Decoração'
        },
        'contratacao_servico': {
          'estado_comercial': 'Contratado',
          'estado_execucao': 'entrega_informada'
        },
        'historico_mediacao': {
          'caso_aberto': {'id': 'caso'}
        },
      };

  @override
  dynamic noSuchMethod(Invocation invocation) {
    chamadas++;
    return super.noSuchMethod(invocation);
  }

  @override
  Future<Map<String, dynamic>> registrarRegistro(
      {required String idCaso,
      required String texto,
      String tipo = 'analise',
      String? visibilidade,
      String? novoEstado}) async {
    chamadas++;
    enviado = texto;
    if (falhar) {
      throw const FinanceiroCallableException(
          'invalid-argument', 'Informe o texto do registro.');
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> consultarCaso(
          {required String idCaso,
          String? papelConsulta,
          String? idFornecedorOperador}) async =>
      {
        'caso': {'id': idCaso, 'estado': 'em_analise'},
        'registros': []
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  testWidgets(
      'nota vazia mostra erro no campo e permite corrigir sem erro global',
      (tester) async {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final remote = _Remote();
    final controller = CentralMediacaoController(remote: remote);
    await tester.pumpWidget(GetMaterialApp(
        home: CentralMediacaoDetalhePage(
            controller: controller,
            themeController: EventThemeController(),
            idOrcamento: 'orc')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mediação e histórico'));
    await tester.pumpAndSettle();
    final nota = find.text('Nota interna');
    await tester.scrollUntilVisible(nota, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(nota);
    await tester.pumpAndSettle();
    await tester.tap(nota);
    await tester.pumpAndSettle();
    expect(remote.chamadas, 0);
    expect(controller.erro.value, isEmpty);
    expect(controller.erroRegistro.value,
        'Escreva o texto no campo Novo registro antes de continuar.');
    expect(
        find.text('Escreva o texto no campo Novo registro antes de continuar.'),
        findsOneWidget);
    final campo = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Novo registro');
    expect(tester.widget<TextField>(campo).focusNode!.hasFocus, true);
    await tester.enterText(campo, 'Análise documentada.');
    await tester.pumpAndSettle();
    expect(controller.erroRegistro.value, isEmpty);
    await tester.ensureVisible(nota);
    await tester.tap(nota);
    await tester.pumpAndSettle();
    expect(remote.chamadas, 1);
    expect(tester.widget<TextField>(campo).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('texto vazio ou só espaços não chama servidor para ações do registro',
      () async {
    final remote = _Remote();
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    for (final texto in ['', '   \n ']) {
      expect(await c.registrarAnalise(texto), false);
      expect(await c.registrarAnalise(texto, interna: false), false);
      expect(await c.solicitarInfo(texto), false);
      expect(await c.registrarDecisao(texto), false);
      expect(await c.recomendarBloqueio(texto), false);
      expect(c.erroRegistro.value, contains('Novo registro'));
    }
    expect(remote.chamadas, 0);
    expect(c.erro.value, isEmpty);
    expect(c.enviando.value, false);
  });

  test('decisão e conclusão respeitam os limites do backend antes de enviar',
      () async {
    final remote = _Remote();
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    for (final texto in ['curto', List.filled(2001, 'a').join()]) {
      expect(await c.registrarDecisao(texto), false);
      expect(c.erroRegistro.value, contains('10 a 2000'));
      expect(await c.fecharCaso(texto), false);
      expect(c.erroConclusao.value, contains('10 a 2000'));
    }
    expect(remote.chamadas, 0);
  });

  test('registro válido limpa erro anterior e envia texto sem espaços externos',
      () async {
    final remote = _Remote();
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    await c.registrarAnalise('');
    c.erro.value = 'erro antigo';
    expect(await c.registrarAnalise('  Análise documentada.  '), true);
    expect(remote.enviado, 'Análise documentada.');
    expect(remote.chamadas, 1);
    expect(c.erroRegistro.value, isEmpty);
    expect(c.erro.value, isEmpty);
  });

  test('erro conhecido de envio fica no campo sem prefixo técnico', () async {
    final remote = _Remote()..falhar = true;
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    expect(await c.registrarAnalise('Análise documentada.'), false);
    expect(c.erroRegistro.value, 'Informe o texto do registro.');
    expect(c.erro.value, isEmpty);
  });

  test('linha normaliza o estado comercial recebido com maiúsculas e espaços',
      () {
    final linha =
        LinhaCentralContratacao.fromMap({'estado_comercial': ' Contratado '});
    expect(linha.estadoComercial, 'contratado');
  });
}
