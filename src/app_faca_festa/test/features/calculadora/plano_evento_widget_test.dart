import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_plano_evento_card.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'calculadora_composicao_test.dart' show AiQA, AuthQA;
import 'calculadora_jornada_test.dart'
    show RepoJornada, BaseJornada, CardapioQA;

void main() {
  testWidgets(
      'prévia do conjunto em tela pequena preserva editor e abre destino por ID',
      (tester) async {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthQA());
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    final c = CalculadoraFestaController(
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    final menus = CardapioController(repository: CardapioQA());
    addTearDown(() {
      c.onClose();
      menus.onClose();
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await c.prepararCalculadora(
        idEvento: 'qa',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    c.atualizarOrcamentoDisponivel(1000);
    c.idCardapioAtual = 'editor_original';
    menus.cardapios.assignAll([
      const Cardapio(
          idCardapio: 'almoco',
          idEvento: 'qa',
          titulo: 'Almoço',
          escopo: EscopoCardapio.refeicao)
    ]);
    menus.itensPorCardapio['almoco'] = [
      const CardapioItem(
          idItem: 'arroz',
          idEvento: 'qa',
          idCardapio: 'almoco',
          nome: 'Arroz',
          tipo: TipoItemCardapio.comida)
    ];
    String? destino;
    await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
            body: ListView(children: [
      CalculadoraPlanoEventoCard(
          controller: c,
          cardapios: menus,
          onAbrirDestino: (id) => destino = id,
          onPublico: () {},
          onAjustar: (_) {}),
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('Seu plano do evento'), findsOneWidget);
    expect(find.text('Limite do evento: R\$ 1.000,00'), findsOneWidget);
    expect(c.idCardapioAtual, 'editor_original');
    final abrir = find.text('Conferir esta proposta');
    await tester.ensureVisible(abrir);
    await tester.pumpAndSettle();
    await tester.tap(abrir);
    expect(destino, 'almoco');
    expect(c.idCardapioAtual, 'editor_original');
    expect(tester.takeException(), isNull);
  });
}
