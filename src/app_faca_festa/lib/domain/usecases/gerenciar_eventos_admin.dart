import '../../data/models/admin/evento_com_tipo_model.dart';
import '../repositories/eventos_admin_repository.dart';

class GerenciarEventosAdmin {
  GerenciarEventosAdmin(this.repository);

  final EventosAdminRepository repository;

  Future<List<EventoComTipoModel>> listarEventosComTipo() {
    return repository.listarEventosComTipo();
  }

  Future<void> aprovarEvento(String id) {
    return repository.aprovarEvento(id);
  }

  Future<void> excluirEvento(String id) {
    return repository.excluirEvento(id);
  }
}
