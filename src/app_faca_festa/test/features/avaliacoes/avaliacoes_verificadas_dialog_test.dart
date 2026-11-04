import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/avaliacao.dart';
import 'package:app_faca_festa/domain/repositories/avaliacao_servico_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_avaliacoes_servico.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/pages/enviar_avaliacao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _Repo implements AvaliacaoServicoRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Controller extends AvaliacaoServicoController {
  _Controller(this.lista)
      : super(avaliacoes: GerenciarAvaliacoesServico(_Repo()));
  final List<Map<String, dynamic>> lista;
  @override
  Future<List<Map<String, dynamic>>> contratosAvaliaveis(
          {required String idFornecedor,
          required String idEvento,
          String? idServico}) async =>
      lista;
}

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() => Get.reset());
  testWidgets(
      'duas contratações exigem escolha explícita, sem atribuição por evento',
      (t) async {
    final c = _Controller([
      {'idContrato': 'c1', 'idOrcamento': 'o1', 'nome': 'Buffet'},
      {'idContrato': 'c2', 'idOrcamento': 'o2', 'nome': 'Decoração'}
    ]);
    await t.pumpWidget(GetMaterialApp(
        home: Scaffold(
            body: EnviarAvaliacaoDialog(
                idFornecedor: 'f',
                idServico: null,
                idCliente: 'a',
                nomeCliente: 'Enviado pelo cliente',
                idEvento: 'e',
                nomeEventoAtual: 'Sintético',
                tipo: TipoAvaliacao.fornecedor,
                controller: c,
                themeController: EventThemeController()))));
    await t.pumpAndSettle();
    final botao = t.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton));
    expect(botao.onPressed, isNull);
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Decoração (c2)').last);
    await t.pumpAndSettle();
    expect(
        t
            .widget<ElevatedButton>(
                find.byWidgetPredicate((w) => w is ElevatedButton))
            .onPressed,
        isNotNull);
    expect(
        find.textContaining('Uma avaliação por contratação'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('sem entrega aceita o envio permanece desabilitado', (t) async {
    final c = _Controller([]);
    await t.pumpWidget(GetMaterialApp(
        home: Scaffold(
            body: EnviarAvaliacaoDialog(
                idFornecedor: 'f',
                idServico: null,
                idCliente: 'a',
                nomeCliente: 'Cliente',
                idEvento: 'e',
                nomeEventoAtual: 'Sintético',
                tipo: TipoAvaliacao.fornecedor,
                controller: c,
                themeController: EventThemeController()))));
    await t.pumpAndSettle();
    expect(find.textContaining('Nenhuma contratação com entrega aceita'),
        findsOneWidget);
    expect(
        t
            .widget<ElevatedButton>(
                find.byWidgetPredicate((w) => w is ElevatedButton))
            .onPressed,
        isNull);
  });
}
