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
  String? _idEvento;

  @override
  void onInit() {
    super.onInit();
    carregarUsuario();
  }

  /// 🔹 Configura o evento e inicia a escuta
  void setEvento(String idEvento) {
    if (_idEvento == idEvento) return; // evita recriar o listener
    _idEvento = idEvento;
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
    if (_idEvento == null) return;
    carregando.value = true;

    _db
        .collection('tarefa')
        .where('id_evento_evento', isEqualTo: _idEvento)
        .orderBy('data_prevista', descending: false)
        .snapshots()
        .listen((snapshot) async {
      final lista = <TarefaModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tarefa = TarefaModel.fromMap(data);
        lista.add(tarefa);
      }

      tarefas.assignAll(lista);
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
        idEvento: _idEvento ?? '',
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

  double get progresso {
    if (tarefas.isEmpty) return 0;
    final concluidas = tarefas.where((t) => t.status == StatusTarefa.concluida).length;
    return concluidas / tarefas.length;
  }

  int get concluidas => tarefas.where((t) => t.status == StatusTarefa.concluida).length;

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

  Future<void> atualizarStatus(String idTarefa, StatusTarefa novoStatus) async {
    await _db.collection('tarefa').doc(idTarefa).update({
      'status': novoStatus.firestoreValue,
    });
  }

  Future<void> excluirTarefa(String idTarefa) async {
    await _db.collection('tarefa').doc(idTarefa).delete();
  }
}
