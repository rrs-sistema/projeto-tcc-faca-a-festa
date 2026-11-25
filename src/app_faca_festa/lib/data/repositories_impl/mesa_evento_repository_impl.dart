import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/mesa_evento.dart';
import 'package:app_faca_festa/domain/repositories/mesa_evento_repository.dart';

import '../datasources/remote/mesa_evento_remote_datasource.dart';
import '../models/evento/mesa_evento_model.dart';

class MesaEventoRepositoryImpl implements MesaEventoRepository {
  MesaEventoRepositoryImpl(this.remote);

  final MesaEventoRemoteDatasource remote;

  @override
  Stream<List<MesaEvento>> observarMesas(String idEvento) =>
      remote.observarMesas(idEvento);

  @override
  Future<List<MesaEvento>> buscarMesas(String idEvento) =>
      remote.buscarMesas(idEvento);

  @override
  Future<void> salvarMesa(MesaEvento mesa) {
    return UpdateOperations.run(() async {
      return remote.salvarMesa(
        mesa is MesaEventoModel ? mesa : MesaEventoModel.fromEntity(mesa),
      );
    });
  }

  @override
  Future<void> excluirMesa(
    String idMesa, {
    String? idEvento,
    bool desvincularConvidados = true,
  }) {
    return UpdateOperations.run(() async {
      return remote.excluirMesa(
        idMesa,
        idEvento: idEvento,
        desvincularConvidados: desvincularConvidados,
      );
    });
  }

  @override
  Future<void> atualizarOcupacao({
    required String idMesa,
    required int totalOcupados,
  }) {
    return UpdateOperations.run(() async {
      return remote.atualizarOcupacao(
        idMesa: idMesa,
        totalOcupados: totalOcupados,
      );
    });
  }
}
