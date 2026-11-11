import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/data/datasources/remote/intermediacao_financeira_remote.dart';
import 'package:app_faca_festa/domain/entities/financeiro/intermediacao_financeira.dart';
import 'package:app_faca_festa/domain/services/intermediacao_financeira_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/intermediacao_financeira_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/intermediacao_financeira_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _Remote extends Fake implements IntermediacaoFinanceiraRemote {
  final registrar = Completer<void>();
  final concluirAlocacao = Completer<void>();
  int? recebidoCentavos;
  int? alocadoCentavos;

  @override
  Future<Map<String, dynamic>> consultarExtrato(String idEvento) async => {
        'recebimentos': [
          if (recebidoCentavos != null)
            {
              'id': 'rec-1',
              'valor_centavos': recebidoCentavos,
              'alocado_centavos': alocadoCentavos ?? 0,
            },
        ],
      };

  @override
  Future<Map<String, dynamic>> registrarRecebimento({
    required String idEvento,
    required int valorCentavos,
    required String chaveIdempotencia,
    String? idPagador,
    String nivelConfirmacao = 'conferencia',
    String? referencia,
  }) async {
    await registrar.future;
    recebidoCentavos = valorCentavos;
    return {};
  }

  @override
  Future<Map<String, dynamic>> alocar({
    required String idRecebimento,
    required List<Map<String, dynamic>> alocacoes,
    required String chaveIdempotencia,
  }) async {
    await concluirAlocacao.future;
    alocadoCentavos = alocacoes.single['valorCentavos'] as int;
    return {};
  }
}

void main() {
  const svc = IntermediacaoFinanceiraService();

  testWidgets('recebimento e alocação validam, exibem progresso e enviam centavos',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(Get.reset);
    await tester.binding.setSurfaceSize(const Size(1200, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final remote = _Remote();
    await tester.pumpWidget(GetMaterialApp(
      home: IntermediacaoFinanceiraPage(
        controller: IntermediacaoFinanceiraController(remote: remote),
        themeController: EventThemeController(),
      ),
    ));

    Finder campo(String label) => find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == label);
    final lista = find.byType(Scrollable).first;
    Future<void> tocar(Finder alvo) async {
      await tester.scrollUntilVisible(alvo, 250, scrollable: lista);
      await tester.pumpAndSettle();
      await tester.tap(alvo);
    }
    Future<void> preencher(String label, String valor) async {
      final alvo = campo(label);
      await tester.scrollUntilVisible(alvo, 250, scrollable: lista);
      await tester.pumpAndSettle();
      await tester.enterText(alvo, valor);
    }

    await preencher('Referência do evento', 'evento-1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final alocar = find.text('Alocar ao contrato');
    await tocar(alocar);
    await tester.pumpAndSettle();
    expect(
        find.text('Selecione um recebimento. Informe o orçamento ou contrato. '
            'Informe um valor maior que zero.'),
        findsOneWidget);
    expect(find.byType(GetSnackBar), findsNothing);

    const valorRecebido = 'Valor (R\$)';
    await preencher(valorRecebido, '18700');
    expect(tester.widget<TextField>(campo(valorRecebido)).controller!.text,
        'R\$ 187,00');
    final registrar = find.text('Registrar recebimento').last;
    await tocar(registrar);
    await tester.pump();
    expect(find.text('Registrando recebimento…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final botaoAlocar = find.ancestor(
        of: alocar,
        matching: find.byWidgetPredicate((widget) => widget is FilledButton));
    expect(tester.widget<FilledButton>(botaoAlocar).onPressed, isNull);
    remote.registrar.complete();
    await tester.pumpAndSettle();
    expect(remote.recebidoCentavos, 18700);
    expect(
        find.text('Recebimento registrado. Você pode alocá-lo a um contrato.'),
        findsOneWidget);

    const valorAlocado = 'Valor a alocar (R\$)';
    await preencher('ID do orçamento / contrato', 'orc-1');
    await tester.scrollUntilVisible(campo(valorAlocado), 250,
        scrollable: lista);
    expect(tester.widget<TextField>(campo(valorAlocado)).controller!.text,
        'R\$ 187,00');
    await preencher(valorAlocado, '12345');
    expect(tester.widget<TextField>(campo(valorAlocado)).controller!.text,
        'R\$ 123,45');
    await tocar(alocar);
    await tester.pump();
    expect(find.text('Alocando ao contrato…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    remote.concluirAlocacao.complete();
    await tester.pumpAndSettle();
    expect(remote.alocadoCentavos, 12345);
    expect(find.text('Valor alocado ao contrato. O repasse é conferido no passo 4.'),
        findsOneWidget);
  });

  test('10k com 5% descontada: 9500 fornecedor sem cobrança duplicada', () {
    final d = svc.calcularDireitos(
      valorContratadoCentavos: 1000000,
      percentualBps: 500,
    );
    expect(d.direitoFornecedorPrevistoCentavos, 950000);
    expect(d.comissaoPrevistaCentavos, 50000);
    expect(d.precoClienteCentavos, 1000000);
  });

  test('parcial 4k sem política não libera repasse nem marca recebido fornecedor', () {
    final eleg = svc.avaliarElegibilidade(
      direitoFornecedorCentavos: 950000,
      alocadoCentavos: 400000,
      jaRepassadoCentavos: 0,
      jaAuthCentavos: 0,
      politicaAtiva: false,
    );
    expect(eleg.elegivelCentavos, 0);
    expect(eleg.estado, EstadoRepasse.elegivelPendente);
    expect(1000000 - 400000, 600000); // a receber cliente
  });

  test('política sintética teto 3k + confirmação manual', () {
    final eleg = svc.avaliarElegibilidade(
      direitoFornecedorCentavos: 950000,
      alocadoCentavos: 400000,
      jaRepassadoCentavos: 0,
      jaAuthCentavos: 0,
      politicaAtiva: true,
      permiteParcial: true,
      tetoParcialCentavos: 300000,
    );
    expect(eleg.elegivelCentavos, 300000);
    expect(svc.confirmarManual(EstadoRepasse.autorizado), EstadoRepasse.confirmado);
    final caixa = svc.conciliarCaixa(
      recebidoCentavos: 400000,
      alocadoCentavos: 400000,
      repassadoCentavos: 300000,
    );
    expect(caixa.residual, 100000);
    expect(caixa.ok, isTrue);
  });

  test('concorrência 6k: 4k+3k não passam juntos', () {
    final r = svc.concorrenciaAlocacao(
      disponivelCentavos: 600000,
      pedidoACentavos: 400000,
      pedidoBCentavos: 300000,
    );
    expect(r.aceitoA, isTrue);
    expect(r.aceitoB, isFalse);
    expect(svc.tentarAlocar(
      valorRecebimentoCentavos: 600000,
      jaAlocadoCentavos: 400000,
      pedidoCentavos: 300000,
    ), isNull);
  });

  test('chargeback após repasse preserva histórico', () {
    final c = svc.chargebackPosRepasse(
      valorChargebackCentavos: 200000,
      repassadoConfirmadoCentavos: 300000,
    );
    expect(c.repassePreservado, 300000);
    expect(c.recuperacaoPendente, 200000);
  });
}
