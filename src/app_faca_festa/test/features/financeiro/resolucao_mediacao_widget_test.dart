import 'package:app_faca_festa/data/datasources/remote/central_mediacao_remote.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/central_mediacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/central_mediacao_detalhe_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class _Remote extends Fake implements CentralMediacaoRemote {
  bool resolvido = false;
  String? motivoRecebido;

  @override
  Future<Map<String, dynamic>> consultarDetalhe(
          {required String idOrcamento}) async =>
      {
        'resumo': {
          'idEvento': 'evento',
          'idOrcamento': 'orc',
          'idContrato': 'orc',
          'nome_evento': 'Evento de teste',
          'nome_servico': 'Serviço contratado',
          'valorContratadoCentavos': 10000
        },
        'contratacao_servico': {
          'id_contrato': 'orc',
          'estado_comercial': 'contratado',
          'estado_execucao': resolvido ? 'em_execucao' : 'contestado'
        },
        'financeiro': {
          'comissao_centavos': 500,
          'direito_fornecedor_centavos': 9500,
          'pendenteRepasseCentavos': 9500
        },
        'historico_mediacao': {
          'ultimo_caso_encerrado': {'id': 'caso'}
        },
      };

  @override
  Future<Map<String, dynamic>> consultarCaso(
          {required String idCaso,
          String? papelConsulta,
          String? idFornecedorOperador}) async =>
      {
        'caso': {
          'id': 'caso',
          'estado': 'fechado',
          'motivo': 'Divergência analisada'
        },
        'registros': [],
      };

  @override
  Future<Map<String, dynamic>> resolverExecucao(
      {required String idCaso,
      required String estado,
      required String motivo,
      required bool retirarBloqueio}) async {
    expect(idCaso, 'caso');
    expect(estado, 'em_execucao');
    motivoRecebido = motivo;
    resolvido = true;
    return {'ok': true};
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() async {
    Get.reset();
  });

  testWidgets(
      'caso encerrado permite resolução explícita, confirma e atualiza execução',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
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
    final aplicar = find.text('Aplicar resolução da execução');
    await tester.scrollUntilVisible(aplicar, 400,
        scrollable: find.byType(Scrollable).first);
    final justificativa = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.labelText == 'Justificativa (mínimo 10 caracteres)');
    await tester.ensureVisible(justificativa);
    await tester.enterText(
        justificativa, 'Acordo entre as partes documentado na análise.');
    await tester.ensureVisible(aplicar);
    await tester.tap(aplicar);
    await tester.pumpAndSettle();
    expect(remote.resolvido, false);
    expect(find.text('Confirmar resolução administrativa'), findsOneWidget);
    await tester.tap(find.text('Confirmar resolução'));
    await tester.pumpAndSettle();
    expect(remote.resolvido, true);
    expect(remote.motivoRecebido, contains('Acordo entre as partes'));
    expect(controller.detalhe.value!['contratacao_servico']['estado_execucao'],
        'em_execucao');
    expect(find.text('Aplicar resolução da execução'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
