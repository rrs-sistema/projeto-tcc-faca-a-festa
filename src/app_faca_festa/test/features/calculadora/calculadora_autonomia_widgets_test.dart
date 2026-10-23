import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_capacidade_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_proposta_card.dart';
import 'calculadora_composicao_test.dart' show AuthQA;
import 'calculadora_proposta_refeicao_test.dart' show preparar, item;
import 'calculadora_autonomia_fase1_test.dart' show regraDog;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthQA());
  });
  tearDown(() => Get.reset());

  testWidgets(
      'referência escolhida permanece legível em modal pequeno com texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    final c = preparar([item('Churrasco', id: 'carne')]);
    addTearDown(() {
      c.onClose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final p = c.proporRefeicao(respostas: {
      'compra_carne': 'preparar',
      'preparo_carne': 'senar_sem_osso_v1'
    });
    c.usarProposta(p, assinatura: c.assinaturaProposta);
    await tester.pumpWidget(
        GetMaterialApp(home: CalculadoraPropostaDialog(controller: c)));
    await tester.pumpAndSettle();
    final anteriores = find.text('Escolhas anteriores e ajustes opcionais');
    await tester.ensureVisible(anteriores);
    await tester.tap(anteriores);
    await tester.pumpAndSettle();
    final campo = find.byKey(const ValueKey('preparo_carne'));
    await tester.ensureVisible(campo);
    await tester.pumpAndSettle();
    expect(campo, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'capacidade pede verba, valida limite, preserva público e invalida resultado antigo',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    final itens = [item('Cachorro-quente', id: 'dog')];
    final c = preparar(itens);
    c.adicionarItemManual(regraDog);
    c.atualizarTotaisManuais(adultos: 20, criancas: 0, bebes: 0);
    c.atualizarOrcamentoDisponivel(1000);
    final origem = 'refeicao'.obs;
    addTearDown(() {
      c.onClose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(GetMaterialApp(
        home: CalculadoraCapacidadeDialog(
            controller: c,
            calculo: c.calculoAtual.value!,
            cardapios: const [
              Cardapio(
                  idEvento: 'festa',
                  idCardapio: 'almoco',
                  titulo: 'Almoço',
                  escopo: EscopoCardapio.refeicao)
            ],
            itens: {'almoco': itens},
            regras: c.regrasDisponiveis,
            assinaturaFonte: () => origem.value,
            consultaCompleta: true)));
    await tester.pumpAndSettle();
    final campo = find.byType(TextField);
    expect(tester.widget<TextField>(campo).controller!.text, isEmpty);
    await tester.tap(find.text('Simular capacidade'));
    await tester.pumpAndSettle();
    expect(c.verbaAlimentacao.value, isNull);
    await tester.ensureVisible(campo);
    await tester.enterText(campo, '200000');
    await tester.tap(find.text('Simular capacidade'));
    await tester.pumpAndSettle();
    expect(c.verbaAlimentacao.value, isNull);
    await tester.enterText(campo, '10000');
    await tester.tap(find.text('Simular capacidade'));
    await tester.pumpAndSettle();
    // A prévia não confirma a verba; somente a ação explícita pode gravar.
    expect(c.verbaAlimentacao.value, isNull);
    expect(c.snapshotPlanejamento['verba_alimentacao'], isNull);
    expect(c.totalAdultos.value, 20);
    final resultado = find.textContaining('10 adultos neste cenário');
    await tester.ensureVisible(resultado);
    await tester.pumpAndSettle();
    expect(resultado, findsOneWidget);
    origem.value = 'compartilhado';
    await tester.pumpAndSettle();
    expect(resultado, findsNothing);
    final usarVerba = find.text('Usar esta verba');
    expect(usarVerba, findsOneWidget);
    expect(
        tester
            .widget<ButtonStyleButton>(find
                .ancestor(
                    of: usarVerba, matching: find.bySubtype<ButtonStyleButton>())
                .first)
            .onPressed,
        isNull);
    origem.value = 'refeicao';
    await tester.pumpAndSettle();
    expect(resultado, findsOneWidget);
    c.atualizarTotaisManuais(adultos: 30, criancas: 0, bebes: 0);
    await tester.pumpAndSettle();
    expect(resultado, findsNothing);
    expect(
        tester
            .widget<ButtonStyleButton>(find
                .ancestor(
                    of: usarVerba, matching: find.bySubtype<ButtonStyleButton>())
                .first)
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'escolhas aprovadas ficam recolhidas e podem ser corrigidas sem outra configuração técnica',
      (tester) async {
    final c = preparar([item('Cachorro-quente', id: 'dog')]);
    addTearDown(c.onClose);
    final p = c.proporRefeicao();
    c.usarProposta(p, assinatura: c.assinaturaProposta);
    await tester.pumpWidget(
        GetMaterialApp(home: CalculadoraPropostaDialog(controller: c)));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.tap(find.text('Escolhas anteriores e ajustes opcionais'));
    await tester.pumpAndSettle();
    final tamanho = find.byKey(const ValueKey('dog_tamanho_dog'));
    await tester.ensureVisible(tamanho);
    await tester.tap(tamanho);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grande / reforçado').last);
    await tester.pumpAndSettle();
    expect(tamanho, findsOneWidget);
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(c.respostasProposta['dog_tamanho_dog'], 'grande');
    expect(c.regrasManuais.single.quantidadePorConvidadoEquivalente, 1.5);
    expect(tester.takeException(), isNull);
  });
}
