import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/domain/repositories/eventos_admin_repository.dart';
import '../datasources/remote/eventos_admin_remote_datasource.dart';

class EventosAdminRepositoryImpl implements EventosAdminRepository {
  EventosAdminRepositoryImpl(this.remote);

  final EventosAdminRemoteDatasource remote;

  @override
  Future<List<EventoAdmin>> listarEventosComTipo() {
    return remote.listarEventosComTipo();
  }

  @override
  Future<void> aprovarEvento(String id) {
    return remote.aprovarEvento(id);
  }

  @override
  Future<void> excluirEvento(String id) {
    return remote.excluirEvento(id);
  }
}
