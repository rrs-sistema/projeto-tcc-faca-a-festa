import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/tarefa/tarefa_model.dart';

class TarefaRemoteDatasource {
  TarefaRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _tarefas =>
      firestore.collection('tarefa');

  Stream<List<TarefaModel>> observarPorEvento(
    String idEvento, {
    bool ordenarPorData = false,
  }) {
    Query<Map<String, dynamic>> query =
        _tarefas.where('id_evento', isEqualTo: idEvento);
    if (ordenarPorData) {
      query = query.orderBy('data_prevista', descending: false);
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => TarefaModel.fromMap(document.data()))
              .toList(),
        );
  }

  Future<void> adicionar(TarefaModel tarefa) =>
      _tarefas.doc(tarefa.idTarefa).set(tarefa.toMap());

  Future<void> atualizar(TarefaModel tarefa) =>
      _tarefas.doc(tarefa.idTarefa).update(tarefa.toMap());

  Future<void> atualizarStatus(String idTarefa, StatusTarefa status) {
    return _tarefas.doc(idTarefa).update({'status': status.firestoreValue});
  }

  Future<void> excluir(String idTarefa) => _tarefas.doc(idTarefa).delete();
}
