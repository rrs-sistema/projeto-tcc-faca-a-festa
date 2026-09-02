import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/tarefa_repository.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';

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
  StreamSubscription<List<Convidado>>? _convidadosSubscription;
  String _idEventoUsuarios = '';

  EventoController get eventoController => Get.find<EventoController>();

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
      erro.value = '';
      final idEvento = _idEventoAtual();
      if (idEvento.isEmpty) {
        usuarios.clear();
        _idEventoUsuarios = '';
        await _convidadosSubscription?.cancel();
        _convidadosSubscription = null;
        return;
      }

      if (_idEventoUsuarios == idEvento && _convidadosSubscription != null) {
        usuarios.assignAll(
          _montarElegiveis(
            [...usuarios, ..._convidadosDoEvento(idEvento)],
            idEvento: idEvento,
          ),
        );
        return;
      }

      await _convidadosSubscription?.cancel();
      _idEventoUsuarios = idEvento;

      final primeiro = Completer<void>();
      _convidadosSubscription =
          _convidadoRepository.observarPorEvento(idEvento).listen(
        (lista) {
          usuarios.assignAll(_montarElegiveis(lista, idEvento: idEvento));
          if (!primeiro.isCompleted) primeiro.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          erro.value = 'Erro ao carregar usuários: $error';
          if (!primeiro.isCompleted) primeiro.complete();
        },
      );

      await primeiro.future;
      if (usuarios.isEmpty) {
        usuarios.assignAll(
          _montarElegiveis(_convidadosDoEvento(idEvento), idEvento: idEvento),
        );
      }
    } catch (e) {
      erro.value = 'Erro ao carregar usuários: $e';
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

  String _idEventoAtual() {
    final doEvento =
        eventoController.eventoAtualEntidade?.idEvento.trim() ?? '';
    if (doEvento.isNotEmpty) return doEvento;
    if (Get.isRegistered<ConvidadoController>()) {
      return Get.find<ConvidadoController>().idEventoAtual.value.trim();
    }
    return '';
  }

  List<Convidado> _convidadosDoEvento(String idEvento) {
    if (!Get.isRegistered<ConvidadoController>()) return const [];
    final controller = Get.find<ConvidadoController>();
    if (controller.idEventoAtual.value.trim() != idEvento) return const [];
    return controller.convidados.toList();
  }

  List<Convidado> _montarElegiveis(
    List<Convidado> convidados, {
    String? idEvento,
  }) {
    final lista = [...convidados, ..._convidadosDoEvento(idEvento ?? '')];
    _incluirOrganizador(lista, idEvento ?? '');

    final vistos = <String>{};
    final elegiveis = <Convidado>[];
    for (final item in lista) {
      if (!item.podeSerResponsavelTarefa) continue;
      final chave = item.idConvidado.trim().isNotEmpty
          ? 'id:${item.idConvidado.trim()}'
          : 'email:${item.emailNormalizadoEfetivo}';
      if (chave.endsWith(':') || !vistos.add(chave)) continue;
      elegiveis.add(item);
    }
    return elegiveis;
  }

  void _incluirOrganizador(List<Convidado> convidados, String idEvento) {
    if (!Get.isRegistered<AppController>()) return;
    final user = Get.find<AppController>().usuarioLogado.value;
    if (user == null || user.idUsuario.trim().isEmpty) return;
    if (_jaRepresentaUsuario(convidados, user)) return;

    final agora = DateTime.now();
    convidados.insert(
      0,
      Convidado(
        idConvidado: user.idUsuario,
        idEvento: idEvento,
        nome: user.nome,
        contato: user.email,
        email: user.email,
        emailUsuario: user.email,
        emailNormalizado: Convidado.normalizarEmail(user.email),
        status: StatusConvidado.confirmado,
        cuidadoEspecial: false,
        dataCadastro: agora,
        dataAtualizacao: agora,
        idUsuario: user.idUsuario,
        conviteStatus: 'vinculado',
      ),
    );
  }

  bool _jaRepresentaUsuario(List<Convidado> convidados, Usuario user) {
    final uid = user.idUsuario.trim();
    final email = Convidado.normalizarEmail(user.email);
    return convidados.any((item) {
      if (uid.isNotEmpty &&
          (item.idConvidado.trim() == uid || item.idUsuario?.trim() == uid)) {
        return true;
      }
      return email.isNotEmpty && item.emailDaConta == email;
    });
  }

  void reset() {
    unawaited(_tarefasSubscription?.cancel());
    unawaited(_convidadosSubscription?.cancel());
    _tarefasSubscription = null;
    _convidadosSubscription = null;
    _idEventoUsuarios = '';
    tarefas.clear();
    usuarios.clear();
  }

  Future<void> encerrarEscutas() async {
    await _tarefasSubscription?.cancel();
    await _convidadosSubscription?.cancel();
    _tarefasSubscription = null;
    _convidadosSubscription = null;
    _idEventoUsuarios = '';
    tarefas.clear();
    usuarios.clear();
  }

  @override
  void onClose() {
    unawaited(_tarefasSubscription?.cancel());
    unawaited(_convidadosSubscription?.cancel());
    super.onClose();
  }
}
