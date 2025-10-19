import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/models/model.dart';

class TarefaController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<TarefaModel> tarefas = <TarefaModel>[].obs;
  final RxList<UsuarioModel> usuarios = <UsuarioModel>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  /// 🔹 ID do evento ativo
  String? idEvento; // 🔹 Pode ser setado depois

  @override
  void onInit() {
    super.onInit();
    carregarUsuario();
  }

  void setEvento(String id) {
    idEvento = id;
    listenTarefas();
  }

  Future<void> carregarUsuario() async {
    final snapshot = await _db.collection('usuarios').where('ativo', isEqualTo: true).get();

    final lista = snapshot.docs.map((d) => UsuarioModel.fromMap(d.data())).toList();
    usuarios.assignAll(lista);
  }

  // ======================================================
  // 🔹 Carregar tarefas em tempo real
  // ======================================================

  void listenTarefas() {
    if (idEvento == null) return;

    carregando.value = true;
    _db
        .collection('tarefa')
        .where('id_evento_evento', isEqualTo: idEvento)
        .orderBy('data_prevista', descending: false)
        .snapshots()
        .listen((snapshot) {
      tarefas.assignAll(
        snapshot.docs.map((d) => TarefaModel.fromMap(d.data())).toList(),
      );
      carregando.value = false;
    }, onError: (e) {
      erro.value = e.toString();
      carregando.value = false;
    });
  }

  // ======================================================
  // 🔹 Adicionar nova tarefa
  // ======================================================
  Future<void> adicionarTarefa({
    required String nome,
    String? descricao,
    DateTime? dataPrevista,
    String? idResponsavel,
  }) async {
    try {
      final id = const Uuid().v4();
      final nova = TarefaModel(
        idTarefa: id,
        idEvento: idEvento ?? '',
        titulo: nome,
        descricao: descricao,
        dataPrevista: dataPrevista,
        idResponsavel: idResponsavel,
        status: StatusTarefa.aFazer,
      );

      await _db.collection('tarefa').doc(id).set(nova.toMap());
    } catch (e) {
      erro.value = 'Erro ao adicionar tarefa: $e';
    }
  }

  // ======================================================
  // 🔹 Atualizar status
  // ======================================================
  Future<void> atualizarStatus(String idTarefa, StatusTarefa novoStatus) async {
    try {
      await _db.collection('tarefa').doc(idTarefa).update({'status': novoStatus.firestoreValue});
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  // ======================================================
  // 🔹 Editar tarefa
  // ======================================================
  Future<void> editarTarefa(TarefaModel tarefa) async {
    try {
      await _db.collection('tarefa').doc(tarefa.idTarefa).update(tarefa.toMap());
    } catch (e) {
      erro.value = 'Erro ao editar tarefa: $e';
    }
  }

  // ======================================================
  // 🔹 Excluir tarefa
  // ======================================================
  Future<void> excluirTarefa(String idTarefa) async {
    try {
      await _db.collection('tarefa').doc(idTarefa).delete();
    } catch (e) {
      erro.value = 'Erro ao excluir tarefa: $e';
    }
  }

  // ======================================================
  // 🔹 Indicadores de progresso
  // ======================================================
  double get progresso {
    if (tarefas.isEmpty) return 0;
    final concluidas = tarefas.where((t) => t.status == StatusTarefa.concluida).length;
    return concluidas / tarefas.length;
  }

  int get concluidas => tarefas.where((t) => t.status == StatusTarefa.concluida).length;
}
