import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/services/composicao_refeicao_service.dart';
import 'calculadora_composicao_test.dart' show regraQA;

void main() {
  const pessoas = ConvidadosEquivalentes(adultos: 20, criancas: 6, bebes: 0);
  double compra(ItemEstimativaFinanceira r, {int horas = 4}) =>
      r.calcularQuantidadeArredondada(
          convidados: pessoas,
          perfil: PerfilFesta.padrao(),
          duracaoHoras: horas);

  test(
      '26 pessoas: conta usa os equivalentes, sem multiplicar um almoço pelas horas',
      () {
    final carne = regraQA('Churrasco', consumo: .4);
    expect(carne.publicoEquivalente(pessoas), 23.6);
    // 23,6 × 0,4 kg × 1,10 = 10,384 kg, compra arredondada 10,39 kg.
    expect(compra(carne), 10.39);
    expect(compra(carne, horas: 8), 10.39);
    expect(compra(carne, horas: 2), 10.39);
  });

  test(
      'arroz e massa não são cortados pela metade só por coexistirem no almoço',
      () {
    final itens = const ComposicaoRefeicaoService().compor([
      regraQA('Arroz',
          consumo: .05,
          premissas: {'grupo': 'acompanhamentos', 'fator_composicao': .5}),
      regraQA('Massa', consumo: .08, premissas: {'grupo': 'acompanhamentos'}),
    ]);
    expect(itens.map((i) => i.fatorComposicao), [1, 1]);
    expect(compra(itens[0]), 1.3);
    expect(compra(itens[1]), 2.08);
    // Referências integrais, não validação de suficiência para esse cardápio.
    expect(itens[0].porcaoReferenciaFormatada, '50 g');
    expect(itens[1].porcaoReferenciaFormatada, '80 g');
  });

  test('item sem adesão à divisão não reduz o que foi explicitamente dividido',
      () {
    final itens = const ComposicaoRefeicaoService().compor([
      regraQA('Arroz',
          premissas: {'grupo': 'acompanhamentos', 'dividir_grupo': true}),
      regraQA('Massa', premissas: {'grupo': 'acompanhamentos'}),
    ]);
    expect(itens.map((i) => i.fatorComposicao), [1, 1]);
  });

  test(
      'serviços e escala de duração só alteram o consumo por escolha explícita',
      () {
    final arroz = regraQA('Arroz', consumo: .05);
    expect(compra(arroz.copyWith(premissas: {'numero_servicos': 2})), 2.6);
    expect(
        compra(arroz.copyWith(premissas: {'ajustar_por_duracao': true}),
            horas: 8),
        1.63);
    final salvo = arroz.copyWith(premissas: {
      'estado': 'seco',
      'numero_servicos': 2,
      'dividir_grupo': true,
      'ajustar_por_duracao': false,
    });
    expect(
        ItemEstimativaFinanceira.fromPlanejamento(salvo.toPlanejamento())
            .premissas,
        salvo.premissas);
  });
}
