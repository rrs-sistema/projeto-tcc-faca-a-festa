import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import './../domain/entities/convidado.dart';
import './../domain/entities/tarefa.dart';
import './../domain/repositories/convidado_repository.dart';
import './../domain/repositories/tarefa_repository.dart';
import 'app_controller.dart';
import 'evento_controller.dart';

class TarefaController extends GetxController {
  TarefaController({
    required TarefaRepository repository,
    required ConvidadoRepository convidadoRepository,
  })  : _repository = repository,
        _convidadoRepository = convidadoRepository;

  final TarefaRepository _repository;
  final ConvidadoRepository _convidadoRepository;

  final RxList<Tarefa> tarefas = <Tarefa>[].obs;
  final RxList<Convidado> usuarios = <Convidado>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;
  StreamSubscription<List<Tarefa>>? _tarefasSubscription;

  EventoController get eventoController => Get.find<EventoController>();

  @override
  void onInit() {
    super.onInit();
    unawaited(carregarUsuarios());
  }

  Future<void> listenTarefas(String idEvento) async {
    if (idEvento.isEmpty) return;
    carregando.value = true;
    erro.value = '';
    await _iniciarEscuta(idEvento, ordenarPorData: false);
  }

  void listenTarefas00(String? idEvento) {
    if (idEvento == null) return;
    carregando.value = true;
    unawaited(_iniciarEscuta(idEvento, ordenarPorData: true));
  }

  Future<void> _iniciarEscuta(
    String idEvento, {
    required bool ordenarPorData,
  }) async {
    await _tarefasSubscription?.cancel();
    _tarefasSubscription = _repository
        .observarPorEvento(idEvento, ordenarPorData: ordenarPorData)
        .listen(
      (lista) {
        tarefas.assignAll(lista);
        carregando.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = ordenarPorData
            ? error.toString()
            : 'Erro ao carregar tarefas: $error';
        carregando.value = false;
      },
    );
  }

  Future<void> carregarUsuarios() async {
    try {
      carregando.value = true;
      await Future<void>.delayed(const Duration(seconds: 5));
      erro.value = '';
      usuarios.clear();

      final idEvento = eventoController.eventoAtualEntidade?.idEvento ?? '';
      final lista = idEvento.isEmpty
          ? <Convidado>[]
          : await _convidadoRepository.observarPorEvento(idEvento).first;

      final convidados = lista.toList();
      final user = Get.find<AppController>().usuarioLogado.value;
      if (user != null &&
          !convidados.any((item) => item.idConvidado == user.idUsuario)) {
        final agora = DateTime.now();
        convidados.insert(
          0,
          Convidado(
            idConvidado: user.idUsuario,
            idEvento: idEvento,
            nome: user.nome,
            contato: user.email,
            email: user.email,
            status: StatusConvidado.confirmado,
            cuidadoEspecial: false,
            dataCadastro: agora,
            dataAtualizacao: agora,
          ),
        );
      }
      usuarios.assignAll(convidados);
    } catch (e) {
      erro.value = 'Erro ao carregar usuários: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> adicionarTarefa({
    required String nome,
    String? descricao,
    DateTime? dataPrevista,
    String? idResponsavel,
    String? idEvento,
  }) async {
    try {
      await _repository.adicionar(
        Tarefa(
          idTarefa: const Uuid().v4(),
          idEvento: idEvento ?? '',
          titulo: nome,
          descricao: descricao,
          dataPrevista: dataPrevista,
          idResponsavel: idResponsavel,
          status: StatusTarefa.aFazer,
        ),
      );
    } catch (e) {
      erro.value = 'Erro ao adicionar tarefa: $e';
    }
  }

  Future<void> editarTarefa(Tarefa tarefa) async {
    try {
      await _repository.atualizar(tarefa);
    } catch (e) {
      erro.value = 'Erro ao editar tarefa: $e';
    }
  }

  Future<bool> atualizarStatus(
    String idTarefa,
    StatusTarefa novoStatus,
  ) async {
    try {
      await _repository.atualizarStatus(idTarefa, novoStatus);
      return true;
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
      return false;
    }
  }

  Future<void> excluirTarefa(String idTarefa) async {
    try {
      await _repository.excluir(idTarefa);
    } catch (e) {
      erro.value = 'Erro ao excluir tarefa: $e';
    }
  }

  List<Tarefa> tarefasProximas({int diasLimite = 30}) {
    final hoje = DateTime.now().subtract(const Duration(days: 150));
    final limite = hoje.add(Duration(days: diasLimite));
    return tarefas
        .where((tarefa) =>
            tarefa.dataPrevista != null &&
            tarefa.dataPrevista!
                .isAfter(hoje.subtract(const Duration(days: 1))) &&
            tarefa.dataPrevista!.isBefore(limite))
        .toList()
      ..sort((a, b) => a.dataPrevista!.compareTo(b.dataPrevista!));
  }

  double get progresso {
    if (tarefas.isEmpty) return 0;
    return concluidas / tarefas.length;
  }

  int get total => tarefas.length;
  int get concluidas =>
      tarefas.where((t) => t.status == StatusTarefa.concluida).length;
  int get pendentes =>
      tarefas.where((t) => t.status != StatusTarefa.concluida).length;

  void reset() {
    unawaited(_tarefasSubscription?.cancel());
    _tarefasSubscription = null;
    tarefas.clear();
    usuarios.clear();
  }

  @override
  void onClose() {
    unawaited(_tarefasSubscription?.cancel());
    super.onClose();
  }
}
