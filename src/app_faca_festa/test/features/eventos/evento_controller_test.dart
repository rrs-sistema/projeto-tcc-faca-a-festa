import 'package:app_faca_festa/controllers/evento_controller.dart';
import 'package:app_faca_festa/data/local/evento_ativo_store.dart';
import 'package:app_faca_festa/data/models/evento/evento_model.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/presentation/coordinators/evento_session_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _EventoRepositoryFake repository;
  late _EventoSessionCoordinatorFake sessionCoordinator;
  late EventoController controller;

  setUp(() {
    repository = _EventoRepositoryFake();
    sessionCoordinator = _EventoSessionCoordinatorFake();
    controller = EventoController(
      repository: repository,
      sessionCoordinator: sessionCoordinator,
    );
  });

  tearDown(() {
    controller.onClose();
  });

  test('buscar por id delegates and returns the existing model', () async {
    final evento = _evento();
    repository.evento = evento;

    final result = await controller.buscarEventoPeloIdEvento('evento-1');

    expect(repository.idBuscado, 'evento-1');
    expect(result, same(evento));
    expect(controller.carregando.value, isFalse);
  });

  test('buscar por id returns a pure domain entity unchanged', () async {
    final evento = Evento(
      idEvento: 'evento-domain',
      idTipoEvento: 'tipo-domain',
      idUsuario: 'usuario-domain',
      nomeEvento: 'Evento de domínio',
      localEvento: 'Local',
      data: DateTime(2026, 12, 23),
    );
    repository.evento = evento;

    final result = await controller.buscarEventoPeloIdEvento('evento-domain');

    expect(result, same(evento));
    expect(result?.idEvento, 'evento-domain');
    expect(result?.nomeEvento, 'Evento de domínio');
  });

  test('buscar por id keeps current null behavior when not found', () async {
    controller.eventoAtual.value = _evento();

    final result = await controller.buscarEventoPeloIdEvento('inexistente');

    expect(result, isNull);
    expect(controller.eventoAtual.value, isNull);
    expect(controller.carregando.value, isFalse);
  });

  test('buscar por id keeps current null behavior on repository error',
      () async {
    repository.error = StateError('failure');

    final result = await controller.buscarEventoPeloIdEvento('evento-1');

    expect(result, isNull);
    expect(controller.carregando.value, isFalse);
  });

  test('save and delete preserve delegation parameters', () async {
    final evento = _evento();

    await controller.salvarEvento(evento);
    await controller.excluirEvento('evento-1');

    expect(repository.eventoSalvo, same(evento));
    expect(repository.idExcluido, 'evento-1');
  });

  test('save accepts a pure domain entity', () async {
    final evento = Evento(
      idEvento: 'evento-domain',
      idTipoEvento: 'tipo-domain',
      idUsuario: 'usuario-domain',
      nomeEvento: 'Evento',
      localEvento: 'Local',
      data: DateTime(2026, 12, 24),
    );

    await controller.salvarEvento(evento);

    expect(repository.eventoSalvo, same(evento));
  });

  test('list by user exposes the repository stream unchanged', () async {
    final evento = _evento();
    repository.eventos = [evento];

    final result = await controller.listarEventosPorUsuario('usuario-1').first;

    expect(repository.usuarioListado, 'usuario-1');
    expect(result, [same(evento)]);
  });

  test('latest event keeps current empty state when none is found', () async {
    controller.eventoAtual.value = _evento();

    await controller.buscarUltimoEvento('usuario-1');

    expect(repository.usuarioUltimoBuscado, 'usuario-1');
    expect(controller.eventoAtual.value, isNull);
    expect(controller.carregando.value, isFalse);
  });

  test('latest event keeps current loading behavior on error', () async {
    repository.latestError = StateError('failure');

    await controller.buscarUltimoEvento('usuario-1');

    expect(repository.usuarioUltimoBuscado, 'usuario-1');
    expect(controller.carregando.value, isFalse);
  });

  test('latest event listener delegates user and clears state on null',
      () async {
    controller.eventoAtual.value = _evento();

    controller.escutarUltimoEvento('usuario-1');
    await Future<void>.delayed(Duration.zero);

    expect(repository.usuarioUltimoObservado, 'usuario-1');
    expect(controller.eventoAtual.value, isNull);
  });

  test('event document listener exposes updates for presentation', () async {
    final inicial = _evento();
    final atualizado = Evento(
      idEvento: 'evento-1',
      idTipoEvento: 'tipo-1',
      idUsuario: 'usuario-1',
      nomeEvento: 'Festa atualizada',
      localEvento: 'Novo salão',
      data: DateTime(2026, 12, 21),
      mensagemConvidado: 'Bem-vindo',
    );
    repository.eventoObservadoRetorno = atualizado;

    await controller.escutarEventoPorId(
      'evento-1',
      eventoInicial: inicial,
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.eventoObservado, 'evento-1');
    expect(controller.eventoAtual.value, same(atualizado));
    expect(controller.eventoAtual.value?.mensagemConvidado, 'Bem-vindo');
  });

  test('event type keeps current empty behavior when not found', () async {
    await controller.buscarTipoEvento('tipo-inexistente');

    expect(repository.tipoBuscado, 'tipo-inexistente');
    expect(controller.tipoEventoAtual.value, isNull);
  });

  test('event type keeps the pure domain entity returned by repository',
      () async {
    const tipoEvento = TipoEvento(
      idTipoEvento: 'tipo-domain',
      nome: 'Formatura',
    );
    repository.tipoEvento = tipoEvento;

    await controller.buscarTipoEvento('tipo-domain');

    expect(repository.tipoBuscado, 'tipo-domain');
    expect(controller.tipoEventoAtual.value, same(tipoEvento));
    expect(sessionCoordinator.temasAplicados, ['Formatura']);
  });

  test('initializing a found event delegates related modules', () async {
    final evento = _evento();
    repository.evento = evento;

    await controller.buscarUltimoEvento('usuario-1');

    expect(sessionCoordinator.eventoInicializado, same(evento));
    expect(sessionCoordinator.cancelamentos, 1);
    expect(controller.eventoAtual.value, same(evento));
    expect(controller.eventoAtualEntidade, same(controller.eventoAtual.value));
  });

  test('full session cleanup clears event and event type', () {
    final evento = Evento(
      idEvento: 'evento-domain',
      idTipoEvento: 'tipo-domain',
      idUsuario: 'usuario-domain',
      nomeEvento: 'Evento de domínio',
      localEvento: 'Local',
      data: DateTime(2026, 12, 26),
    );
    controller.eventoAtual.value = evento;
    const tipoEvento = TipoEvento(
      idTipoEvento: 'tipo-1',
      nome: 'Casamento',
    );
    controller.tipoEventoAtual.value = tipoEvento;

    expect(controller.eventoAtualEntidade, same(evento));
    expect(controller.tipoEventoAtualEntidade, same(tipoEvento));

    controller.limparSessaoAtual();

    expect(controller.eventoAtual.value, isNull);
    expect(controller.tipoEventoAtual.value, isNull);
  });

  test('list by user activates the nearest upcoming event', () async {
    final longe = _evento(
      id: 'evento-longe',
      nome: 'Festa distante',
      data: DateTime(2028, 12, 20),
      cadastro: DateTime(2026, 8, 1),
    );
    final perto = _evento(
      id: 'evento-perto',
      nome: 'Festa próxima',
      data: DateTime(2026, 9, 1),
      cadastro: DateTime(2026, 1, 1),
    );
    repository.eventos = [longe, perto];

    await controller.carregarEventosDoUsuario('usuario-1');

    expect(repository.usuarioListado, 'usuario-1');
    expect(controller.eventoAtual.value?.idEvento, 'evento-perto');
    expect(sessionCoordinator.eventoInicializado?.idEvento, 'evento-perto');
  });

  test('list by user prefers the nearest event over a stored one', () async {
    controller.onClose();
    final store = MemoriaEventoAtivoStore();
    controller = EventoController(
      repository: repository,
      sessionCoordinator: sessionCoordinator,
      eventoAtivoStore: store,
    );
    final longe = _evento(
      id: 'evento-longe',
      nome: 'Festa distante',
      data: DateTime(2028, 12, 20),
      cadastro: DateTime(2026, 8, 1),
    );
    final perto = _evento(
      id: 'evento-perto',
      nome: 'Festa próxima',
      data: DateTime(2026, 9, 1),
      cadastro: DateTime(2026, 3, 1),
    );
    repository.eventos = [longe, perto];
    store.salvar('usuario-1', 'evento-longe');

    await controller.carregarEventosDoUsuario('usuario-1');

    expect(controller.eventoAtual.value?.idEvento, 'evento-perto');
    expect(sessionCoordinator.eventoInicializado, same(perto));
  });

  test('nearest upcoming event prefers a future date over a past one', () {
    final passado = _evento(
      id: 'evento-passado',
      data: DateTime(2025, 1, 10),
    );
    final futuro = _evento(
      id: 'evento-futuro',
      data: DateTime(2027, 6, 30),
    );

    final escolhido = EventoController.eventoMaisProximo([passado, futuro]);

    expect(escolhido.idEvento, 'evento-futuro');
  });

  test('list by user with no events leaves the session empty', () async {
    repository.eventos = const [];

    await controller.carregarEventosDoUsuario('usuario-1');

    expect(controller.eventoAtual.value, isNull);
    expect(controller.eventosDoUsuario, isEmpty);
    expect(sessionCoordinator.eventoInicializado, isNull);
  });

  test('selecting another event cancels the previous session', () async {
    final primeiro = _evento(id: 'evento-1', nome: 'Primeiro');
    final segundo = _evento(id: 'evento-2', nome: 'Segundo');
    repository.evento = primeiro;

    await controller.buscarUltimoEvento('usuario-1');
    await controller.selecionarEvento(segundo);

    expect(controller.eventoAtual.value?.idEvento, 'evento-2');
    expect(sessionCoordinator.eventoInicializado, same(segundo));
    expect(sessionCoordinator.cancelamentos, 2);
  });

  test('selecting the current event does not reinitialize modules', () async {
    final evento = _evento();
    repository.evento = evento;

    await controller.buscarUltimoEvento('usuario-1');
    final cancelamentos = sessionCoordinator.cancelamentos;

    await controller.selecionarEvento(evento);

    expect(sessionCoordinator.cancelamentos, cancelamentos);
    expect(controller.eventoAtual.value, same(evento));
  });

  test('empty user list does not clear a freshly selected event', () async {
    final evento = _evento(id: 'evento-novo', nome: 'Formatura do Rivaldo');
    await controller.selecionarEvento(evento);
    repository.eventos = const [];

    await controller.carregarEventosDoUsuario('usuario-1');

    expect(controller.eventoAtual.value?.idEvento, 'evento-novo');
    expect(controller.eventoAtual.value?.nomeEvento, 'Formatura do Rivaldo');
  });
}

EventoModel _evento({
  String id = 'evento-1',
  String nome = 'Festa',
  DateTime? data,
  DateTime? cadastro,
}) {
  return EventoModel(
    idEvento: id,
    idTipoEvento: 'tipo-1',
    idUsuario: 'usuario-1',
    nomeEvento: nome,
    localEvento: 'Salão',
    data: data ?? DateTime(2026, 12, 20),
    dataCadastro: cadastro,
  );
}

class _EventoRepositoryFake implements EventoRepository {
  Evento? evento;
  TipoEvento? tipoEvento;
  Object? error;
  Object? latestError;
  String? idBuscado;
  String? usuarioUltimoBuscado;
  String? usuarioUltimoObservado;
  String? eventoObservado;
  String? tipoBuscado;
  Evento? eventoSalvo;
  String? idExcluido;
  String? usuarioListado;
  List<Evento> eventos = const [];
  Evento? eventoObservadoRetorno;

  @override
  Future<Evento?> buscarPorId(String idEvento) async {
    idBuscado = idEvento;
    if (error case final repositoryError?) {
      throw repositoryError;
    }
    return evento;
  }

  @override
  Future<Evento?> buscarUltimoPorUsuario(String idUsuario) async {
    usuarioUltimoBuscado = idUsuario;
    if (latestError case final repositoryError?) {
      throw repositoryError;
    }
    return evento;
  }

  @override
  Stream<Evento?> observarUltimoPorUsuario(String idUsuario) {
    usuarioUltimoObservado = idUsuario;
    return Stream.value(evento);
  }

  @override
  Stream<Evento?> observarPorId(String idEvento) {
    eventoObservado = idEvento;
    final retorno = eventoObservadoRetorno;
    return retorno == null ? const Stream.empty() : Stream.value(retorno);
  }

  @override
  Future<TipoEvento?> buscarTipoPorId(String idTipoEvento) async {
    tipoBuscado = idTipoEvento;
    return tipoEvento;
  }

  @override
  Future<List<TipoEvento>> listarTiposAtivos() async {
    return const [];
  }

  @override
  Future<void> salvar(Evento evento) async {
    eventoSalvo = evento;
  }

  @override
  Future<void> atualizarImagemCapa({
    required String idEvento,
    String? imagemCapaUrl,
  }) async {}

  @override
  Future<void> atualizarRotuloBanner({
    required String idEvento,
    String? rotuloBanner,
  }) async {}

  @override
  Future<void> excluir(String idEvento) async {
    idExcluido = idEvento;
  }

  @override
  Stream<List<Evento>> listarPorUsuario(String idUsuario) {
    usuarioListado = idUsuario;
    return Stream.value(eventos);
  }
}

class _EventoSessionCoordinatorFake implements EventoSessionCoordinator {
  Evento? eventoInicializado;
  int cancelamentos = 0;
  final temasAplicados = <String>[];

  @override
  void aplicarTema(String nomeTipoEvento, {Evento? evento}) {
    temasAplicados.add(nomeTipoEvento);
  }

  @override
  Future<void> inicializarModulosRelacionados(Evento evento) async {
    eventoInicializado = evento;
  }

  @override
  Future<void> cancelar() async {
    cancelamentos++;
  }
}
