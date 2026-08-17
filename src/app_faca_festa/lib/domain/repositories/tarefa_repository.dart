import '../entities/tarefa.dart';

abstract interface class TarefaRepository {
  Stream<List<Tarefa>> observarPorEvento(
    String idEvento, {
    bool ordenarPorData = false,
  });

  Future<void> adicionar(Tarefa tarefa);

  Future<void> atualizar(Tarefa tarefa);

  Future<void> atualizarStatus(String idTarefa, StatusTarefa status);

  Future<void> excluir(String idTarefa);
}
