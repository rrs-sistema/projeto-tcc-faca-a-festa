import 'package:app_faca_festa/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _EventoRepositoryFake repository;
  late EventoCadastroController controller;

  setUp(() {
    repository = _EventoRepositoryFake();
    controller = EventoCadastroController(repository: repository);
  });

  tearDown(() {
    controller.onClose();
  });

  test('loads active event types from repository unchanged', () async {
    const casamento = TipoEvento(
      idTipoEvento: 'casamento',
      nome: 'Casamento',
    );
    const formatura = TipoEvento(
      idTipoEvento: 'formatura',
      nome: 'Formatura',
    );
    repository.tiposAtivos = [casamento, formatura];

    await controller.carregarTiposEvento();

    expect(controller.tiposEvento, [same(casamento), same(formatura)]);
  });

  test('keeps the current type list when repository loading fails', () async {
    const existente = TipoEvento(
      idTipoEvento: 'existente',
      nome: 'Existente',
    );
    controller.tiposEvento.add(existente);
    repository.error = StateError('failure');

    await controller.carregarTiposEvento();

    expect(controller.tiposEvento, [same(existente)]);
  });
}

class _EventoRepositoryFake implements EventoRepository {
  List<TipoEvento> tiposAtivos = const [];
  Object? error;

  @override
  Future<List<TipoEvento>> listarTiposAtivos() async {
    if (error case final repositoryError?) {
      throw repositoryError;
    }
    return tiposAtivos;
  }

  @override
  Future<Evento?> buscarPorId(String idEvento) async => null;

  @override
  Future<Evento?> buscarUltimoPorUsuario(String idUsuario) async => null;

  @override
  Future<TipoEvento?> buscarTipoPorId(String idTipoEvento) async => null;

  @override
  Future<void> excluir(String idEvento) async {}

  @override
  Stream<List<Evento>> listarPorUsuario(String idUsuario) =>
      const Stream.empty();

  @override
  Stream<Evento?> observarPorId(String idEvento) => const Stream.empty();

  @override
  Stream<Evento?> observarUltimoPorUsuario(String idUsuario) =>
      const Stream.empty();

  @override
  Future<void> salvar(Evento evento) async {}

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
}
