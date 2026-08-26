import '../entities/evento.dart';
import '../entities/tipo_evento.dart';

/// Framework-independent data contract for the Eventos feature.
abstract interface class EventoRepository {
  Future<Evento?> buscarPorId(String idEvento);

  Future<Evento?> buscarUltimoPorUsuario(String idUsuario);

  Stream<Evento?> observarUltimoPorUsuario(String idUsuario);

  Stream<Evento?> observarPorId(String idEvento);

  Future<TipoEvento?> buscarTipoPorId(String idTipoEvento);

  Future<List<TipoEvento>> listarTiposAtivos();

  Future<void> salvar(Evento evento);

  Future<void> atualizarImagemCapa({
    required String idEvento,
    String? imagemCapaUrl,
  });

  Future<void> atualizarRotuloBanner({
    required String idEvento,
    String? rotuloBanner,
  });

  Future<void> excluir(String idEvento);

  Stream<List<Evento>> listarPorUsuario(String idUsuario);
}
