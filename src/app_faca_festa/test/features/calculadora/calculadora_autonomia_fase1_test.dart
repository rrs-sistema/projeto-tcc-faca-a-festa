import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';
import 'package:app_faca_festa/domain/services/capacidade_alimentos_service.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/prioridade_perguntas_service.dart';
import 'package:app_faca_festa/domain/services/rendimento_referencia_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'plano_evento_test.dart' show calculo, menu;

const dog = CardapioItem(
    idItem: 'dog',
    idEvento: 'evento',
    idCardapio: 'almoco',
    nome: 'Cachorro-quente');
const carne = CardapioItem(
    idItem: 'carne',
    idEvento: 'evento',
    idCardapio: 'almoco',
    nome: 'Churrasco');
const regraDog = ItemEstimativaFinanceira(
    id: 'menu_almoco_dog',
    categoria: 'comida',
    nome: 'Cachorro-quente',
    tipoItem: 'comida',
    publicoAlvo: 'todos',
    unidade: UnidadeEstimativa.unidade,
    quantidadePorConvidadoEquivalente: 2,
    valorUnitarioMedio: 5,
    premissas: {
      'id_cardapio': 'almoco',
      'id_item_cardapio': 'dog',
      'estado': 'pronto',
      'estado_compra': 'pronto',
      'papel_na_refeicao': 'principal',
      'revisada_pelo_organizador': true
    });

void main() {
  const propostas = PropostaRefeicaoService();
  const capacidade = CapacidadeAlimentosService();
  final base = calculo().copyWith(margemPersonalizada: 0);
  PlanoInicialEvento plano(int n,
          {ItemEstimativaFinanceira r = regraDog, bool desconhecido = false}) =>
      const PlanoEventoService()
          .gerar(calculo: base.copyWith(totalAdultos: n), cardapios: [
        menu
      ], itensPorCardapio: {
        'almoco': [
          dog,
          if (desconhecido) dog.copyWith(idItem: 'x', nome: 'Especial')
        ]
      }, regras: [
        r
      ]);

  test(
      'converte referência de carne sem osso e distingue rendimento estimado de medido',
      () {
    final p = propostas.gerar(itens: [
      carne
    ], regras: [], respostas: {
      'compra_carne': 'preparar',
      'preparo_carne': 'senar_sem_osso_v1'
    });
    final r = p.regras.single;
    expect(r.rendimento, .7);
    expect(r.premissas['rendimento_estimado'], true);
    expect(r.premissas['rendimento_medido'], false);
    expect(const RendimentoReferenciaService().valida(r), true);
    final resultado = const CalculadoraFestaService()
        .calcularItens(calculo: base, itensBase: p.regras)
        .single;
    expect(resultado.quantidade, closeTo(9.29, .001));
    final item = carne.copyWith(
        unidade: 'kg',
        disponibilidade: const DisponibilidadeCardapio(
            comprado: 0,
            estoque: 0,
            unidade: 'kg',
            estado: 'cru',
            nome: 'Churrasco',
            publico: 'todos'));
    final compra = const ListaComprasCalculadoraService().analisar(
        resultado: resultado,
        regra: r,
        cardapio: [item],
        compromissos: [],
        convidados: base.convidadosEquivalentes,
        perfil: base.perfilFesta,
        duracao: 4,
        margem: 0);
    expect(compra.situacao, SituacaoCompra.comprar);
    expect(compra.base, contains('estimado'));
    final alterada = r.copyWith(premissas: {...r.premissas, 'rendimento': .9});
    expect(const RendimentoReferenciaService().valida(alterada), false);
    final invalida = const ListaComprasCalculadoraService().analisar(
        resultado: resultado,
        regra: alterada,
        cardapio: [item],
        compromissos: [],
        convidados: base.convidadosEquivalentes,
        perfil: base.perfilFesta,
        duracao: 4,
        margem: 0);
    expect(invalida.situacao, SituacaoCompra.revisarPorcao);
  });

  test(
      'mistura e frutas não recebem rendimento genérico; medição explícita continua prioritária',
      () {
    final mistura = propostas.gerar(
        itens: [carne], regras: [], respostas: {'compra_carne': 'preparar'});
    expect(mistura.regras.single.premissas['proposta_apenas_servir'], true);
    expect(mistura.pendencias, isNotEmpty);
    final medida = propostas.gerar(itens: [
      carne
    ], regras: [], respostas: {
      'compra_carne': 'preparar',
      'preparo_carne': 'medido',
      'rendimento_carne': '0,5'
    });
    expect(medida.regras.single.rendimento, .5);
    expect(medida.regras.single.premissas['rendimento_medido'], true);
    expect(medida.regras.single.premissas['rendimento_referencia'], isNull);
    final fruta = propostas.gerar(itens: [
      carne.copyWith(nome: 'Frutas')
    ], regras: [], respostas: {
      'compra_carne': 'preparar',
      'preparo_carne': 'senar_sem_osso_v1'
    });
    expect(fruta.regras.single.premissas['proposta_apenas_servir'], true);
  });

  test('capacidade recalcula custos e embalagens sem cortar porções para caber',
      () {
    final normal = capacidade.simular(
        verba: 100, gerar: (n) => plano(n), consultaCompleta: true);
    expect(normal.pessoas, 10);
    expect(normal.custo, 100);
    final embalado =
        regraDog.copyWith(premissas: {...regraDog.premissas, 'embalagem': 12});
    final resultado = capacidade.simular(
        verba: 65, gerar: (n) => plano(n, r: embalado), consultaCompleta: true);
    expect(resultado.pessoas, 6);
    expect(resultado.custo, 60);
    expect(regraDog.quantidadePorConvidadoEquivalente, 2);
  });

  test('preços e referências ausentes não viram capacidade zero ou economia',
      () {
    final semPreco = capacidade.simular(
        verba: 100,
        gerar: (n) => plano(n, r: regraDog.copyWith(valorUnitarioMedio: 0)),
        consultaCompleta: true);
    expect(semPreco.pessoas, isNull);
    expect(semPreco.custo, isNull);
    expect(semPreco.motivo, contains('preço'));
    final semReferencia = capacidade.simular(
        verba: 100,
        gerar: (n) => plano(n, desconhecido: true),
        consultaCompleta: true);
    expect(semReferencia.pessoas, isNull);
    expect(
        capacidade
            .simular(verba: 1, gerar: (n) => plano(n), consultaCompleta: true)
            .pessoas,
        0);
    expect(
        () => capacidade.simular(
            verba: double.nan, gerar: (n) => plano(n), consultaCompleta: true),
        throwsArgumentError);
  });

  test('item explicitamente excluído não exige preço nem entra na capacidade',
      () {
    final excluido = regraDog.copyWith(
        id: 'menu_almoco_x',
        nome: 'Extra',
        selecionado: false,
        valorUnitarioMedio: 0,
        premissas: {...regraDog.premissas, 'id_item_cardapio': 'x'});
    final resultado = capacidade.simular(
        verba: 100,
        consultaCompleta: true,
        gerar: (n) => const PlanoEventoService()
                .gerar(calculo: base.copyWith(totalAdultos: n), cardapios: [
              menu
            ], itensPorCardapio: {
              'almoco': [dog, dog.copyWith(idItem: 'x', nome: 'Extra')]
            }, regras: [
              regraDog,
              excluido
            ]));
    expect(resultado.pessoas, 10);
    expect(resultado.custo, 100);
  });

  test('consulta incompleta e públicos específicos impedem extrapolação', () {
    expect(
        capacidade
            .simular(
                verba: 100, gerar: (n) => plano(n), consultaCompleta: false)
            .pessoas,
        isNull);
    expect(
        capacidade
            .simular(
                verba: 100,
                gerar: (n) => plano(n),
                consultaCompleta: true,
                publicoEspecifico: true)
            .pessoas,
        isNull);
    final teto = capacidade.simular(
        verba: 1000000,
        gerar: (n) => plano(n),
        consultaCompleta: true,
        teto: 200);
    expect(teto.pessoas, 200);
    expect(teto.limiteBusca, true);
    final fixo = capacidade.simular(
        verba: 100,
        consultaCompleta: true,
        gerar: (n) => const PlanoEventoService()
                .gerar(calculo: base.copyWith(totalAdultos: n), cardapios: [
              menu
            ], itensPorCardapio: {
              'almoco': [dog]
            }, regras: [
              regraDog
            ], operacao: {
              'refeicoes': {
                'almoco': {
                  'publico': {'adultos': 5, 'criancas': 0, 'bebes': 0}
                }
              }
            }));
    expect(fixo.pessoas, isNull);
  });

  test(
      'perguntas usam impacto calculado e escolhas salvas não são exigidas novamente',
      () {
    PropostaRefeicao gerar(Map<String, String> r) =>
        propostas.gerar(itens: [dog], regras: [], respostas: r);
    final p = gerar({});
    final prioridades = const PrioridadePerguntasService().ordenar(
        proposta: p,
        respostasExplicitas: {'dog_uso_dog': 'principal'},
        gerar: gerar,
        calcular: (p) => const CalculadoraFestaService()
            .calcularItens(calculo: base, itensBase: p.regras));
    expect(prioridades.first.pergunta.id, 'dog_tamanho_dog');
    expect(prioridades.first.decisiva, true);
    expect(prioridades.first.variacao, greaterThan(0));
    expect(prioridades.last.respondida, true);
    final mini = gerar({'dog_tamanho_dog': 'mini'});
    final invalidas = const PrioridadePerguntasService().ordenar(
        proposta: mini,
        respostasExplicitas: {'dog_mini_dog': 'NaN'},
        gerar: gerar,
        calcular: (p) => const CalculadoraFestaService()
            .calcularItens(calculo: base, itensBase: p.regras));
    expect(
        invalidas.firstWhere((p) => p.pergunta.id == 'dog_mini_dog').decisiva,
        true);
  });

  test('mudança pequena que exige outra embalagem continua material', () {
    PropostaRefeicao gerar(Map<String, String> respostas) {
      final r = regraDog.copyWith(
          unidade: UnidadeEstimativa.quilo,
          quantidadePorConvidadoEquivalente:
              respostas['porcao'] == 'mais' ? .5005 : .5,
          premissas: {...regraDog.premissas, 'embalagem': 10});
      return PropostaRefeicao(
          [r],
          [
            const PerguntaProposta(
                'porcao', 'Porção', {'base': 'Base', 'mais': 'Mais'}, 'base')
          ],
          [],
          {},
          respostas,
          {});
    }

    final p = gerar({});
    final q = const PrioridadePerguntasService()
        .ordenar(
            proposta: p,
            respostasExplicitas: {},
            gerar: gerar,
            calcular: (p) => const CalculadoraFestaService().calcularItens(
                calculo: base.copyWith(totalAdultos: 1000),
                itensBase: p.regras))
        .single;
    expect(q.variacao, lessThan(.05));
    expect(q.mudaCompra, true);
    expect(q.decisiva, true);
    expect(q.variacaoCusto, greaterThan(0));
  });
}
