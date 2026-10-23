import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/domain/services/consumo_observado_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/contexto_servico_planejador.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/services/planejador_hibrido_service.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'catalogo_contextual_test.dart' show referenciaQA, itemQA, respostasQA;
import 'plano_evento_test.dart' show calculo;

ContextoServicoPlanejador contexto(
        {List<ItemEstimativaFinanceira> regras = const [],
        int pessoas = 20,
        List<Map<String, dynamic>> grupos = const []}) =>
    ContextoServicoPlanejador(
        evento: 'evento',
        cardapio: 'menu',
        publico:
            ConvidadosEquivalentes(adultos: pessoas, criancas: 0, bebes: 0),
        origemPublico: 'previstos',
        itens: [itemQA.copyWith(unidade: 'kg')],
        regras: regras,
        grupos: grupos);
ResultadoPlanejadorHibrido gerar(
        {Map<String, String> respostas = const {},
        List<ReferenciaContextual>? refs,
        ContextoServicoPlanejador? ctx}) =>
    const PlanejadorHibridoService().gerar(
        contexto: ctx ?? contexto(),
        catalogo: CatalogoContextual(refs ?? [referenciaQA()]),
        respostas: respostas,
        calcular: (p) => const CalculadoraFestaService()
            .calcularItens(calculo: calculo(), itensBase: p.regras));
void main() {
  final respostas = {
    'objetivo': 'comparar_quantidades',
    'servico': 'lanche',
    'formato': 'buffet',
    ...respostasQA(referenciaQA())
  };
  test(
      'perguntas que desbloqueiam cálculo não somem quando ainda não há quantidades',
      () {
    final r = gerar();
    expect(r.principal.regras, isEmpty);
    expect(r.perguntas.where((q) => q.decisiva).map((q) => q.pergunta.id),
        containsAll(['objetivo', 'servico', 'formato', 'obtencao_item']));
    expect(r.recomendacao, isNull);
    expect(r.alternativa, isNull);
  });
  test('placeholder vazio não é uma resposta confirmada', () {
    final r = gerar(respostas: {'objetivo': '', 'servico': '', 'formato': ''});
    expect(r.perguntas.where((q) => q.respondida), isEmpty);
  });
  test('quantidade válida continua com custo pendente, sem economia inventada',
      () {
    final r = gerar(respostas: respostas);
    expect(r.principal.regras.single.quantidadePorConvidadoEquivalente, .1);
    expect(r.financeiroCompleto, isFalse);
    expect(r.pendencias.join(' '), contains('Custo pendente'));
  });
  test('alternativa depende de objetivo e diferença compatível', () {
    final outra = referenciaQA(extra: {'id': 'segunda_fonte'}, porcao: .2);
    final r = gerar(respostas: respostas, refs: [referenciaQA(), outra]);
    expect(r.alternativa, isNotNull);
    expect(r.alternativa!.regras.single.quantidadePorConvidadoEquivalente, .2);
    expect(
        gerar(
            respostas: {...respostas, 'objetivo': 'manter_receitas'},
            refs: [referenciaQA(), outra]).alternativa,
        isNull);
    expect(
        gerar(respostas: respostas, refs: [
          referenciaQA(),
          referenciaQA(extra: {'id': 'igual'})
        ]).alternativa,
        isNull);
  });
  test('receita revisada prevalece sobre nova referência e alternativa', () {
    final propria = gerar(respostas: respostas)
        .principal
        .regras
        .single
        .copyWith(quantidadePorConvidadoEquivalente: .37, premissas: {
      'id_evento': 'evento',
      'id_cardapio': 'menu',
      'id_item_cardapio': 'item',
      'receita': 'Receita da família',
      'revisada_pelo_organizador': true
    });
    final r = gerar(
        respostas: respostas,
        ctx: contexto(regras: [propria]),
        refs: [referenciaQA(porcao: .8)]);
    expect(
        r.principal.regras.single.toPlanejamento(), propria.toPlanejamento());
    expect(r.alternativa, isNull);
  });
  test('infraestrutura ausente pergunta; negativa bloqueia; positiva libera',
      () {
    final ref = referenciaQA(extra: {
      'infraestrutura': ['refrigeracao']
    });
    expect(
        gerar(respostas: respostas, refs: [ref])
            .perguntas
            .where((q) => q.decisiva)
            .map((q) => q.pergunta.id),
        contains('infra_refrigeracao'));
    expect(
        gerar(
            respostas: {...respostas, 'infra_refrigeracao': 'nao'},
            refs: [ref]).principal.regras,
        isEmpty);
    expect(
        gerar(
            respostas: {...respostas, 'infra_refrigeracao': 'sim'},
            refs: [ref]).principal.regras,
        hasLength(1));
  });
  test('respostas reaproveitadas só no mesmo contexto material', () {
    final c = contexto(),
        d = {
          'assinatura_material': contexto().assinatura,
          'respostas': respostas
        };
    expect(c.reutilizar(d), respostas);
    expect(contexto(pessoas: 21).reutilizar(d), isEmpty);
  });
  test('restrição sem composição permanece pendente', () {
    final r = gerar(
        respostas: respostas,
        ctx: contexto(grupos: [
          {
            'restricoes': ['sem_leite'],
            'adultos': 2
          }
        ]));
    expect(r.pendencias.join(' '), contains('não comprova adequação'));
  });
  test('catálogo indisponível mantém manual e não inventa porção', () {
    final r = gerar(respostas: respostas, refs: []);
    expect(r.principal.regras, isEmpty);
    expect(r.pendencias.join(' '), contains('livremente'));
  });
  test('medição recuperada é oferecida para adoção e não herda preço antigo',
      () {
    final base = ItemEstimativaFinanceira(
        id: 'historica',
        nome: 'Alimento sintético',
        categoria: 'comida',
        tipoItem: 'comida',
        publicoAlvo: 'todos',
        unidade: UnidadeEstimativa.quilo,
        quantidadePorConvidadoEquivalente: .2,
        valorUnitarioMedio: 77,
        premissas: {
          'receita': 'Receita QA',
          'estado': 'pronto',
          'papel_na_refeicao': 'outro',
          'peso_crianca': 1.0,
          'peso_bebe': 1.0
        });
    final registros = [
      for (var i = 0; i < 3; i++)
        RegistroConsumoCalculadora(
            idEvento: 'outro$i',
            contexto: 'comparavel',
            dataRegistro: DateTime.now(),
            dataConsumo: DateTime.now(),
            regra: base,
            adultos: 20,
            criancas: 0,
            bebes: 0,
            duracaoHoras: 4,
            disponibilizado: 2,
            sobra: 0,
            desperdicio: .1,
            faltou: false)
    ];
    final resumo = const ConsumoObservadoService().resumir(
        registros: registros,
        contexto: 'comparavel',
        eventoAtual: 'evento',
        pessoas: contexto().publico);
    ResultadoPlanejadorHibrido proposta(Map<String, String> r) =>
        const PlanejadorHibridoService().gerar(
            contexto: contexto(),
            catalogo: CatalogoContextual([referenciaQA()]),
            respostas: r,
            basesObservadas: {'item': base},
            observados: {'item': resumo},
            calcular: (p) => const CalculadoraFestaService()
                .calcularItens(calculo: calculo(), itensBase: p.regras));
    final antes = proposta(respostas);
    expect(antes.perguntas.where((q) => q.decisiva).map((q) => q.pergunta.id),
        contains('origem_item'));
    final depois = proposta({...respostas, 'origem_item': 'observado'}),
        r = depois.principal.regras.single;
    expect(r.quantidadePorConvidadoEquivalente, .1);
    expect(r.valorUnitarioMedio, 0);
    expect(r.premissas['origem'], 'consumo_observado');
    expect(r.premissas['contexto_consumo'], 'comparavel');
    expect(depois.principal.preservados, isEmpty);
  });
  test(
      'quantidade final confirmada, inclusive zero, prevalece sobre nova referência',
      () {
    for (final quantidade in [0.0, 8.0]) {
      final original = contexto(),
          c = ContextoServicoPlanejador(
              evento: original.evento,
              cardapio: original.cardapio,
              publico: original.publico,
              origemPublico: original.origemPublico,
              itens: [
                itemQA.copyWith(
                    confirmado: true,
                    quantidadeFinal: quantidade,
                    unidade: 'kg')
              ],
              regras: []);
      final p = gerar(ctx: c, respostas: respostas);
      expect(p.principal.regras, isEmpty);
      expect(p.alternativa, isNull);
      expect(p.origens['item'], contains('$quantidade kg'));
    }
  });
  test(
      'contrato persistido recusa objetivo, assinatura e infraestrutura inválidos',
      () {
    final d = {
      'versao': 1,
      'objetivo': 'manter_receitas',
      'infraestrutura': <String, dynamic>{},
      'respostas': <String, String>{},
      'assinatura_material': contexto().assinatura
    };
    validarDecisaoServicoPlanejador(d);
    for (final altera in [
      {'objetivo': 'economia garantida'},
      {'assinatura_material': 'x' * 64},
      {
        'infraestrutura': {'cozinha': 'sim'}
      }
    ]) {
      expect(() => validarDecisaoServicoPlanejador({...d, ...altera}),
          throwsArgumentError);
    }
    const OperacaoCalculadoraService().validarDocumento({
      'versao': 1,
      'planejador': {'menu': d}
    });
  });
}
