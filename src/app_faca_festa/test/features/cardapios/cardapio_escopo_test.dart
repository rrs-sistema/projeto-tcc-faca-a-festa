import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/cadastro_cardapio_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/editar_cardapio_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../calculadora/calculadora_jornada_test.dart' show CardapioQA;

class RepoEscopo extends CardapioQA {
  Cardapio? salvo;
  @override
  Future<void> salvarCardapio(Cardapio cardapio) async {
    salvo = cardapio;
  }
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  Future<void> abrir(WidgetTester tester, Widget modal) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => modal),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('novo cardápio persiste categoria em tela pequena',
      (tester) async {
    final repo = RepoEscopo();
    final c = CardapioController(repository: repo);
    addTearDown(c.onClose);
    await abrir(
        tester,
        CadastroCardapioBottomSheet(
            idEvento: 'festa', controller: c, primaryColor: Colors.green));
    await tester.enterText(find.byType(TextFormField).first, 'Bebidas');
    await tester.ensureVisible(find.text('Categoria'));
    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(repo.salvo!.escopo, EscopoCardapio.categoria);
    expect(repo.salvo!.idEvento, 'festa');
    expect(repo.salvo!.titulo, 'Bebidas');
    expect(tester.takeException(), isNull);
  });
  testWidgets('editar título legado mantém escopo indefinido e os demais dados',
      (tester) async {
    final repo = RepoEscopo();
    final c = CardapioController(repository: repo);
    addTearDown(c.onClose);
    const antigo = Cardapio(
        idEvento: 'festa',
        idCardapio: 'antigo',
        titulo: 'Comidas',
        publicoAlvo: PublicoAlvoCardapio.criancas,
        totalItens: 4,
        ativo: false);
    await abrir(
        tester,
        EditarCardapioBottomSheet(
            cardapio: antigo, controller: c, primaryColor: Colors.green));
    await tester.enterText(
        find.byType(TextFormField).first, 'Comidas da festa');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(repo.salvo!.escopo, EscopoCardapio.naoDefinido);
    expect(repo.salvo!.publicoAlvo, PublicoAlvoCardapio.criancas);
    expect(repo.salvo!.idCardapio, 'antigo');
    expect(repo.salvo!.totalItens, 4);
    expect(repo.salvo!.ativo, false);
    expect(tester.takeException(), isNull);
  });
}
