import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';

CalculadoraFesta calculo(
        {int pessoas = 20,
        double? limite = 1000,
        String tipo = 'Aniversário'}) =>
    CalculadoraFesta(
        idCalculo: 'teste',
        idEvento: 'evento',
        tipoEvento: tipo,
        baseCalculo: BaseCalculoFesta.naoRecusados,
        totalAdultos: pessoas,
        totalCriancas: 0,
        totalBebes: 0,
        duracaoHoras: 4,
        dataCalculo: DateTime(2026),
        dataAtualizacao: DateTime(2026),
        perfilFesta: PerfilFesta.fromTipo(TipoPerfilFesta.padrao),
        orcamentoDisponivel: limite);
const menu = Cardapio(
    idCardapio: 'almoco',
    idEvento: 'evento',
    titulo: 'Almoço',
    escopo: EscopoCardapio.refeicao);
const arroz = CardapioItem(
    idItem: 'arroz',
    idEvento: 'evento',
    idCardapio: 'almoco',
    nome: 'Arroz',
    tipo: TipoItemCardapio.comida);

void main() {
  const service = PlanoEventoService();
  test(
      'carregamento vazio não vira exemplo e público inválido não vira cálculo',
      () {
    final pendente = service.gerar(
        calculo: calculo(),
        cardapios: [],
        itensPorCardapio: {},
        regras: [],
        consultaCompleta: false);
    expect(pendente.destinos, isEmpty);
    expect(
        () => service.gerar(calculo: calculo(), cardapios: [
              menu
            ], itensPorCardapio: {
              'almoco': [arroz]
            }, regras: [], operacao: {
              'refeicoes': {
                'almoco': {
                  'publico': {'adultos': -1, 'criancas': 0, 'bebes': 0}
                }
              }
            }),
        throwsArgumentError);
  });

  test('grupo alimentar sem porção conferida permanece pendente na visão geral',
      () {
    final plano = service.gerar(calculo: calculo(), cardapios: [
      menu
    ], itensPorCardapio: {
      'almoco': [arroz]
    }, regras: [], operacao: {
      'refeicoes': {
        'almoco': {
          'grupos': [
            {
              'id': 'g',
              'nome': 'Grupo',
              'restricoes': ['vegano'],
              'adultos': 2,
              'criancas': 0,
              'bebes': 0,
              'itens': {}
            }
          ]
        }
      }
    });
    expect(plano.destinos.single.pendencias, isNotEmpty);
    expect(plano.destinos.single.pendencias.join(), contains('Grupo'));
  });
  for (final comPublico in [false, true]) {
    for (final comCardapio in [false, true]) {
      test(
          'matriz: público=$comPublico, cardápio=$comCardapio entrega prévia sem inventar capacidade',
          () {
        final plano = service.gerar(
            calculo: calculo(pessoas: comPublico ? 20 : 0),
            formato: FormatoPlanoInicial.lanche,
            cardapios: comCardapio ? [menu] : [],
            itensPorCardapio: comCardapio
                ? {
                    'almoco': [arroz]
                  }
                : {},
            regras: []);
        expect(plano.destinos, hasLength(1));
        expect(plano.destinos.single.sugerido, !comCardapio);
        expect(plano.publicoInformado, comPublico);
        expect(plano.destinos.single.resultados.isNotEmpty, comPublico);
        expect(plano.pendencias.join(), contains('verba de alimentação'));
        if (!comPublico) {
          expect(plano.pendencias.join(), contains('Escolha o público'));
        }
        expect(plano.orcamento, 1000);
      });
    }
  }

  test(
      'preserva receita privada, público por destino e entradas; exclui outro evento',
      () {
    final r = ItemEstimativaFinanceira(
        id: 'menu_almoco_arroz',
        categoria: 'comida',
        nome: 'Arroz',
        tipoItem: 'comida',
        publicoAlvo: 'todos',
        unidade: UnidadeEstimativa.quilo,
        quantidadePorConvidadoEquivalente: .123,
        valorUnitarioMedio: 12,
        premissas: {
          'id_cardapio': 'almoco',
          'id_item_cardapio': 'arroz',
          'receita': 'Receita da família',
          'estado': 'cru',
          'rendimento': 1,
          'revisada_pelo_organizador': true
        });
    final itens = {
      'almoco': [arroz.copyWith(unidade: 'kg')],
      'outro': [arroz.copyWith(idEvento: 'outra')]
    };
    final operacao = {
      'refeicoes': {
        'almoco': {
          'publico': {'adultos': 5, 'criancas': 0, 'bebes': 0}
        }
      }
    };
    final antes = jsonEncode(operacao);
    final plano = service.gerar(
        calculo: calculo(),
        cardapios: [
          menu,
          menu.copyWith(idCardapio: 'outro', idEvento: 'outra')
        ],
        itensPorCardapio: itens,
        regras: [r],
        operacao: operacao);
    expect(plano.destinos, hasLength(1));
    expect(plano.destinos.single.pessoas, 5);
    expect(plano.destinos.single.proposta.preservados, contains(r.id));
    expect(
        plano.destinos.single.proposta.regras.single
            .quantidadePorConvidadoEquivalente,
        .123);
    expect(plano.destinos.single.resultados.single.valorUnitarioMedio, 12);
    expect(r.premissas['receita'], 'Receita da família');
    expect(jsonEncode(operacao), antes);
  });

  test('receita de outro cardápio não contamina referência por nome', () {
    const r = ItemEstimativaFinanceira(
        id: 'menu_jantar_arroz',
        categoria: 'comida',
        nome: 'Arroz',
        tipoItem: 'comida',
        publicoAlvo: 'todos',
        unidade: UnidadeEstimativa.quilo,
        quantidadePorConvidadoEquivalente: 8,
        valorUnitarioMedio: 999,
        premissas: {'id_cardapio': 'jantar', 'receita': 'Privada'});
    final plano = service.gerar(calculo: calculo(), cardapios: [
      menu
    ], itensPorCardapio: {
      'almoco': [arroz]
    }, regras: [
      r
    ]);
    expect(
        plano.destinos.single.proposta.regras.single
            .quantidadePorConvidadoEquivalente,
        .055);
    expect(plano.destinos.single.resultados.single.valorUnitarioMedio, 0);
  });

  test('respostas salvas são reutilizadas e desconhecido fica pendente', () {
    const r = ItemEstimativaFinanceira(
        id: 'meta',
        categoria: 'comida',
        nome: 'Meta',
        tipoItem: 'outro',
        publicoAlvo: 'todos',
        unidade: UnidadeEstimativa.unidade,
        quantidadePorConvidadoEquivalente: 1,
        valorUnitarioMedio: 0,
        premissas: {
          'id_cardapio': 'almoco',
          'proposta_respostas': {
            'dog_tamanho_dog': 'grande',
            'dog_uso_dog': 'principal'
          }
        });
    final plano = service.gerar(calculo: calculo(), cardapios: [
      menu
    ], itensPorCardapio: {
      'almoco': [
        arroz.copyWith(idItem: 'dog', nome: 'Cachorro-quente'),
        arroz.copyWith(idItem: 'especial', nome: 'Receita especial')
      ]
    }, regras: [
      r
    ]);
    expect(
        plano.destinos.single.proposta.respostas['dog_tamanho_dog'], 'grande');
    expect(
        plano.destinos.single.proposta.regras.single
            .quantidadePorConvidadoEquivalente,
        1.5);
    expect(
        plano.destinos.single.pendencias.join(), contains('Receita especial'));
  });

  test(
      'categoria e serviço compartilhado não dividem arroz e massa como refeição',
      () {
    for (final escopo in [
      EscopoCardapio.categoria,
      EscopoCardapio.compartilhado
    ]) {
      final plano = service.gerar(calculo: calculo(), cardapios: [
        menu.copyWith(escopo: escopo)
      ], itensPorCardapio: {
        'almoco': [
          arroz,
          arroz.copyWith(idItem: 'massa', nome: 'Macarrão'),
          arroz.copyWith(idItem: 'carne', nome: 'Churrasco')
        ]
      }, regras: []);
      expect(plano.destinos.single.proposta.regras.any((r) => r.dividirGrupo),
          isFalse);
    }
  });

  test('dados ausentes e orçamento indefinido não viram plano completo', () {
    final plano = service.gerar(
        calculo: calculo(limite: null),
        cardapios: [menu],
        itensPorCardapio: {},
        regras: [],
        consultaCompleta: false);
    expect(plano.pendencias.join(),
        contains('consulta do evento está incompleta'));
    expect(plano.pendencias.join(), contains('Orçamento não definido'));
    expect(plano.destinos.single.pendencias.join(),
        contains('Itens ainda não carregados'));
    expect(plano.itensCalculados, 0);
  });
}
