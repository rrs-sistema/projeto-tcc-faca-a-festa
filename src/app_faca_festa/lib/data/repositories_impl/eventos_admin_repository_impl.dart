import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/domain/repositories/eventos_admin_repository.dart';
import '../datasources/remote/eventos_admin_remote_datasource.dart';

class EventosAdminRepositoryImpl implements EventosAdminRepository {
  EventosAdminRepositoryImpl(this.remote);

  final EventosAdminRemoteDatasource remote;

  @override
  Future<List<EventoAdmin>> listarEventosComTipo() {
    return UpdateOperations.run(() async {
      return remote.listarEventosComTipo();
    });
  }

  @override
  Future<void> aprovarEvento(String id) {
    return UpdateOperations.run(() async {
      return remote.aprovarEvento(id);
    });
  }

  @override
  Future<void> excluirEvento(String id) {
    return UpdateOperations.run(() async {
      return remote.excluirEvento(id);
    });
  }
}
