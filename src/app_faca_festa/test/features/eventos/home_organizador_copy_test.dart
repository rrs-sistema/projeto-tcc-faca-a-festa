import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';

void main() {
  group('HomeOrganizadorCopy', () {
    test('resume convidados sem lista', () {
      expect(HomeOrganizadorCopy.convidadosValor(0, 0), '0 na lista');
    });

    test('resume convidados confirmados', () {
      expect(HomeOrganizadorCopy.convidadosValor(3, 12), '3 de 12');
    });

    test('pedidos de preço no plural', () {
      expect(HomeOrganizadorCopy.cotacoesValor(0), 'Nenhum pedido');
      expect(HomeOrganizadorCopy.cotacoesValor(1), '1 pedido');
      expect(HomeOrganizadorCopy.cotacoesValor(4), '4 pedidos');
    });

    test('percentual de orçamento', () {
      expect(HomeOrganizadorCopy.orcamentoPercentual(0.42), '42%');
    });

    test('faixa de tarefas distingue vazio e concluídas', () {
      expect(
        HomeOrganizadorCopy.tarefasFaixaTitulo(total: 0, pendentes: 0),
        HomeOrganizadorCopy.nenhumaTarefa,
      );
      expect(
        HomeOrganizadorCopy.tarefasFaixaTitulo(total: 2, pendentes: 0),
        HomeOrganizadorCopy.tarefasEmDia,
      );
      expect(
        HomeOrganizadorCopy.tarefasFaixaAcao(total: 2),
        HomeOrganizadorCopy.verTodasTarefas,
      );
    });

    test('prazo da tarefa distingue atraso, hoje e data distante', () {
      final agora = DateTime(2026, 10, 6, 15);
      expect(
        HomeOrganizadorCopy.prazoTarefa(DateTime(2026, 8, 27), agora).rotulo,
        'Atrasada · 27/08',
      );
      expect(
        HomeOrganizadorCopy.prazoTarefa(DateTime(2026, 8, 27), agora).atrasada,
        isTrue,
      );
      expect(
        HomeOrganizadorCopy.prazoTarefa(DateTime(2026, 10, 6, 8), agora).rotulo,
        'Hoje',
      );
      expect(
        HomeOrganizadorCopy.prazoTarefa(DateTime(2026, 10, 7), agora).rotulo,
        'Amanhã',
      );
      expect(
        HomeOrganizadorCopy.prazoTarefa(DateTime(2026, 10, 9), agora).rotulo,
        'Em 3 dias',
      );
      expect(
        HomeOrganizadorCopy.prazoTarefa(DateTime(2027, 7, 11), agora).rotulo,
        '11/07',
      );
      expect(
        HomeOrganizadorCopy.prazoTarefa(null, agora).rotulo,
        HomeOrganizadorCopy.semPrazo,
      );
    });

    test('resumo da faixa conta atrasadas sem alarmar o que está em dia', () {
      expect(
        HomeOrganizadorCopy.tarefasResumoFaixa(
          total: 0,
          pendentes: 0,
          atrasadas: 0,
        ),
        'Anote o que falta até o dia da festa.',
      );
      expect(
        HomeOrganizadorCopy.tarefasResumoFaixa(
          total: 4,
          pendentes: 1,
          atrasadas: 1,
        ),
        '1 atrasada',
      );
      expect(
        HomeOrganizadorCopy.tarefasResumoFaixa(
          total: 2,
          pendentes: 0,
          atrasadas: 0,
        ),
        'Nada pendente. A festa está em dia.',
      );
      expect(HomeOrganizadorCopy.eMaisTarefas(2), 'E mais 2 tarefas');
      expect(HomeOrganizadorCopy.distanciaFornecedor(0.4), '400 m');
      expect(HomeOrganizadorCopy.distanciaFornecedor(2.5), '2.5 km');
    });
  });
}
