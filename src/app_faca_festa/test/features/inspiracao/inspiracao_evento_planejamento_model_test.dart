import 'package:app_faca_festa/data/models/evento/inspiracao_evento_planejamento_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads event inspiration tasks from legacy map keys', () {
    final tarefa = TarefaInspiracaoEventoModel.fromMap(
      {
        'idEvento': 'evento-1',
        'idUsuario': 'user-1',
        'inspiracaoId': 'insp-1',
        'nome': 'Reservar buffet',
        'statusConclusao': true,
        'origem': 'inspiracao',
        'deleted': false,
      },
      documentId: 'tarefa-1',
    );

    expect(tarefa.id, 'tarefa-1');
    expect(tarefa.eventoId, 'evento-1');
    expect(tarefa.userId, 'user-1');
    expect(tarefa.titulo, 'Reservar buffet');
    expect(tarefa.concluida, isTrue);
    expect(
      tarefa.visivelPara(eventoId: 'evento-1', userId: 'user-1'),
      isTrue,
    );
    expect(tarefa.pertenceAInspiracao('insp-1'), isTrue);
  });

  test('reads event inspiration budget items from legacy map keys', () {
    final item = ItemOrcamentoInspiracaoEventoModel.fromMap(
      {
        'eventoId': 'evento-1',
        'userId': 'user-1',
        'inspiracaoId': 'insp-1',
        'nome': 'Buffet completo',
        'valorEstimado': '1200,5',
        'custoReal': 0,
        'origem': 'inspiracao_app',
      },
      documentId: 'item-1',
    );

    expect(item.item, 'Buffet completo');
    expect(item.custoEstimado, 1200.5);
    expect(item.valorOrcado, 1200.5);
    expect(item.pertenceAInspiracao('insp-1'), isTrue);
    expect(item.visivelPara(eventoId: 'outro', userId: 'user-1'), isFalse);
  });

  test('ignores deleted or foreign planning documents', () {
    final tarefa = TarefaInspiracaoEventoModel.fromMap({
      'id': 'tarefa-1',
      'eventoId': 'evento-1',
      'userId': 'user-1',
      'inspiracaoId': 'insp-1',
      'titulo': 'Reservar buffet',
      'deletado': true,
      'origem': 'inspiracao',
    });

    expect(tarefa.visivelPara(eventoId: 'evento-1', userId: 'user-1'), isFalse);
    expect(tarefa.pertenceAInspiracao('insp-1'), isFalse);
  });
}
