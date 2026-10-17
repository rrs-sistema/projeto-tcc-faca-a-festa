import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/services/resumo_compras_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/analise_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/cenario_alternativa_service.dart';
import 'package:app_faca_festa/domain/services/medicao_uso_calculadora.dart';
import 'package:app_faca_festa/domain/services/referencia_porcao_service.dart';
import 'calculadora_lista_compras_test.dart' as fixture;
import 'calculadora_composicao_test.dart' show regraQA;

ItemListaCompras compra(
        {double preco = 10,
        double comprado = 0,
        double? falta = 3,
        SituacaoCompra situacao = SituacaoCompra.comprar}) =>
    ItemListaCompras(
        resultado: fixture.resultado.copyWith(valorUnitarioMedio: preco),
        regra: fixture.regra,
        cardapio: fixture.menu.copyWith(
            disponibilidade:
                fixture.disponivel(comprado: comprado, estoque: 0)),
        situacao: situacao,
        orientacao: '',
        base: '',
        falta: falta);
CalculadoraFesta calculo() => CalculadoraFesta(
    idCalculo: 'c',
    idEvento: 'e',
    tipoEvento: 'Aniversário',
    baseCalculo: BaseCalculoFesta.manual,
    totalAdultos: 10,
    totalCriancas: 0,
    totalBebes: 0,
    duracaoHoras: 4,
    dataCalculo: DateTime(2026),
    dataAtualizacao: DateTime(2026),
    perfilFesta: PerfilFesta.padrao());

void main() {
  const resumo = ResumoComprasService();
  const refeicao = AnaliseRefeicaoService();
  const cenarios = CenarioAlternativaService();
  final arroz = regraQA('Arroz',
          consumo: .1,
          premissas: {'papel_na_refeicao': 'acompanhamento', 'estado': 'cru'})
      .copyWith(valorUnitarioMedio: 20);
  final batata = regraQA('Batata',
      consumo: .05,
      premissas: {'papel_na_refeicao': 'acompanhamento', 'estado': 'cru'});

  test(
      'consolida compras, orçamento e pagamentos sem confundir fluxo de caixa com custo',
      () {
    final r = resumo.calcular(itens: [
      compra()
    ], compromissos: [
      {
        'valor': 100,
        'pago': 40,
        'identidade': 'espaco||todos',
        'cobertura_identificavel': true
      }
    ], limite: 200);
    expect(r.custoConhecido, 30);
    expect(r.pagamentosPendentes, 60);
    expect(r.saldoAposCompras, 70);
  });
  test(
      'conferência explícita distingue despesa realizada de compra futura e invalida quando o valor muda',
      () {
    const mapper = CompromissoPlanejamentoService();
    final data = {
      'nome': 'Arroz',
      'unidade': 'kg',
      'custo_real': 100,
      'calculadora_conferencia_financeira': {
        'modo': 'realizado',
        'valor': 100,
        'identidade': 'arroz|kg|todos',
        'coberturas': <String>[]
      }
    };
    final gasto = mapper.mapear('g', data)!;
    final r = resumo.calcular(
        itens: [compra(comprado: 2)], compromissos: [gasto], limite: 200);
    expect(r.sobreposicao, isFalse);
    expect(r.saldoAposCompras, 70);
    final alterado = mapper.mapear('g', {...data, 'custo_real': 120})!;
    expect(alterado['conferencia_financeira'], 'revisar');
    expect(
        resumo.calcular(
            itens: [compra()],
            compromissos: [alterado],
            limite: 200).saldoAposCompras,
        isNull);
  });
  test(
      'espaço sem itens do cardápio só deixa de ser ambíguo depois de declaração explícita',
      () {
    const mapper = CompromissoPlanejamentoService();
    final gasto = mapper.mapear('g', {
      'nome': 'Espaço',
      'custo_estimado': 100,
      'calculadora_conferencia_financeira': {
        'modo': 'sem_itens',
        'valor': 100,
        'identidade': 'espaco||todos',
        'coberturas': <String>[]
      }
    })!;
    expect(gasto['cobertura_identificavel'], isTrue);
    expect(
        resumo.calcular(
            itens: [compra()],
            compromissos: [gasto],
            limite: 200).saldoAposCompras,
        70);
  });
  test('preço ou quantidade desconhecidos não são custo zero definitivo', () {
    final r = resumo.calcular(itens: [
      compra(preco: 0),
      compra(falta: null, situacao: SituacaoCompra.revisarPorcao)
    ], compromissos: [], limite: 100);
    expect(r.precosPendentes, 1);
    expect(r.quantidadesPendentes, 1);
    expect(r.completo, isFalse);
    expect(r.saldoAposCompras, isNull);
  });
  test('orçamento que pode cobrir a compra restante bloqueia soma duplicada',
      () {
    final r = resumo.calcular(itens: [
      compra()
    ], compromissos: [
      {'valor': 100, 'identidade': 'arroz|kg|todos'}
    ], limite: 200);
    expect(r.sobreposicao, isTrue);
    expect(r.saldoAposCompras, isNull);
  });
  test('compra física sem registro de custo não vira saldo financeiro fictício',
      () {
    final r = resumo
        .calcular(itens: [compra(comprado: 2)], compromissos: [], limite: 200);
    expect(r.comprasSemRegistro, 1);
    expect(r.saldoAposCompras, isNull);
    expect(r.custoConhecido, 30);
  });
  test(
      'consulta incompleta e item sem regra impedem afirmar que cabe no limite',
      () {
    final r = resumo.calcular(
        itens: [compra()],
        compromissos: [],
        semRegra: 1,
        consultaCompleta: false,
        limite: 200);
    expect(r.saldoAposCompras, isNull);
    expect(r.quantidadesPendentes, 1);
  });
  test(
      'cobertura contratada e estoque completo não exigem preço para comprar zero',
      () {
    final r = resumo.calcular(
        itens: [compra(preco: 0, falta: 0, situacao: SituacaoCompra.incluido)],
        compromissos: [],
        limite: 100);
    expect(r.precosPendentes, 0);
    expect(r.saldoAposCompras, 100);
  });
  test(
      'refeição completa aponta falta de principal sem impor isso ao coffee break',
      () {
    expect(
        refeicao
            .analisar([arroz], refeicao: 'Almoço', adultos: 10)
            .pendencias
            .join(' '),
        contains('prato principal'));
    expect(
        refeicao
            .analisar([arroz], refeicao: 'Coffee break', adultos: 10)
            .pendencias
            .join(' '),
        isNot(contains('prato principal')));
  });
  test('alternativas não declaradas geram orientação sem modificar porções',
      () {
    final analise = refeicao.analisar([arroz, batata], refeicao: 'Almoço');
    expect(analise.pendencias.join(' '),
        contains('Nenhuma divisão foi presumida'));
    expect(arroz.fatorComposicao, 1);
  });
  test('público infantil sem alimento participante é uma pendência explícita',
      () {
    final r = arroz.copyWith(publicoAlvo: 'adultos');
    expect(
        refeicao
            .analisar([r], refeicao: 'Jantar', adultos: 10, criancas: 4)
            .pendencias
            .join(' '),
        contains('criancas'));
  });
  test('substituição usa a nova porção e preço sem alterar o original', () {
    final proposta = cenarios.simular(
        calculo: calculo(),
        regras: [arroz],
        original: arroz,
        alternativa: batata);
    expect(proposta.resultados.single.nome, 'Batata');
    expect(proposta.resultados.single.quantidade, .55);
    expect(proposta.variacao, closeTo(16.5, .001));
    expect(arroz.nome, 'Arroz');
    expect(arroz.quantidadePorConvidadoEquivalente, .1);
  });
  test('troca sem preço, estado ou papel compatível é recusada', () {
    for (final alternativa in [
      batata.copyWith(valorUnitarioMedio: 0),
      batata.copyWith(
          premissas: {'estado': 'cru', 'papel_na_refeicao': 'principal'}),
      batata.copyWith(premissas: {'papel_na_refeicao': 'acompanhamento'})
    ]) {
      expect(
          () => cenarios.simular(
              calculo: calculo(),
              regras: [arroz],
              original: arroz,
              alternativa: alternativa),
          throwsArgumentError);
    }
  });
  test('outro item sem preço torna a economia total desconhecida', () {
    final proposta = cenarios.simular(
        calculo: calculo(),
        regras: [arroz, regraQA('Salada').copyWith(valorUnitarioMedio: 0)],
        original: arroz,
        alternativa: batata);
    expect(proposta.variacao, isNull);
  });
  test('menos variedade preserva outra alternativa e recompõe participação',
      () {
    final a = arroz.copyWith(premissas: {
      ...arroz.premissas,
      'grupo': 'acomp',
      'dividir_grupo': true
    });
    final b = batata.copyWith(premissas: {
      ...batata.premissas,
      'grupo': 'acomp',
      'dividir_grupo': true
    });
    final proposta =
        cenarios.simularRetirada(calculo: calculo(), regras: [a, b], id: a.id);
    expect(proposta.single.nome, 'Batata');
    expect(proposta.single.quantidade, .55);
    expect(
        () =>
            cenarios.simularRetirada(calculo: calculo(), regras: [a], id: a.id),
        throwsArgumentError);
  });
  test('não retira alimento independente nem troca papéis entre grupos', () {
    expect(
        () => cenarios.simularRetirada(
            calculo: calculo(), regras: [arroz, batata], id: arroz.id),
        throwsArgumentError);
  });
  test('novas referências preservam fonte, estado e unidade específica', () {
    const s = ReferenciaPorcaoService();
    final massa = s.buscar('Penne', 'principal').single;
    expect(massa.minimo, .08);
    expect(massa.estado, 'seco');
    expect(massa.fonte, contains('barilla.com'));
    final doces = s.buscar('Docinhos', 'outro').single;
    expect(doces.minimo, 5);
    expect(doces.maximo, 5);
    expect(doces.unidade, UnidadeEstimativa.unidade);
    expect(s.buscar('Brigadeiro', 'outro'),
        isEmpty); // a referência é para o conjunto, não para cada sabor.
    final aplicado = s.aplicar(
        item: regraQA('Docinhos').copyWith(unidade: UnidadeEstimativa.unidade),
        referencia: doces,
        porcao: 5,
        estadoDestino: 'pronto');
    expect(aplicado.premissas['unidade_consumo'], 'un');
  });
  test('medição de sessão exporta contagens sem nomes ou identificadores', () {
    final m = MedicaoUsoCalculadora();
    m.abrirLista(2);
    m.listasCopiadas++;
    m.ajustes++;
    expect(m.relatorio(facilidade: 4), contains('Listas abertas: 1'));
    expect(
        m.relatorio(facilidade: 4), contains('Facilidade informada: 4 de 5'));
    expect(m.relatorio(), isNot(contains('Arroz')));
  });
}
