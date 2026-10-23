import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/rendimento_referencia_service.dart';

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_composicao_test.dart' show AuthQA;
import 'calculadora_proposta_refeicao_test.dart' show item, preparar;
import 'catalogo_contextual_test.dart'
    show contextoQA, itemQA, referenciaQA, respostasQA;
import 'planejador_hibrido_test.dart' show contexto, gerar;
import 'plano_evento_test.dart' show calculo;
import 'plano_execucao_test.dart'
    show contextoExec, fichaExec, itemExec, proporExec, regraExec;

/// Matriz do grupo 6 da homologação 12. Domínio real; sem Firebase e sem IA.
void main() {
  final respostasPlanejador = {
    'objetivo': 'comparar_quantidades',
    'servico': 'lanche',
    'formato': 'buffet',
    ...respostasQA(referenciaQA())
  };

  ItemEstimativaFinanceira regraConfirmada(ReferenciaContextual ref) {
    final gerada = const PropostaRefeicaoService()
        .gerar(
            itens: [itemQA],
            regras: [],
            catalogo: CatalogoContextual([ref]),
            contexto: contextoQA,
            respostas: respostasQA(ref))
        .regras
        .single;
    return gerada.copyWith(premissas: {
      ...gerada.premissas,
      'revisada_pelo_organizador': true,
    });
  }

  test('receita própria revisada não é substituída por referência nova', () {
    final antiga = referenciaQA();
    final nova = referenciaQA(versao: 2, porcao: .22);
    final propria = regraConfirmada(antiga).copyWith(premissas: {
      ...regraConfirmada(antiga).premissas,
      'origem': 'referencia_organizador',
      'receita': 'Arroz da casa',
      'receita_referencia': 'Arroz da casa',
      'consumo_min': .08,
      'consumo_max': .12,
    });
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [propria],
        catalogo: CatalogoContextual([nova]),
        contexto: contextoQA,
        respostas: respostasQA(nova));
    expect(p.regras.single.premissas['receita'], 'Arroz da casa');
    expect(p.regras.single.premissas['origem'], 'referencia_organizador');
    expect(p.regras.single.quantidadePorConvidadoEquivalente,
        propria.quantidadePorConvidadoEquivalente);
    expect(p.regras.single.premissas['referencia_versao'], isNot(2));
  });

  test('ingredientes vazios na ficha não inventam compra de grão ou água', () {
    final ficha = fichaExec()..['ingredientes'] = <Map<String, dynamic>>[];
    final p = proporExec(contextoExec(menus: ['almoco']), ficha: ficha);
    expect(p.compras.where((c) => c['nome'] == 'Grão para a receita'), isEmpty);
    expect(p.compras.where((c) => c['nome'] == 'Água'), isEmpty);
    expect(p.compras.any((c) => (c['quantidade'] as num) < 0), isFalse);
  });

  test('ficha incompatível fica pendente sem inventar ingrediente nem preço',
      () {
    final ficha = fichaExec()..['estado'] = 'pronto';
    final p = proporExec(contextoExec(menus: ['almoco']), ficha: ficha);
    expect(p.compras, isEmpty);
    expect(p.pendencias.join(), contains('ficha'));
    expect(regraExec('almoco', ficha: ficha).valorUnitarioMedio, 0);
  });

  test('compra pronta não vira crua; crua exige rendimento medido', () {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthQA());
    addTearDown(Get.reset);
    final c = preparar([item('Churrasco', id: 'carne')]);
    addTearDown(c.onClose);
    final pronta = c.proporRefeicao(respostas: {'compra_carne': 'pronto'});
    expect(pronta.regras.single.premissas['estado_compra'], isNot('cru'));
    expect(c.resultadosDaProposta(pronta).single.quantidade, 3.25);
    final crua = c.proporRefeicao(
        respostas: {'compra_carne': 'preparar', 'rendimento_carne': '0,5'});
    expect(crua.regras.single.premissas['estado_compra'], 'cru');
    expect(crua.regras.single.premissas['rendimento_medido'], true);
    expect(c.resultadosDaProposta(crua).single.quantidade, 6.5);
    final semMedir = c.proporRefeicao(respostas: {'compra_carne': 'preparar'});
    expect(semMedir.pendencias, isNotEmpty);
    expect(semMedir.regras.single.premissas['proposta_apenas_servir'], true);
  });

  test('peso pronto publicado não vira compra crua sem rendimento', () {
    final ref = referenciaQA(extra: {'estado_compra': 'cru'});
    expect(
        const PropostaRefeicaoService().gerar(
            itens: [itemQA],
            regras: [],
            catalogo: CatalogoContextual([ref]),
            contexto: contextoQA,
            respostas: respostasQA(ref, obtencao: 'preparar')).regras,
        isEmpty);
  });

  test('embalagem arredonda a necessidade sem inventar preço', () {
    final regra =
        regraExec('almoco').copyWith(valorUnitarioMedio: 0, premissas: {
      ...regraExec('almoco').premissas,
      'embalagem': 2,
      'estado': 'pronto',
      'estado_compra': 'pronto',
      'rendimento': 1,
    });
    final out = const CalculadoraFestaService().calcularItens(
        calculo: calculo(pessoas: 20), itensBase: [regra]).single;
    final compra = const ListaComprasCalculadoraService().analisar(
        resultado: out,
        regra: regra,
        cardapio: [itemExec('almoco', informado: false)],
        compromissos: [],
        convidados:
            const ConvidadosEquivalentes(adultos: 20, criancas: 0, bebes: 0),
        perfil: PerfilFesta.padrao(),
        duracao: 4,
        margem: 0);
    expect(regra.valorUnitarioMedio, 0);
    expect(out.quantidadeNecessaria, greaterThan(0));
    expect(compra.orientacao.toLowerCase(),
        anyOf(contains('embalagem'), contains('compra'), contains('confer')));
  });

  test('unidade e embalagem da regra própria seguem no cálculo e na lista', () {
    final regra =
        regraExec('almoco').copyWith(valorUnitarioMedio: 0, premissas: {
      ...regraExec('almoco').premissas,
      'estado': 'cru',
      'estado_compra': 'cru',
      'embalagem': 2,
      'unidade_consumo': 'kg',
      'rendimento': 1,
    });
    final out = const CalculadoraFestaService()
        .calcularItens(calculo: calculo(pessoas: 20), itensBase: [regra]).single;
    expect(regra.unidade, UnidadeEstimativa.quilo);
    expect(regra.tamanhoEmbalagem, 2);
    expect(out.unidade.toLowerCase(), anyOf('kg', 'quilo'));
    final compra = const ListaComprasCalculadoraService().analisar(
        resultado: out,
        regra: regra,
        cardapio: [itemExec('almoco', informado: false)],
        compromissos: [],
        convidados:
            const ConvidadosEquivalentes(adultos: 20, criancas: 0, bebes: 0),
        perfil: PerfilFesta.padrao(),
        duracao: 4,
        margem: 0);
    expect(compra.preparo, greaterThan(0));
    expect(out.quantidadeNecessaria, greaterThan(0));
  });

  test('referência nova publicada não reescreve regra confirmada', () {
    final a = referenciaQA(), b = referenciaQA(versao: 2, porcao: .2);
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [regraConfirmada(a)],
        catalogo: CatalogoContextual([b]),
        contexto: contextoQA,
        respostas: respostasQA(b));
    expect(p.regras.single.quantidadePorConvidadoEquivalente, .1);
    expect(p.regras.single.premissas['referencia_versao'], 1);
    expect(b.versao, 2);
  });

  test('rendimento publicado compatível converte compra crua sem nome fechado',
      () {
    final porcao = referenciaQA(extra: {'estado_compra': 'cru'});
    final rendimento = referenciaQA(porcao: .7, extra: {
      'id': 'rendimento_novo',
      'tipo': 'rendimento',
      'estado_compra': 'cru'
    });
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [],
        catalogo: CatalogoContextual([porcao, rendimento]),
        contexto: contextoQA,
        respostas: {
          ...respostasQA(porcao, obtencao: 'preparar'),
          'rendimento_item': rendimento.chave
        });
    expect(p.regras.single.rendimento, .7);
    expect(const RendimentoReferenciaService().valida(p.regras.single), true);
    expect(p.regras.single.premissas['rendimento_medido'], false);
    expect(p.regras.single.valorUnitarioMedio, 0);
  });

  test('restrição sem composição conferida permanece pendente', () {
    final r = gerar(
        respostas: respostasPlanejador,
        ctx: contexto(grupos: [
          {
            'restricoes': ['sem_leite'],
            'adultos': 2
          }
        ]));
    expect(r.pendencias.join(' '), contains('não comprova adequação'));
  });

  test('catálogo indisponível não inventa porção, preço nem adequação', () {
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [],
        catalogo: CatalogoContextual.indisponivel,
        contexto: contextoQA);
    expect(p.regras, isEmpty);
    expect(p.pendencias.join(' '), contains('indisponíveis'));
  });
}
