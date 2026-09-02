import 'dart:async';

import 'package:app_faca_festa/presentation/modules/convidado/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/domain/repositories/convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/tarefa_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TarefaRepositoryFake repository;
  late TarefaController controller;

  setUp(() {
    repository = _TarefaRepositoryFake();
    controller = TarefaController(
      repository: repository,
      convidadoRepository: _ConvidadoRepositoryFake(),
    );
  });

  tearDown(() async {
    controller.onClose();
    await repository.close();
  });

  test('task listener exposes repository entities and progress', () async {
    await controller.listenTarefas('evento-1');
    repository.stream.add([
      _tarefa('Pendente'),
      _tarefa('Concluída', id: 'tarefa-2', status: StatusTarefa.concluida),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(repository.eventoObservado, 'evento-1');
    expect(repository.ordenarPorData, isFalse);
    expect(controller.total, 2);
    expect(controller.concluidas, 1);
    expect(controller.pendentes, 1);
    expect(controller.progresso, 0.5);
  });

  test('add, edit, status and delete preserve repository operations', () async {
    final tarefa = _tarefa('Comprar bebidas');

    await controller.adicionarTarefa(
      nome: 'Comprar bebidas',
      idEvento: 'evento-1',
      idResponsavel: 'convidado-1',
    );
    await controller.editarTarefa(tarefa);
    await controller.atualizarStatus('tarefa-1', StatusTarefa.concluida);
    await controller.excluirTarefa('tarefa-1');

    expect(repository.adicionada?.titulo, 'Comprar bebidas');
    expect(repository.adicionada?.idEvento, 'evento-1');
    expect(repository.atualizada, same(tarefa));
    expect(repository.status, StatusTarefa.concluida);
    expect(repository.idExcluido, 'tarefa-1');
  });

  test('repository errors keep the existing controller error message',
      () async {
    repository.falharAtualizacao = true;

    await controller.editarTarefa(_tarefa('Comprar bebidas'));

    expect(controller.erro.value, contains('Erro ao editar tarefa'));
  });

  test('status update reports success or failure to the guest screen',
      () async {
    expect(
      await controller.atualizarStatus(
        'tarefa-1',
        StatusTarefa.concluida,
      ),
      isTrue,
    );

    repository.falharStatus = true;
    expect(
      await controller.atualizarStatus(
        'tarefa-1',
        StatusTarefa.aFazer,
      ),
      isFalse,
    );
    expect(controller.erro.value, contains('Erro ao atualizar status'));
  });
}

Tarefa _tarefa(
  String titulo, {
  String id = 'tarefa-1',
  StatusTarefa status = StatusTarefa.aFazer,
}) =>
    Tarefa(
      idTarefa: id,
      idEvento: 'evento-1',
      titulo: titulo,
      status: status,
      dataCadastro: DateTime(2026, 8, 14),
    );

class _TarefaRepositoryFake implements TarefaRepository {
  final stream = StreamController<List<Tarefa>>.broadcast();
  String? eventoObservado;
  bool? ordenarPorData;
  Tarefa? adicionada;
  Tarefa? atualizada;
  StatusTarefa? status;
  String? idExcluido;
  bool falharAtualizacao = false;
  bool falharStatus = false;

  Future<void> close() => stream.close();

  @override
  Stream<List<Tarefa>> observarPorEvento(
    String idEvento, {
    bool ordenarPorData = false,
  }) {
    eventoObservado = idEvento;
    this.ordenarPorData = ordenarPorData;
    return stream.stream;
  }

  @override
  Future<void> adicionar(Tarefa tarefa) async => adicionada = tarefa;

  @override
  Future<void> atualizar(Tarefa tarefa) async {
    if (falharAtualizacao) throw StateError('falha');
    atualizada = tarefa;
  }

  @override
  Future<void> atualizarStatus(String idTarefa, StatusTarefa status) async {
    if (falharStatus) throw StateError('falha');
    this.status = status;
  }

  @override
  Future<void> excluir(String idTarefa) async => idExcluido = idTarefa;
}

class _ConvidadoRepositoryFake implements ConvidadoRepository {
  @override
  Stream<List<Convidado>> observarPorEvento(String idEvento) =>
      Stream.value(const []);

  @override
  Future<Convidado?> buscarPorId(String idConvidado) async => null;

  @override
  Future<Convidado?> buscarPorToken(String token) async => null;

  @override
  Future<Convidado?> buscarPrimeiroPorEvento(String idEvento) async => null;

  @override
  Future<void> atualizarStatus(
    String idConvidado,
    StatusConvidado status,
    DateTime dataResposta,
  ) async {}

  @override
  Future<void> excluir(String idConvidado) async {}

  @override
  Future<void> garantirTokensConvite(Map<String, String> tokensPorId) async {}

  @override
  Future<MigracaoTipoConvidadoResultado> migrarTiposLegados() async =>
      const MigracaoTipoConvidadoResultado(
        totalEncontrados: 0,
        totalAtualizados: 0,
        totalIgnorados: 0,
      );

  @override
  Future<void> salvar(Convidado convidado) async {}
}
