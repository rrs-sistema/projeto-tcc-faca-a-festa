import '../entities/orcamento_admin.dart';
import '../repositories/orcamentos_admin_repository.dart';

class CarregarOrcamentosAdmin {
  CarregarOrcamentosAdmin(this.repository);

  final OrcamentosAdminRepository repository;

  Future<List<OrcamentoAdmin>> call() {
    return repository.listarOrcamentosComEventoDetalhes();
  }
}
