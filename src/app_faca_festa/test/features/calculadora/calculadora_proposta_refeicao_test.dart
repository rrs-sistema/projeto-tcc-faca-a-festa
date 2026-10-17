import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calculadora_composicao_test.dart' show AuthQA;
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_proposta_card.dart';
import 'calculadora_integridade_ponta_a_ponta_test.dart' show controller, regra;

const service = PropostaRefeicaoService();
CardapioItem item(String nome,
        {String? id,
        String unidade = 'un',
        double finalPlanejado = 0,
        PublicoAlvoCardapio publico = PublicoAlvoCardapio.todos}) =>
    CardapioItem(
        idItem: id ?? nome,
        idEvento: 'festa',
        idCardapio: 'almoco',
        nome: nome,
        tipo: TipoItemCardapio.comida,
        publicoAlvo: publico,
        unidade: unidade,
        quantidadeFinal: finalPlanejado);

CalculadoraFestaController preparar(List<CardapioItem> itens) {
  final c = controller(disponivel: false);
  c.regrasManuais.clear();
  c.itensEstimativa.clear();
  c.operacaoEvento.clear();
  c.idCardapioAtual = 'almoco';
  c.atualizarCardapio(itens, titulo: 'Almoço', disponivel: true);
  return c;
}

void main() {
  setUp(() => Get.put<FirebaseAuth>(AuthQA()));
  tearDown(() => Get.reset());
  test('propõe a refeição inteira e explicita a divisão dos acompanhamentos',
      () {
    final itens = [item('Churrasco 🍖'), item('Arroz 🍚'), item('Macarrão 🍜')];
    final p = service.gerar(itens: itens, regras: []);
    expect(p.regras.length, 3);
    expect(p.perguntas.map((q) => q.id), contains('amidos'));
    expect(p.regras.first.premissas['papel_na_refeicao'], 'principal');
    expect(p.regras.first.premissas['estado'], 'pronto');
    expect(p.regras.first.premissas['proposta_apenas_servir'], true);
    expect(p.regras.skip(1).every((r) => r.fatorComposicao == .5), true);
    final independentes = service
        .gerar(itens: itens, regras: [], respostas: {'amidos': 'inteiros'});
    expect(independentes.regras.every((r) => r.fatorComposicao == 1), true);
    expect(p.regras.every((r) => r.valorUnitarioMedio == 0), true);
  });
  test('públicos e destinos alimentares distintos não compartilham porção', () {
    final itens = [item('Churrasco'), item('Arroz'), item('Macarrão')];
    final p = service.gerar(
        itens: itens,
        regras: [],
        publicosDosItens: {'Arroz': 'todos', 'Macarrão': 'grupo vegetariano'});
    expect(p.perguntas.where((q) => q.id == 'amidos'), isEmpty);
    expect(p.regras.every((r) => r.fatorComposicao == 1), true);
    final outro = service.gerar(itens: [
      itens.first,
      itens[1],
      item('Macarrão', publico: PublicoAlvoCardapio.adultos)
    ], regras: []);
    expect(outro.perguntas.where((q) => q.id == 'amidos'), isEmpty);
  });
  test('massa sem outro principal mantém porção inteira e papel de principal',
      () {
    final p =
        service.gerar(itens: [item('Macarrão'), item('Arroz')], regras: []);
    expect(p.perguntas.where((q) => q.id == 'amidos'), isEmpty);
    expect(p.regras.first.premissas['papel_na_refeicao'], 'principal');
    expect(p.regras.every((r) => r.fatorComposicao == 1), true);
  });
  test('receita manual e preço compatível são preservados', () {
    final r = regra.copyWith(
        id: 'menu_almoco_arroz',
        quantidadePorConvidadoEquivalente: .15,
        premissas: {...regra.premissas, 'receita': 'Arroz da família'});
    final p = service.gerar(itens: [
      item('Arroz', id: 'arroz', unidade: 'kg'),
      item('Macarrão'),
      item('Churrasco')
    ], regras: [
      r
    ]);
    expect(p.regras.first.quantidadePorConvidadoEquivalente, .15);
    expect(p.regras.first.valorUnitarioMedio, 10);
    expect(p.preservados, contains(r.id));
    expect(p.perguntas.where((q) => q.id == 'amidos'), isEmpty);
    final base = regra.copyWith(premissas: {'estado': 'cru'});
    final simples = service.gerar(
        itens: [item('Arroz', id: 'arroz', unidade: 'kg')], regras: [base]);
    expect(simples.regras.single.valorUnitarioMedio, 10);
  });
  test('não muda unidades já planejadas ou reconhece nomes ambíguos como arroz',
      () {
    final p = service.gerar(
        itens: [item('Arroz', finalPlanejado: 3), item('Arroz doce')],
        regras: []);
    expect(p.regras, isEmpty);
    expect(p.pendencias.length, 2);
  });
  test(
      'cachorro-quente tem duas perguntas materiais e mini requer só uma porção',
      () {
    final itens = [item('Cachorro quente 🌭', id: 'dog')];
    final p = service.gerar(itens: itens, regras: []);
    expect(p.perguntas.length, 2);
    expect(p.regras.single.quantidadePorConvidadoEquivalente, 2);
    final complemento = service.gerar(
        itens: itens, regras: [], respostas: {'dog_uso_dog': 'complemento'});
    expect(complemento.regras.single.quantidadePorConvidadoEquivalente, 1);
    final grande = service.gerar(
        itens: itens, regras: [], respostas: {'dog_tamanho_dog': 'grande'});
    expect(grande.regras.single.quantidadePorConvidadoEquivalente, 1.5);
    final mini = service.gerar(
        itens: itens, regras: [], respostas: {'dog_tamanho_dog': 'mini'});
    expect(mini.regras, isEmpty);
    expect(mini.perguntas.last.opcoes, isEmpty);
    final informado = service.gerar(
        itens: itens,
        regras: [],
        respostas: {'dog_tamanho_dog': 'mini', 'dog_mini_dog': '3,5'});
    expect(informado.regras.single.quantidadePorConvidadoEquivalente, 3.5);
    final invalido = service.gerar(
        itens: itens,
        regras: [],
        respostas: {'dog_tamanho_dog': 'mini', 'dog_mini_dog': 'NaN'});
    expect(invalido.regras, isEmpty);
  });
  test('frutas distinguem função e compra, sem inventar perda', () {
    final p = service.gerar(itens: [item('Frutas')], regras: []);
    expect(p.perguntas.length, 2);
    expect(p.regras.single.quantidadePorConvidadoEquivalente, .125);
    expect(p.regras.single.pesoCrianca, .5);
    expect(p.regras.single.pesoBebe, 0);
    expect(p.regras.single.premissas['proposta_apenas_servir'], true);
    final sobremesa = service.gerar(
        itens: [item('Frutas')],
        regras: [],
        respostas: {'frutas_Frutas': 'sobremesa'});
    expect(sobremesa.regras.single.quantidadePorConvidadoEquivalente, .225);
  });
  test(
      'primeira prévia funciona sem regra remota nem cálculo anterior e adota sem preços',
      () {
    final c = preparar([item('Cachorro quente', id: 'dog')]);
    addTearDown(c.onClose);
    expect(c.calculoAtual.value, isNull);
    final p = c.proporRefeicao();
    expect(c.resultadosDaProposta(p).single.quantidade, 20);
    expect(c.itensCalculados, isEmpty);
    expect(c.regrasManuais, isEmpty);
    c.usarProposta(p, assinatura: c.assinaturaProposta);
    expect(c.itensCalculados.single.quantidade, 20);
    expect(c.regrasManuais.single.valorUnitarioMedio, 0);
    expect(c.itensCardapio.single.quantidadeFinal, 0);
    expect(c.itensCardapio.single.disponibilidade, isNull);
    expect(c.resumoCompras.completo, false);
    final roundtrip = ItemEstimativaFinanceira.fromPlanejamento(
        jsonDecode(jsonEncode(c.regrasManuais.single.toPlanejamento())));
    expect(roundtrip.premissas['proposta_refeicao'], 1);
    expect(roundtrip.premissas['proposta_respostas'], p.respostas);
  });
  test(
      'público da refeição e seu grupo são respeitados na prévia e no cálculo adotado',
      () {
    final c = preparar([item('Cachorro quente', id: 'dog')]);
    addTearDown(c.onClose);
    c.operacaoEvento['refeicoes'] = {
      'almoco': {
        'publico': {'adultos': 4, 'criancas': 2, 'bebes': 0},
        'grupos': [
          {'id': 'g', 'adultos': 2, 'criancas': 0, 'bebes': 0}
        ],
        'destinos_itens': {
          'dog': {
            'modo': 'grupos',
            'grupos': ['g']
          }
        }
      }
    };
    final p = c.proporRefeicao();
    expect(c.resultadosDaProposta(p).single.quantidade, 4);
    c.usarProposta(p, assinatura: c.assinaturaProposta);
    expect(c.itensCalculados.single.quantidade, 4);
  });
  test('proposta antiga ou histórica não sobrescreve o planejamento', () {
    final c = preparar([item('Frutas')]);
    addTearDown(c.onClose);
    final p = c.proporRefeicao(), assinatura = c.assinaturaProposta;
    c.totalAdultos.value = 12;
    expect(() => c.usarProposta(p, assinatura: assinatura), throwsStateError);
    expect(c.regrasManuais, isEmpty);
    c.usandoContextoHistorico.value = true;
    expect(() => c.usarProposta(p, assinatura: c.assinaturaProposta),
        throwsStateError);
  });
  test(
      'quantidade pronta para servir não vira compra crua e falta de preço não bloqueia proposta',
      () {
    final c = preparar([item('Churrasco')]);
    addTearDown(c.onClose);
    c.usarProposta(c.proporRefeicao(), assinatura: c.assinaturaProposta);
    expect(c.itensCalculados.single.quantidade, 3.25);
    expect(c.listaCompras.single.precisaConferir, true);
    expect(c.listaCompras.single.orientacao, contains('pronta para servir'));
  });
  test(
      'compra pronta dispensa conversão e compra crua usa somente rendimento medido',
      () {
    final c = preparar([item('Churrasco', id: 'carne')]);
    addTearDown(c.onClose);
    final crua = c.proporRefeicao(
        respostas: {'compra_carne': 'preparar', 'rendimento_carne': '0,5'});
    expect(crua.regras.single.rendimento, .5);
    expect(crua.regras.single.premissas['estado_compra'], 'cru');
    expect(crua.regras.single.premissas['rendimento_medido'], true);
    expect(c.resultadosDaProposta(crua).single.quantidade, 6.5);
    final pronta = c.proporRefeicao(respostas: {'compra_carne': 'pronto'});
    expect(pronta.regras.single.premissas['proposta_apenas_servir'], false);
    expect(c.resultadosDaProposta(pronta).single.quantidade, 3.25);
    final semMedir = c.proporRefeicao(respostas: {'compra_carne': 'preparar'});
    expect(semMedir.pendencias, isNotEmpty);
    expect(semMedir.regras.single.premissas['proposta_apenas_servir'], true);
    expect(c.resultadosDaProposta(semMedir).single.quantidade, 3.25);
  });
  test('grupo ligado a uma regra própria mantém sua composição protegida', () {
    final arroz = regra.copyWith(id: 'menu_almoco_arroz', premissas: {
      ...regra.premissas,
      'grupo': 'g',
      'dividir_grupo': true,
      'participacao': 1,
      'revisada_pelo_organizador': true,
    });
    final massa = arroz.copyWith(
        id: 'menu_almoco_massa',
        nome: 'Macarrão',
        premissas: {...arroz.premissas, 'proposta_refeicao': 1});
    final p = service.gerar(itens: [
      item('Arroz', id: 'arroz', unidade: 'kg'),
      item('Macarrão', id: 'massa', unidade: 'kg'),
      item('Churrasco')
    ], regras: [
      arroz,
      massa
    ]);
    expect(p.preservados, containsAll([arroz.id, massa.id]));
    expect(p.regras.take(2).every((r) => r.fatorComposicao == .5), true);
    expect(p.perguntas.where((q) => q.id == 'amidos'), isEmpty);
  });
  testWidgets(
      'edição manual de proposta remove a faixa sugerida e protege a nova receita',
      (tester) async {
    final original =
        service.gerar(itens: [item('Frutas')], regras: []).regras.single;
    ItemEstimativaFinanceira? editada;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (ctx) => TextButton(
                    onPressed: () async {
                      editada = await showDialog<ItemEstimativaFinanceira>(
                          context: ctx,
                          builder: (_) =>
                              CalculadoraRegraManualDialog(inicial: original));
                    },
                    child: const Text('Editar'))))));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    final consumo =
        find.widgetWithText(TextFormField, 'Quantidade por convidado');
    await tester.ensureVisible(consumo);
    await tester.enterText(consumo, '0,3');
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(editada, isNotNull);
    expect(editada!.premissas['consumo_min'], isNull);
    expect(editada!.premissas['proposta_refeicao'], isNull);
    expect(editada!.premissas['origem'], 'ajuste_organizador');
    final nova = service.gerar(itens: [item('Frutas')], regras: [editada!]);
    expect(nova.preservados, contains(original.id));
    expect(nova.regras.single.quantidadePorConvidadoEquivalente, .3);
  });
  testWidgets(
      'refinamento compacto recalcula com duas escolhas e confirma sem formulário técnico',
      (tester) async {
    final c = preparar([item('Cachorro quente', id: 'dog')]);
    addTearDown(c.onClose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (ctx) => TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) =>
                            CalculadoraPropostaDialog(controller: c)),
                    child: const Text('Propor'))))));
    await tester.tap(find.text('Propor'));
    await tester.pumpAndSettle();
    expect(find.text('20 un'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    final dropdown = find.byKey(const ValueKey('dog_uso_dog'));
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Junto de outros lanches').last);
    await tester.pumpAndSettle();
    expect(find.text('10 un'), findsOneWidget);
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(c.itensCalculados.single.quantidade, 10);
    expect(find.byType(CalculadoraPropostaDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'mini em tela pequena mantém confirmação acessível com teclado e cancelamento preserva dados',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final c = preparar([item('Mini cachorro quente', id: 'dog')]);
    addTearDown(c.onClose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (ctx) => TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) =>
                            CalculadoraPropostaDialog(controller: c)),
                    child: const Text('Propor'))))));
    await tester.tap(find.text('Propor'));
    await tester.pumpAndSettle();
    final campo = find.byKey(const ValueKey('dog_mini_dog'));
    await tester.ensureVisible(campo);
    await tester.enterText(campo, '3,5');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(find.text('Usar no cálculo').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(c.regrasManuais, isEmpty);
    expect(c.itensCalculados, isEmpty);
  });
}
