import 'package:app_faca_festa/data/models/tarefa/tarefa_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task map preserves the current Firestore contract', () {
    final data = DateTime(2026, 8, 14, 18, 30);
    final model = TarefaModel(
      idTarefa: 'tarefa-1',
      idEvento: 'evento-1',
      idResponsavel: 'convidado-1',
      titulo: 'Comprar bebidas',
      descricao: 'Água e suco',
      dataPrevista: data,
      status: StatusTarefa.emAndamento,
      dataCadastro: data,
    );

    final map = model.toMap();
    expect(map['id_tarefa'], 'tarefa-1');
    expect(map['status'], 'em_andamento');
    expect((map['data_prevista'] as Timestamp).toDate(), data);
  });

  test('fromEntity preserves domain values without casting', () {
    final tarefa = Tarefa(
      idTarefa: 'tarefa-1',
      idEvento: 'evento-1',
      titulo: 'Comprar bebidas',
      status: StatusTarefa.concluida,
      dataCadastro: DateTime(2026, 8, 14),
    );

    final model = TarefaModel.fromEntity(tarefa);

    expect(model.idTarefa, tarefa.idTarefa);
    expect(model.status, StatusTarefa.concluida);
    expect(model.dataCadastro, tarefa.dataCadastro);
  });
}
