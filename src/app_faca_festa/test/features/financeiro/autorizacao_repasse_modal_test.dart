import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/data/datasources/remote/acompanhamento_partes_remote.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/acompanhamento_partes_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/acompanhamento_organizador_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _Remote extends Fake implements AcompanhamentoPartesRemote {
  final pedidos = <(String, String, bool)>[];
  Completer<Map<String, dynamic>> resposta = Completer();

  @override
  Future<Map<String, dynamic>> consultarOrganizador(
          {required String idEvento}) async =>
      {
        'linhas': [
          {
            'idContrato': 'contrato-1',
            'idOrcamento': 'orcamento-1',
            'nomeFornecedor': 'Decora Festas',
            'nomeServico': 'Decoração do salão',
          }
        ],
      };

  @override
  Future<Map<String, dynamic>> autorizarRepasse({
    required String idOrcamento,
    required String motivo,
    required bool autorizar,
  }) async {
    pedidos.add((idOrcamento, motivo, autorizar));
    return resposta.future;
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(Get.reset);

  for (final autorizar in [true, false]) {
    testWidgets(
        autorizar
            ? 'autoriza em tela estreita com teclado e texto ampliado'
            : 'revoga no desktop e permite cancelar sem enviar',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize =
          autorizar ? const Size(360, 780) : const Size(1280, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);

      final remote = _Remote();
      await tester.pumpWidget(GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(autorizar ? 1.4 : 1),
          ),
          child: child!,
        ),
        home: AcompanhamentoOrganizadorPage(
          controller: AcompanhamentoPartesController(remote: remote),
          themeController: EventThemeController(),
          idEvento: 'evento-1',
        ),
      ));
      await tester.pumpAndSettle();

      final abrir = find.text(
          autorizar ? 'Autorizar pagamento antecipado' : 'Revogar autorização');
      final modal = autorizar ? find.byType(BottomSheet) : find.byType(Dialog);
      Future<void> abrirModal() async {
        await tester.ensureVisible(abrir);
        await tester.pumpAndSettle();
        await tester.tap(abrir);
        await tester.pumpAndSettle();
        expect(modal, findsOneWidget);
      }

      await abrirModal();
      expect(find.text('Decora Festas · Decoração do salão'), findsOneWidget);
      if (!autorizar) {
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(modal, findsNothing);
        expect(remote.pedidos, isEmpty);
        await abrirModal();
      }

      final motivo = find.descendant(
        of: modal,
        matching: find.byType(TextFormField),
      );
      final confirmar = find.descendant(
        of: modal,
        matching: find
            .text(autorizar ? 'Autorizar pagamento' : 'Revogar autorização'),
      );
      await tester.ensureVisible(motivo);
      await tester.enterText(motivo, 'curto');
      if (autorizar) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 410);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.ensureVisible(confirmar);
      await tester.pumpAndSettle();
      expect(confirmar.hitTestable(), findsOneWidget);
      if (autorizar) {
        expect(tester.getBottomRight(confirmar).dy, lessThanOrEqualTo(370));
      }
      await tester.tap(confirmar);
      await tester.pumpAndSettle();
      expect(find.text('Informe pelo menos 10 caracteres.'), findsOneWidget);
      expect(remote.pedidos, isEmpty);

      await tester.ensureVisible(motivo);
      await tester.enterText(
          motivo, '  Condições acordadas com o fornecedor.  ');
      await tester.ensureVisible(confirmar);
      await tester.pumpAndSettle();
      await tester.tap(confirmar);
      tester.view.resetViewInsets();
      await tester.pump();
      expect(modal, findsOneWidget);
      final carregando = find.descendant(
        of: modal,
        matching: find.text(
            autorizar ? 'Registrando autorização…' : 'Revogando autorização…'),
      );
      expect(carregando, findsOneWidget);
      expect(
        find.descendant(
            of: modal, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
      expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
              .onPressed,
          isNull);
      expect(tester.widget<TextFormField>(motivo).controller!.text,
          '  Condições acordadas com o fornecedor.  ');
      final rota = ModalRoute.of(tester.element(motivo))!;
      expect(rota.popDisposition, RoutePopDisposition.doNotPop);
      expect(remote.pedidos, hasLength(1));

      if (!autorizar) {
        remote.resposta.completeError(StateError('Falha simulada.'));
        await tester.pumpAndSettle();
        expect(modal, findsOneWidget);
        expect(
            find.text(
                'Não foi possível revogar a autorização. Tente novamente.'),
            findsOneWidget);
        expect(tester.widget<TextFormField>(motivo).controller!.text,
            '  Condições acordadas com o fornecedor.  ');
        remote.resposta = Completer();
        await tester.ensureVisible(confirmar);
        await tester.pumpAndSettle();
        await tester.tap(confirmar);
        await tester.pump();
        expect(carregando, findsOneWidget);
      }

      remote.resposta.complete({});
      await tester.pumpAndSettle();
      expect(modal, findsNothing);
      expect(remote.pedidos, [
        ('orcamento-1', 'Condições acordadas com o fornecedor.', autorizar),
        if (!autorizar)
          ('orcamento-1', 'Condições acordadas com o fornecedor.', false),
      ]);
      expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(autorizar
                ? 'Autorização registrada.'
                : 'Autorização antecipada revogada.'),
          ),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
