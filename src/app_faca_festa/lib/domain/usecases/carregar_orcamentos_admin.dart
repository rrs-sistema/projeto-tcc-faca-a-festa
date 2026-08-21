import '../../data/models/admin/orcamento_admin_model.dart';
import '../repositories/orcamentos_admin_repository.dart';

class CarregarOrcamentosAdmin {
  CarregarOrcamentosAdmin(this.repository);

  final OrcamentosAdminRepository repository;

  Future<List<OrcamentoAdminModel>> call() {
    return repository.listarOrcamentosComEventoDetalhes();
  }
}
