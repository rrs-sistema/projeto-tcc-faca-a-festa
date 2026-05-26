import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/model.dart';
import 'app_controller.dart';
import 'evento_controller.dart';

class TarefaController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Observáveis reativos
  final RxList<TarefaModel> tarefas = <TarefaModel>[].obs;
  final RxList<ConvidadoModel> usuarios = <ConvidadoModel>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  // 🔹 Assinatura para cancelamento de escuta
  StreamSubscription? _tarefasSubscription;

  final eventoController = Get.put(EventoController());

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
      carregando.value = true;
      await Future.delayed(const Duration(seconds: 5));
      erro.value = '';

      // 🔹 LIMPA lista atual
      usuarios.clear();

      // ============================================================
      // 1️⃣ BUSCAR CONVIDADOS DO EVENTO
      // ============================================================
      final snapshot = await _db
          .collection('convidado')
          .where('id_evento', isEqualTo: eventoController.eventoAtual.value?.idEvento)
          .get();

      final listaConvidados = snapshot.docs.map((d) => ConvidadoModel.fromMap(d.data())).toList();

      // ============================================================
      // 2️⃣ PEGAR ORGANIZADOR LOGADO (AppController)
      // ============================================================
      final appController = Get.find<AppController>();
      final user = appController.usuarioLogado.value;

      if (user != null) {
        // ============================================================
        // 3️⃣ CONVERTER USUÁRIO → ConvidadoModel "virtual"
        // ============================================================
        final organizador = ConvidadoModel(
          idConvidado: user.idUsuario,
          idEvento: eventoController.eventoAtual.value?.idEvento ?? '',
          nome: user.nome,
          contato: user.email,
          email: user.email,
          status: StatusConvidado.confirmado, // Organizador sempre confirmado
          //adulto: true,
          //grupoMesa: null,
          cuidadoEspecial: false, 
          dataCadastro: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        );

        // Evitar duplicação caso o organizador também esteja na coleção "convidado"
        final jaExiste = listaConvidados.any((c) => c.idConvidado == user.idUsuario);

        if (!jaExiste) {
          listaConvidados.insert(0, organizador); // adiciona no topo
        }
      }

      // ============================================================
      // 4️⃣ Atualizar lista reativa
      // ============================================================
      usuarios.assignAll(listaConvidados);
    } catch (e) {
      erro.value = 'Erro ao carregar usuários: $e';
    } finally {
      carregando.value = false;
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
// 🔹 Lista de tarefas com data mais próxima (ordenadas)
// ==========================================================
  List<TarefaModel> tarefasProximas({int diasLimite = 30}) {
    final hoje = DateTime.now().subtract(Duration(days: 150));
    final limite = hoje.add(Duration(days: diasLimite));

    final proximas = tarefas
        .where((t) =>
            t.dataPrevista != null &&
            t.dataPrevista!.isAfter(hoje.subtract(const Duration(days: 1))) &&
            t.dataPrevista!.isBefore(limite))
        .toList();

    proximas.sort((a, b) => a.dataPrevista!.compareTo(b.dataPrevista!));
    return proximas;
  }

  // ==========================================================
  // 🔹 Cálculos reativos de progresso
  // ==========================================================
  double get progresso {
    if (tarefas.isEmpty) return 0;
    final concluidas = tarefas.where((t) => t.status == StatusTarefa.concluida).length;
    return concluidas / tarefas.length;
  }

  int get total => tarefas.length;
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
