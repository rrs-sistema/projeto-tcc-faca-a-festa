import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_model.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_gasto_model.dart';
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
  test('orçamento e gasto leem a execução e o serviço gravados na contratação',
      () {
    final orcamento = OrcamentoModel.fromMap({
      'id_orcamento': 'orc',
      'id_produto_servico': 'servico',
      'estado_execucao': 'entrega_informada',
      'contrato_financeiro': {
        'id_contrato': 'contrato',
        'estado_execucao': 'aceito'
      },
    }).copyWith();
    expect(orcamento.idServicoFornecido, 'servico');
    expect(orcamento.estadoExecucao, 'aceito');
    expect(orcamento.idContrato, 'contrato');
    final gasto = OrcamentoGastoModel.fromMap({
      'id_servico_contratado': 'servico',
      'nome_servico_contratado': 'Arco floral',
    });
    expect(gasto.idServicoContratado, 'servico');
    expect(gasto.nomeServicoContratado, 'Arco floral');
  });

  for (final elegivel in [false, true]) {
    testWidgets(
        'avaliação pelo orçamento fica vinculada ao contrato ($elegivel)',
        (t) async {
      final c = _Controller([
        {
          'idContrato': 'outro',
          'idOrcamento': 'outro-orc',
          'nome': 'Outro pedido'
        },
        if (elegivel)
          {
            'idContrato': 'alvo',
            'idOrcamento': 'espelho',
            'nome': 'Arco floral'
          },
      ]);
      await t.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: EnviarAvaliacaoDialog(
            idFornecedor: 'f',
            idServico: 's',
            idCliente: 'a',
            nomeCliente: 'Cliente',
            idEvento: 'e',
            nomeEventoAtual: 'Evento',
            tipo: TipoAvaliacao.servico,
            idOrcamentoAlvo: 'orc',
            idContratoAlvo: 'alvo',
            controller: c,
            themeController: EventThemeController(),
          ),
        ),
      ));
      await t.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text('Outro pedido'), findsNothing);
      expect(
          find.text('Arco floral'), elegivel ? findsOneWidget : findsNothing);
      expect(
          find.byType(TextFormField), elegivel ? findsOneWidget : findsNothing);
      final botao = t.widget<ElevatedButton>(
          find.byWidgetPredicate((w) => w is ElevatedButton));
      expect(botao.onPressed, elegivel ? isNotNull : isNull);
    });
  }
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
