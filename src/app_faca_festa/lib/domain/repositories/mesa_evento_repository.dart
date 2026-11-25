import '../entities/mesa_evento.dart';

abstract interface class MesaEventoRepository {
  Stream<List<MesaEvento>> observarMesas(String idEvento);

  /// Leitura pontual (evita seed em cima de snapshot vazio transitório).
  Future<List<MesaEvento>> buscarMesas(String idEvento);

  Future<void> salvarMesa(MesaEvento mesa);

  Future<void> excluirMesa(
    String idMesa, {
    String? idEvento,
    bool desvincularConvidados = true,
  });

  Future<void> atualizarOcupacao({
    required String idMesa,
    required int totalOcupados,
  });
}
