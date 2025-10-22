import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/model.dart';

class TarefaController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Observáveis reativos
  final RxList<TarefaModel> tarefas = <TarefaModel>[].obs;
  final RxList<UsuarioModel> usuarios = <UsuarioModel>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  // 🔹 Assinatura para cancelamento de escuta
  StreamSubscription? _tarefasSubscription;

  @override
  void onInit() {
    super.onInit();
    carregarUsuarios();
  }

  // ==========================================================
  // 🔹 Escuta tarefas em tempo real (reatividade total)
  // ==========================================================

  Future<void> listenTarefas(String idEvento) async {
    if (idEvento.isEmpty) return;

    _db.collection('tarefa').where('id_evento', isEqualTo: idEvento).snapshots().listen((snapshot) {
      final lista = snapshot.docs.map((d) {
        final data = d.data();
        return TarefaModel.fromMap(data);
      }).toList();

      tarefas.assignAll(lista);
    }, onError: (e) {
      erro.value = 'Erro ao carregar tarefas: $e';
    });
  }

  void listenTarefas00(String? idEvento) {
    if (idEvento == null) return;
    carregando.value = true;

    // Cancela escuta anterior, se existir
    _tarefasSubscription?.cancel();

    // Cria nova stream com bind direto na RxList
    _tarefasSubscription = _db
        .collection('tarefa')
        .where('id_evento', isEqualTo: idEvento) // 🔹 campo correto
        .orderBy('data_prevista', descending: false)
        .snapshots()
        .listen((snapshot) {
      final lista = snapshot.docs.map((doc) => TarefaModel.fromMap(doc.data())).toList();

      tarefas.assignAll(lista);
      carregando.value = false;
    }, onError: (e) {
      erro.value = e.toString();
      carregando.value = false;
    });
  }

  // ==========================================================
  // 🔹 Carrega usuários ativos (para seleção de responsáveis)
  // ==========================================================
  Future<void> carregarUsuarios() async {
    try {
      final snapshot = await _db.collection('usuarios').where('ativo', isEqualTo: true).get();

      final lista = snapshot.docs.map((d) => UsuarioModel.fromMap(d.data())).toList();

      usuarios.assignAll(lista);
    } catch (e) {
      erro.value = 'Erro ao carregar usuários: $e';
    }
  }

  // ==========================================================
  // 🔹 Adiciona nova tarefa
  // ==========================================================
  Future<void> adicionarTarefa(
      {required String nome,
      String? descricao,
      DateTime? dataPrevista,
      String? idResponsavel,
      String? idEvento}) async {
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

  // ==========================================================
  // 🔹 Editar / Atualizar tarefa
  // ==========================================================
  Future<void> editarTarefa(TarefaModel tarefa) async {
    try {
      await _db.collection('tarefa').doc(tarefa.idTarefa).update(tarefa.toMap());
    } catch (e) {
      erro.value = 'Erro ao editar tarefa: $e';
    }
  }

  Future<void> atualizarStatus(String idTarefa, StatusTarefa novoStatus) async {
    try {
      await _db.collection('tarefa').doc(idTarefa).update({
        'status': novoStatus.firestoreValue,
      });
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  // ==========================================================
  // 🔹 Excluir tarefa
  // ==========================================================
  Future<void> excluirTarefa(String idTarefa) async {
    try {
      await _db.collection('tarefa').doc(idTarefa).delete();
    } catch (e) {
      erro.value = 'Erro ao excluir tarefa: $e';
    }
  }

  // ==========================================================
  // 🔹 Cálculos reativos de progresso
  // ==========================================================
  double get progresso {
    if (tarefas.isEmpty) return 0;
    final concluidas = tarefas.where((t) => t.status == StatusTarefa.concluida).length;
    return concluidas / tarefas.length;
  }

  int get concluidas => tarefas.where((t) => t.status == StatusTarefa.concluida).length;
  int get pendentes => tarefas.where((t) => t.status != StatusTarefa.concluida).length;

  // ==========================================================
  // 🔹 Resetar controller
  // ==========================================================
  void reset() {
    _tarefasSubscription?.cancel();
    tarefas.clear();
    usuarios.clear();
  }

  // ==========================================================
  // 🔹 Fechamento seguro do controller
  // ==========================================================
  @override
  void onClose() {
    _tarefasSubscription?.cancel();
    super.onClose();
  }
}
