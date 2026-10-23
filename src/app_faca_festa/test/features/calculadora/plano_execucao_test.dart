import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'plano_evento_test.dart' show calculo;

CardapioItem itemExec(String menu,
        {bool informado = true,
        double comprado = 0,
        double quantidadeFinal = 0}) =>
    CardapioItem(
        idEvento: 'evento',
        idCardapio: menu,
        idItem: 'arroz',
        nome: 'Arroz',
        unidade: 'kg',
        tipo: TipoItemCardapio.comida,
        quantidadeFinal: quantidadeFinal,
        confirmado: true,
        disponibilidade: informado
            ? DisponibilidadeCardapio(
                comprado: comprado,
                estoque: 0,
                unidade: 'kg',
                estado: 'cru',
                nome: 'Arroz',
                publico: 'todos')
            : null);
ItemEstimativaFinanceira regraExec(String menu,
        {Map<String, dynamic>? ficha}) =>
    ItemEstimativaFinanceira(
        id: 'menu_${menu}_arroz',
        nome: 'Arroz',
        categoria: 'comida',
        tipoItem: 'comida',
        publicoAlvo: 'todos',
        unidade: UnidadeEstimativa.quilo,
        quantidadePorConvidadoEquivalente: .1,
        valorUnitarioMedio: 0,
        premissas: {
          'id_evento': 'evento',
          'id_cardapio': menu,
          'id_item_cardapio': 'arroz',
          'origem': 'ajuste_organizador',
          'revisada_pelo_organizador': true,
          'papel_na_refeicao': 'acompanhamento',
          'estado': 'cru',
          'estado_compra': 'cru',
          'ajustar_por_duracao': false,
          'ajustar_por_perfil': false,
          if (ficha != null) 'ficha_tecnica': ficha
        });
ContextoExecucaoPlano contextoExec(
        {List<String> menus = const ['almoco', 'janta'],
        Map<String, dynamic> operacao = const {},
        Map<String, Map<String, dynamic>> tarefas = const {},
        bool informado = true,
        double comprado = 0,
        double quantidadeFinal = 0,
        List<Map<String, dynamic>> compromissos = const [],
        Map<String, Map<String, dynamic>?> fontes = const {}}) =>
    ContextoExecucaoPlano(
        evento: 'evento',
        fontes: fontes,
        operacao: operacao,
        cardapios: [
          for (final id in menus)
            Cardapio(
                idEvento: 'evento',
                idCardapio: id,
                titulo: id,
                escopo: EscopoCardapio.refeicao)
        ],
        itens: {
          for (final id in menus)
            id: [
              itemExec(id,
                  informado: informado,
                  comprado: comprado,
                  quantidadeFinal: quantidadeFinal)
            ]
        },
        compromissos: compromissos,
        tarefas: tarefas);
Map<String, dynamic> loteExec(double total,
        {Map<String, dynamic> reservas = const {},
        String nome = 'Arroz',
        String estado = 'cru'}) =>
    {
      'nome': nome,
      'total': total,
      'unidade': 'kg',
      'estado': estado,
      'reservas': reservas
    };
PropostaExecucaoPlano proporExec(ContextoExecucaoPlano contexto,
        {int pessoas = 20,
        bool declarar = false,
        Map<String, dynamic>? ficha}) =>
    const PlanoExecucaoService().gerar(
        pedido: 'pedido',
        contexto: contexto,
        calculo: calculo(pessoas: pessoas).copyWith(margemPersonalizada: 0),
        regras: [
          for (final m in contexto.cardapios)
            regraExec(m.idCardapio, ficha: ficha)
        ],
        declararSemCompras: declarar);
Map<String, dynamic> fichaExec() => {
      'versao': 1,
      'prato': 'Arroz',
      'rendimento': 2.0,
      'unidade': 'kg',
      'estado': 'cru',
      'ingredientes': [
        {
          'id': 'g',
          'nome': 'Grão para a receita',
          'quantidade': 1.0,
          'unidade': 'kg',
          'estado': 'seco'
        },
        {
          'id': 'a',
          'nome': 'Água',
          'quantidade': 1.0,
          'unidade': 'L',
          'estado': 'pronto'
        },
      ]
    };

void main() {
  test(
      'ingredientes de estado diferente não são agregados e mantêm os IDs dos destinos',
      () {
    final segunda = fichaExec();
    segunda['ingredientes'][0]['estado'] = 'cru';
    final p = const PlanoExecucaoService().gerar(
        pedido: 'estados',
        contexto: contextoExec(),
        calculo: calculo(pessoas: 20).copyWith(margemPersonalizada: 0),
        regras: [
          regraExec('almoco', ficha: fichaExec()),
          regraExec('janta', ficha: segunda)
        ]);
    final graos =
        p.compras.where((l) => l['nome'] == 'Grão para a receita').toList();
    expect(graos.length, 2);
    expect(graos.map((l) => l['estado']).toSet(), {'cru', 'seco'});
    expect(
        graos
            .expand((l) => l['destinos_ids'] as List)
            .map((d) => d['cardapio'])
            .toSet(),
        {'almoco', 'janta'});
  });
  test(
      'preparo iniciado preserva ingredientes reservados mesmo se o público diminuir',
      () {
    final base = proporExec(
        contextoExec(operacao: {
          'lotes': {
            'grao': loteExec(4, nome: 'Grão para a receita', estado: 'seco')
          }
        }),
        ficha: fichaExec());
    final tarefa = base.alteracoes.entries.firstWhere((e) =>
        e.value['calculadora_chave'] ==
        assinaturaExecucao(['preparo', 'almoco', 'arroz']));
    final menor = proporExec(
        contextoExec(operacao: base.operacao, tarefas: {
          tarefa.key.split('/').last: {
            ...tarefa.value,
            'status': 'em_andamento'
          }
        }),
        pessoas: 10,
        ficha: fichaExec());
    final rs = menor.operacao['lotes']['grao']['reservas'] as Map;
    final almoco = rs.values.singleWhere((r) => r['refeicao'] == 'almoco');
    expect(almoco['quantidade'], 1);
    expect(menor.pendencias.join(), contains('estoque físico'));
  });

  test(
      'quantidade final escolhida orienta compras e ficha sem ser substituída pela referência',
      () {
    final p = proporExec(contextoExec(quantidadeFinal: 7, comprado: 1));
    expect(p.compras.single['quantidade'], 12);
    expect(p.mudancas.join(), contains('mantida a quantidade final'));
    expect(p.alteracoes['cardapios/almoco/itens/arroz']!['quantidade_sugerida'],
        2);
    final ingredientes = proporExec(
        contextoExec(quantidadeFinal: 7, comprado: 1),
        ficha: fichaExec());
    expect(
        ingredientes.compras.firstWhere(
            (r) => r['nome'] == 'Grão para a receita')['quantidade'],
        6);
  });

  test(
      'redistribuição usa excesso liberado em outra refeição antes de sugerir compra',
      () {
    final reservaA = {
      'refeicao': 'almoco',
      'item': 'arroz',
      'nome': 'Arroz',
      'publico': 'todos',
      'quantidade': 1.0,
      'origem': 'execucao_v1'
    };
    final reservaB = {...reservaA, 'refeicao': 'janta', 'quantidade': 3.0};
    final ctx = contextoExec(operacao: {
      'refeicoes': {
        'almoco': {
          'publico': {'adultos': 30, 'criancas': 0, 'bebes': 0}
        },
        'janta': {
          'publico': {'adultos': 10, 'criancas': 0, 'bebes': 0}
        }
      },
      'lotes': {
        'lote': loteExec(4, reservas: {
          OperacaoCalculadoraService.destino('almoco', 'arroz'): reservaA,
          OperacaoCalculadoraService.destino('janta', 'arroz'): reservaB
        })
      }
    });
    final p = proporExec(ctx);
    expect(p.compras.single['quantidade'], 0);
    final rs = p.operacao['lotes']['lote']['reservas'];
    expect(
        rs[OperacaoCalculadoraService.destino('almoco', 'arroz')]['quantidade'],
        3);
    expect(
        rs[OperacaoCalculadoraService.destino('janta', 'arroz')]['quantidade'],
        1);
  });
  test(
      'item pendente mantém sua reserva anterior em vez de liberar saldo silenciosamente',
      () {
    final reserva = {
      'refeicao': 'almoco',
      'item': 'arroz',
      'nome': 'Arroz',
      'publico': 'todos',
      'quantidade': 2.0,
      'origem': 'execucao_v1'
    };
    final p = proporExec(contextoExec(informado: false, operacao: {
      'lotes': {
        'lote': loteExec(2, reservas: {
          OperacaoCalculadoraService.destino('almoco', 'arroz'): reserva
        })
      }
    }));
    expect(
        p.operacao['lotes']['lote']['reservas']
            [OperacaoCalculadoraService.destino('almoco', 'arroz')],
        reserva);
  });
  test(
      'necessidades específicas impedem destinação automática de lote genérico',
      () {
    final p = proporExec(contextoExec(operacao: {
      'refeicoes': {
        'almoco': {
          'destinos_itens': {
            'arroz': {'modo': 'demais', 'grupos': []}
          }
        },
        'janta': {
          'destinos_itens': {
            'arroz': {'modo': 'demais', 'grupos': []}
          }
        }
      },
      'lotes': {'lote': loteExec(20)}
    }));
    expect(p.reservas, isEmpty);
    expect(p.pendencias.join(), contains('necessidades específicas'));
    expect(p.compras.length, 2);
  });
  test(
      'lista anterior direciona uma receita aos ingredientes e não cobra o prato inteiro outra vez',
      () {
    final r = regraExec('almoco', ficha: fichaExec());
    final calc = calculo().copyWith(margemPersonalizada: 0);
    final resultado = const CalculadoraFestaService()
        .calcularItens(calculo: calc, itensBase: [r]).single;
    final lista = const ListaComprasCalculadoraService().analisar(
        resultado: resultado,
        regra: r,
        cardapio: [itemExec('almoco')],
        compromissos: [],
        convidados: calc.convidadosEquivalentes,
        perfil: calc.perfilFesta,
        duracao: 4);
    expect(lista.situacao, SituacaoCompra.planejarIngredientes);
    expect(lista.falta, isNull);
  });

  test(
      'estoque compartilhado não duplica saldo e compra é consolidada entre refeições',
      () {
    final ctx = contextoExec(operacao: {
      'lotes': {'lote': loteExec(3)}
    });
    final antes = jsonEncode(ctx.operacao);
    final p = proporExec(ctx);
    expect(p.compras.single['quantidade'], 1);
    expect(
        p.reservas.fold<double>(0, (s, r) => s + (r['quantidade'] as num)), 3);
    expect(jsonEncode(ctx.operacao), antes);
    expect(p.alteracoes['cardapios/almoco/itens/arroz']!.keys,
        ['quantidade_sugerida']);
    expect(p.alteracoes.keys.where((k) => k.startsWith('tarefa/')).length, 1);
  });
  test('reservas manuais e medidas incompatíveis permanecem preservadas', () {
    final manual = {
      'refeicao': 'outro',
      'item': 'arroz',
      'nome': 'Arroz',
      'publico': 'todos',
      'quantidade': 2.0
    };
    final ctx = contextoExec(operacao: {
      'lotes': {
        'lote': loteExec(3, reservas: {'manual': manual}),
        'pronto': loteExec(9, estado: 'pronto')
      }
    });
    final p = proporExec(ctx);
    expect(p.compras.single['quantidade'], 3);
    expect(p.operacao['lotes']['lote']['reservas']['manual'], manual);
    expect(p.operacao['lotes']['pronto']['reservas'], isEmpty);
  });
  test(
      'diminuir público libera somente a reserva do executor, sem modificar quantidade final',
      () {
    final original = proporExec(contextoExec(operacao: {
      'lotes': {'lote': loteExec(9)}
    }));
    final menor =
        proporExec(contextoExec(operacao: original.operacao), pessoas: 10);
    expect(
        menor.reservas.fold<double>(0, (s, r) => s + (r['quantidade'] as num)),
        2);
    expect(menor.mudancas.join(), contains('Liberar'));
    expect(
        menor.alteracoes.values.any((m) =>
            m.containsKey('quantidade_final') || m.containsKey('confirmado')),
        false);
    const OperacaoCalculadoraService().validarDocumento(menor.operacao);
  });
  test(
      'disponibilidade ausente não vira comprado zero sem declaração explícita',
      () {
    final ctx = contextoExec(informado: false);
    final antes = proporExec(ctx);
    expect(antes.compras, isEmpty);
    expect(antes.pendencias.join(), contains('Informe'));
    final aprovado = proporExec(ctx, declarar: true);
    expect(aprovado.compras.single['quantidade'], 4);
    expect(
        aprovado.alteracoes['cardapios/almoco/itens/arroz']!['disponibilidade']
            ['comprado'],
        0);
  });
  test('comprado real é descontado uma vez e nunca regravado pela proposta',
      () {
    final p = proporExec(contextoExec(comprado: 1));
    expect(p.compras.single['quantidade'], 2);
    expect(p.alteracoes.values.any((v) => v.containsKey('disponibilidade')),
        false);
  });
  test(
      'ficha desdobra ingrediente compatível, desconta seu lote e cria tarefa de preparo por destino',
      () {
    final p = proporExec(
        contextoExec(operacao: {
          'lotes': {
            'grao': loteExec(1, nome: 'Grão para a receita', estado: 'seco')
          }
        }),
        ficha: fichaExec());
    expect(
        p.compras.firstWhere(
            (r) => r['nome'] == 'Grão para a receita')['quantidade'],
        1);
    expect(p.compras.firstWhere((r) => r['nome'] == 'Água')['quantidade'], 2);
    expect(
        p.alteracoes.values
            .where(
                (v) => (v['titulo']?.toString() ?? '').startsWith('Preparar'))
            .length,
        2);
    expect(
        const OperacaoCalculadoraService()
            .reservado(p.operacao, itemExec('almoco'), 'kg', 'cru'),
        0);
    final rs = p.operacao['lotes']['grao']['reservas'] as Map;
    final r = Map<String, dynamic>.from(rs.values.single as Map);
    final liberado = const OperacaoCalculadoraService().aplicar(p.operacao, {
      'tipo': 'reservar',
      'revisao': p.operacao['revisao'],
      'id_lote': 'grao',
      'reserva': {...r, 'quantidade': 0}
    });
    expect(liberado['lotes']['grao']['reservas'], isEmpty);
  });
  test(
      'ficha com estado ou rendimento incompatível fica pendente sem inventar ingrediente',
      () {
    final f = fichaExec()..['estado'] = 'pronto';
    final p = proporExec(contextoExec(), ficha: f);
    expect(p.compras, isEmpty);
    expect(p.pendencias.join(), contains('ficha'));
  });
  test('tarefas iniciadas, concluídas ou editadas não são substituídas', () {
    final base = proporExec(contextoExec());
    final t =
        base.alteracoes.entries.singleWhere((e) => e.key.startsWith('tarefa/'));
    for (final status in ['em_andamento', 'concluida', 'a_fazer']) {
      final dados = {
        ...t.value,
        'status': status,
        if (status == 'a_fazer') 'titulo': 'Minha alteração'
      };
      final ctx = contextoExec(tarefas: {t.key.split('/').last: dados});
      final p = proporExec(ctx, pessoas: 30);
      expect(p.alteracoes.containsKey(t.key), false);
      expect(p.pendencias.join(), contains('preservada'));
    }
  });
  test(
      'tarefa pendente gerada é atualizada por identidade e mantém responsável e prazo',
      () {
    final base = proporExec(contextoExec());
    final t =
        base.alteracoes.entries.singleWhere((e) => e.key.startsWith('tarefa/'));
    final p = proporExec(
        contextoExec(tarefas: {
          t.key.split('/').last: {
            ...t.value,
            'id_responsavel': 'ana',
            'data_prevista': 'amanha'
          }
        }),
        pessoas: 30);
    expect(p.alteracoes[t.key]!['descricao'], contains('6,00'));
    expect(p.alteracoes[t.key]!.containsKey('id_responsavel'), false);
    expect(p.alteracoes[t.key]!.containsKey('data_prevista'), false);
  });
  test('serviço integral contratado impede compra e reserva adicionais', () {
    final cobertura = 'v2:["evento","almoco","arroz","arroz|kg|todos"]';
    final p = proporExec(contextoExec(menus: [
      'almoco'
    ], compromissos: [
      {
        'cobre_itens': [cobertura],
        'contratado': true,
        'descricao': 'Buffet'
      }
    ], operacao: {
      'lotes': {'lote': loteExec(10)}
    }));
    expect(p.compras, isEmpty);
    expect(p.reservas, isEmpty);
  });
  test(
      'público é refeito da fonte escolhida e preserva a distinção entre previstos e não recusados',
      () {
    final ctx = contextoExec(fontes: {
      'evento/evento': {'total_adultos': 30, 'total_criancas': 5},
      'convidado/a': {'tipo_convidado': 'adulto', 'status': 'confirmado'},
      'convidado/b': {'tipo_convidado': 'crianca', 'status': 'pendente'},
      'convidado/c': {'tipo_convidado': 'adulto', 'status': 'recusado'}
    });
    final p = proporExec(ctx);
    expect(p.publico['adultos'], 1);
    expect(p.publico['criancas'], 1);
    final previsto = const PlanoExecucaoService().gerar(
        pedido: 'previstos',
        contexto: ctx,
        calculo: calculo().copyWith(baseCalculo: BaseCalculoFesta.previstos),
        regras: [regraExec('almoco'), regraExec('janta')]);
    expect(previsto.publico['adultos'], 30);
    expect(previsto.publico['criancas'], 5);
  });
  test('nova tentativa gera mesmas tarefas e nenhuma alteração financeira', () {
    final a = proporExec(contextoExec()), b = proporExec(contextoExec());
    expect(a.assinatura, b.assinatura);
    expect(a.alteracoes.keys, b.alteracoes.keys);
    expect(a.alteracoes.keys.any((p) => p.startsWith('orcamento/')), false);
  });
}
