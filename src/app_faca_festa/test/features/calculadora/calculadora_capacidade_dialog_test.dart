import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_ai_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_capacidade_dialog.dart';

class _Repository extends Fake implements CalculadoraFestaRepository {}

class _Itens extends Fake implements CalculadoraItensBaseRepositoryContract {}

class _Ai extends Fake implements ICalculadoraFestaAIService {}

void main() {
  testWidgets(
      'confirmar verba não exige simulação; cancelar preserva valor e público misto tem limitação',
      (tester) async {
    final c = CalculadoraFestaController(
        aiService: _Ai(),
        repository: _Repository(),
        itensBaseRepository: _Itens());
    c.verbaAlimentacao.value = 200;
    c.orcamentoDisponivel.value = 8500;
    final calc = CalculadoraFesta(
        idCalculo: 'teste',
        idEvento: 'evento',
        tipoEvento: 'Evento',
        baseCalculo: BaseCalculoFesta.previstos,
        totalAdultos: 20,
        totalCriancas: 5,
        totalBebes: 0,
        duracaoHoras: 4,
        dataCalculo: DateTime(2026),
        dataAtualizacao: DateTime(2026),
        perfilFesta: PerfilFesta.padrao());
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) => CalculadoraCapacidadeDialog(
                            controller: c,
                            calculo: calc,
                            cardapios: const [],
                            itens: const {},
                            regras: const [],
                            consultaCompleta: true)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '500,00');
    await tester.tap(find.text('Simular capacidade'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('públicos ou grupos específicos'), findsOneWidget);
    expect(c.verbaAlimentacao.value, 200);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(c.verbaAlimentacao.value, 200);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0,00');
    await tester.tap(find.text('Usar esta verba'));
    await tester.pumpAndSettle();
    expect(c.verbaAlimentacao.value, 0);
  });
  testWidgets('simulação pendente permite confirmar verba explicitamente',
      (tester) async {
    final controller = CalculadoraFestaController(
        aiService: _Ai(),
        repository: _Repository(),
        itensBaseRepository: _Itens());
    controller.orcamentoDisponivel.value = 8500;
    final calculo = CalculadoraFesta(
        idCalculo: 'calculo',
        idEvento: 'evento',
        tipoEvento: 'Evento',
        baseCalculo: BaseCalculoFesta.todosConvidados,
        totalAdultos: 38,
        totalCriancas: 0,
        totalBebes: 0,
        duracaoHoras: 4,
        dataCalculo: DateTime(2026),
        dataAtualizacao: DateTime(2026),
        perfilFesta: PerfilFesta.padrao());
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => CalculadoraCapacidadeDialog(
                              controller: controller,
                              calculo: calculo,
                              cardapios: const [
                                Cardapio(
                                    idCardapio: 'almoco',
                                    idEvento: 'evento',
                                    titulo: 'Almoço',
                                    escopo: EscopoCardapio.compartilhado)
                              ],
                              itens: const {},
                              regras: const [],
                              consultaCompleta: true)),
                      child: const Text('Abrir')),
                ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1450,00');
    await tester.tap(find.text('Simular capacidade'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível estimar a capacidade'),
        findsOneWidget);
    expect(controller.verbaAlimentacao.value, isNull);
    await tester.tap(find.text('Usar esta verba'));
    await tester.pumpAndSettle();
    expect(controller.verbaAlimentacao.value, 1450);
    expect(find.byType(CalculadoraCapacidadeDialog), findsNothing);
    expect(find.textContaining('aplicada ao planejamento'), findsOneWidget);
  });
}
