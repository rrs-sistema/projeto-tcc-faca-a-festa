import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/admin/eventos_admin_controller.dart';
import 'package:app_faca_festa/data/models/admin/evento_com_tipo_model.dart';
import 'package:app_faca_festa/domain/repositories/eventos_admin_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_eventos_admin.dart';

void main() {
  late _EventosAdminRepositoryFake repository;
  late EventosAdminController controller;

  setUp(() {
    Get.testMode = true;
    repository = _EventosAdminRepositoryFake();
    controller = EventosAdminController(
      eventosAdmin: GerenciarEventosAdmin(repository),
    );
  });

  tearDown(Get.reset);

  test('loads events through the use case and keeps derived indicators',
      () async {
    repository.eventos = [
      _evento(
        id: 'evento-1',
        nome: 'Casamento Ana',
        tipoNome: 'Casamento',
        cidade: 'Maringa',
        status: 'confirmado',
      ),
      _evento(
        id: 'evento-2',
        nome: 'Formatura Joao',
        tipoNome: 'Formatura',
        cidade: 'Londrina',
        status: 'finalizado',
      ),
    ];

    await controller.carregarEventosComTipo();

    expect(controller.eventos, hasLength(2));
    expect(controller.totalAtivos, 1);
    expect(controller.erro.value, isEmpty);
    expect(controller.carregando.value, isFalse);
  });

  test('filters events by name, type, city or organizer', () async {
    repository.eventos = [
      _evento(
        id: 'evento-1',
        nome: 'Casamento Ana',
        tipoNome: 'Casamento',
        cidade: 'Maringa',
        organizador: 'Ana Souza',
      ),
      _evento(
        id: 'evento-2',
        nome: 'Aniversario Pedro',
        tipoNome: 'Festa infantil',
        cidade: 'Curitiba',
        organizador: 'Pedro Lima',
      ),
    ];

    await controller.carregarEventosComTipo();
    controller.busca.value = 'infantil';

    expect(controller.eventosFiltrados, hasLength(1));
    expect(controller.eventosFiltrados.first.id, 'evento-2');
  });

  test('approves event through the use case', () async {
    final evento = _evento(id: 'evento-1', nome: 'Casamento Ana');

    await controller.acaoEvento('aprovar', evento);

    expect(repository.eventosAprovados, ['evento-1']);
  });

  test('deletes event through the use case and removes it locally', () async {
    controller.eventos.assignAll([
      _evento(id: 'evento-1', nome: 'Casamento Ana'),
      _evento(id: 'evento-2', nome: 'Formatura Joao'),
    ]);

    await controller.excluirEvento('evento-1');

    expect(repository.eventosExcluidos, ['evento-1']);
    expect(controller.eventos.map((e) => e.id), ['evento-2']);
  });

  test('stores user-facing loading error when repository fails', () async {
    repository.error = StateError('failure');

    await controller.carregarEventosComTipo();

    expect(controller.eventos, isEmpty);
    expect(controller.erro.value, startsWith('Erro ao carregar eventos:'));
    expect(controller.carregando.value, isFalse);
  });
}

EventoComTipoModel _evento({
  required String id,
  required String nome,
  String tipoNome = 'Casamento',
  String organizador = 'Organizador',
  String? cidade,
  String status = 'confirmado',
}) {
  return EventoComTipoModel(
    id: id,
    nome: nome,
    tipoNome: tipoNome,
    organizador: organizador,
    cidade: cidade,
    status: status,
  );
}

class _EventosAdminRepositoryFake implements EventosAdminRepository {
  List<EventoComTipoModel> eventos = [];
  final eventosAprovados = <String>[];
  final eventosExcluidos = <String>[];
  Object? error;

  @override
  Future<List<EventoComTipoModel>> listarEventosComTipo() async {
    final currentError = error;
    if (currentError != null) throw currentError;
    return eventos;
  }

  @override
  Future<void> aprovarEvento(String id) async {
    eventosAprovados.add(id);
  }

  @override
  Future<void> excluirEvento(String id) async {
    eventosExcluidos.add(id);
  }
}
