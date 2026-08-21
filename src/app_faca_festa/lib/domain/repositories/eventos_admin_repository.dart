import '../../data/models/admin/evento_com_tipo_model.dart';

abstract class EventosAdminRepository {
  Future<List<EventoComTipoModel>> listarEventosComTipo();

  Future<void> aprovarEvento(String id);

  Future<void> excluirEvento(String id);
}
