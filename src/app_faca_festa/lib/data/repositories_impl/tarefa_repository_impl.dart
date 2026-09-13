import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/domain/repositories/tarefa_repository.dart';
import '../datasources/remote/tarefa_remote_datasource.dart';
import '../models/tarefa/tarefa_model.dart';

class TarefaRepositoryImpl implements TarefaRepository {
  TarefaRepositoryImpl(this.remote);

  final TarefaRemoteDatasource remote;

  @override
  Stream<List<Tarefa>> observarPorEvento(
    String idEvento, {
    bool ordenarPorData = false,
  }) =>
      remote.observarPorEvento(idEvento, ordenarPorData: ordenarPorData);

  @override
  Future<void> adicionar(Tarefa tarefa) => remote.adicionar(
        tarefa is TarefaModel ? tarefa : TarefaModel.fromEntity(tarefa),
      );

  @override
  Future<void> atualizar(Tarefa tarefa) => remote.atualizar(
        tarefa is TarefaModel ? tarefa : TarefaModel.fromEntity(tarefa),
      );

  @override
  Future<void> atualizarStatus(String idTarefa, StatusTarefa status) =>
      remote.atualizarStatus(idTarefa, status);

  @override
  Future<void> excluir(String idTarefa) => remote.excluir(idTarefa);
}
