import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/services/diagnostico_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_diagnostico_card.dart';

CardapioItem item(String nome,
        {PublicoAlvoCardapio publico = PublicoAlvoCardapio.todos}) =>
    CardapioItem(
        idItem: nome,
        idEvento: 'festa',
        idCardapio: 'almoco',
        nome: nome,
        unidade: 'kg',
        publicoAlvo: publico);
ItemEstimativaFinanceira regra(
        {String id = 'arroz', String publico = 'todos', double preco = 10}) =>
    ItemEstimativaFinanceira(
        id: id,
        categoria: 'comida',
        nome: 'Arroz',
        tipoItem: 'comida',
        publicoAlvo: publico,
        unidade: UnidadeEstimativa.quilo,
        quantidadePorConvidadoEquivalente: .1,
        valorUnitarioMedio: preco);

void main() {
  const revisao = RevisaoCardapioService();
  const diagnostico = DiagnosticoCalculadoraService();
  test('emojis não impedem correspondência e nome do cardápio é preservado',
      () {
    final resultado = revisao.regraPara(item('Arroz 🍚'), [regra()]);
    expect(resultado?.nome, 'Arroz 🍚');
    expect(resultado?.tipoItem, 'comida');
    expect(RevisaoCardapioService.normalizar('🍚 Arroz!'), 'arroz');
  });
  test(
      'regra específica tem prioridade; duplicatas específicas seguem ambíguas',
      () {
    final menu = item('Arroz', publico: PublicoAlvoCardapio.criancas);
    final especifica = regra(id: 'infantil', publico: 'criancas', preco: 20);
    expect(
        revisao.regraPara(menu, [regra(), especifica])?.valorUnitarioMedio, 20);
    expect(
        revisao.regraPara(
            menu, [especifica, especifica.copyWith(id: 'duplicada')]),
        isNull);
  });
  test('diagnóstico funciona sem catálogo e sem resultados', () {
    final d = diagnostico.analisar(
        pessoas: 40,
        cardapio: [item('Arroz 🍚'), item('Macarrão 🍝')],
        regras: []);
    expect(d.itensComRegra, 0);
    expect(d.semRegra.length, 2);
    expect(
        d.observacoes.single, contains('não reduz a porção automaticamente'));
  });
  test('falta de preço não é confundida com falta de consumo', () {
    final d = diagnostico.analisar(
        pessoas: 40, cardapio: [item('Arroz')], regras: [regra(preco: 0)]);
    expect(d.itensComRegra, 1);
    expect(d.semRegra, isEmpty);
    expect(d.semPreco, ['Arroz']);
  });
  test(
      'descartáveis contam crianças e bebês como pessoas, sem fator de perfil ou duração',
      () {
    final copos = regra().copyWith(
        tipoItem: 'descartavel',
        categoria: 'descartavel',
        unidade: UnidadeEstimativa.unidade,
        quantidadePorConvidadoEquivalente: 1);
    const pessoas = ConvidadosEquivalentes(adultos: 10, criancas: 10, bebes: 5);
    for (final perfil in [PerfilFesta.economico(), PerfilFesta.premium()]) {
      expect(
          copos.calcularQuantidadeArredondada(
              convidados: pessoas,
              perfil: perfil,
              duracaoHoras: 8,
              margemPersonalizada: 0),
          25);
    }
    expect(
        copos.copyWith(publicoAlvo: 'criancas').calcularQuantidadeArredondada(
            convidados: pessoas,
            perfil: PerfilFesta.padrao(),
            margemPersonalizada: 0),
        10);
  });
  test('financeiro exclui cancelados e sinaliza orçamento sem identidade', () {
    const service = CompromissoPlanejamentoService();
    expect(service.mapear('a', {'status': 'cancelado', 'custo_estimado': 6500}),
        isNull);
    expect(service.mapear('b', {'status_orcamento': 'cancelado'}), isNull);
    expect(
        service.mapear('c', {
          'id_servico_fornecido': 'buffet',
          'custo_estimado': 6500
        })?['cobertura_identificavel'],
        isFalse);
    expect(
        service.mapear('d', {
          'nome': 'Arroz 🍚',
          'unidade': 'kg',
          'custo_estimado': 100
        })?['identidade'],
        'arroz|kg|todos');
  });
  testWidgets(
      'diagnóstico sem resultado oferece revisão e suporta texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var revisou = false;
    final d = diagnostico.analisar(
        pessoas: 40,
        cardapio: [item('Arroz 🍚'), item('Macarrão 🍝')],
        regras: []);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
                body: SingleChildScrollView(
                    child: CalculadoraDiagnosticoCard(
              diagnostico: d,
              primary: Colors.green.shade800,
              cardapioDisponivel: true,
              revisando: false,
              carregando: false,
              semCatalogo: true,
              erroCatalogo: '',
              regrasRejeitadas: const [],
              financeiroIncompleto: false,
              onInformarPessoas: () {},
              onRevisar: () => revisou = true,
              onConfigurar: () {},
              onAdicionar: () {},
            ))))));
    expect(find.text('0 de 2 itens com consumo configurado.'), findsOneWidget);
    await tester.ensureVisible(find.text('Usar meu cardápio no cálculo'));
    await tester.tap(find.text('Usar meu cardápio no cálculo'));
    expect(revisou, isTrue);
    expect(tester.takeException(), isNull);
  });
}
