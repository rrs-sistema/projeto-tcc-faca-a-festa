import '../../domain/repositories/orcamentos_admin_repository.dart';
import '../datasources/remote/orcamentos_admin_remote_datasource.dart';
import '../models/admin/orcamento_admin_model.dart';

class OrcamentosAdminRepositoryImpl implements OrcamentosAdminRepository {
  OrcamentosAdminRepositoryImpl(this.remote);

  final OrcamentosAdminRemoteDatasource remote;

  @override
  Future<List<OrcamentoAdminModel>> listarOrcamentosComEventoDetalhes() {
    return remote.listarOrcamentosComEventoDetalhes();
  }
}
