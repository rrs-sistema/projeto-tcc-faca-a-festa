import '../entities/evento_admin.dart';

abstract class EventosAdminRepository {
  Future<List<EventoAdmin>> listarEventosComTipo();

  Future<void> aprovarEvento(String id);

  Future<void> excluirEvento(String id);
}
