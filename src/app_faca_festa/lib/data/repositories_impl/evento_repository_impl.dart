import '../../domain/repositories/evento_repository.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/tipo_evento.dart';
import '../datasources/remote/evento_remote_ds.dart';
import '../models/evento/evento_model.dart' show EventoModel;

class EventoRepositoryImpl implements EventoRepository {
  EventoRepositoryImpl(this.remote);

  final EventoRemoteDatasource remote;

  @override
  Future<Evento?> buscarPorId(String idEvento) {
    return remote.buscarPorId(idEvento);
  }

  @override
  Future<Evento?> buscarUltimoPorUsuario(String idUsuario) {
    return remote.buscarUltimoPorUsuario(idUsuario);
  }

  @override
  Stream<Evento?> observarUltimoPorUsuario(String idUsuario) {
    return remote.observarUltimoPorUsuario(idUsuario);
  }

  @override
  Stream<Evento?> observarPorId(String idEvento) {
    return remote.observarPorId(idEvento);
  }

  @override
  Future<TipoEvento?> buscarTipoPorId(String idTipoEvento) {
    return remote.buscarTipoPorId(idTipoEvento);
  }

  @override
  Future<List<TipoEvento>> listarTiposAtivos() {
    return remote.listarTiposAtivos();
  }

  @override
  Future<void> salvar(Evento evento) {
    final model =
        evento is EventoModel ? evento : EventoModel.fromEntity(evento);
    return remote.salvar(model);
  }

  @override
  Future<String> enviarCapa({
    required String idEvento,
    required List<int> bytes,
  }) {
    return remote.enviarCapa(idEvento: idEvento, bytes: bytes);
  }

  @override
  Future<void> removerArquivoCapa(String idEvento) {
    return remote.removerArquivoCapa(idEvento);
  }

  @override
  Future<void> atualizarImagemCapa({
    required String idEvento,
    String? imagemCapaUrl,
  }) {
    return remote.atualizarImagemCapa(
      idEvento: idEvento,
      imagemCapaUrl: imagemCapaUrl,
    );
  }

  @override
  Future<void> atualizarRotuloBanner({
    required String idEvento,
    String? rotuloBanner,
  }) {
    return remote.atualizarRotuloBanner(
      idEvento: idEvento,
      rotuloBanner: rotuloBanner,
    );
  }

  @override
  Future<void> excluir(String idEvento) {
    return remote.excluir(idEvento);
  }

  @override
  Stream<List<Evento>> listarPorUsuario(String idUsuario) {
    return remote.listarPorUsuario(idUsuario);
  }
}
