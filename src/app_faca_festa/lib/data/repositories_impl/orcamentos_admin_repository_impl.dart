import 'package:app_faca_festa/domain/entities/orcamento_admin.dart';
import 'package:app_faca_festa/domain/repositories/orcamentos_admin_repository.dart';
import '../datasources/remote/orcamentos_admin_remote_datasource.dart';

class OrcamentosAdminRepositoryImpl implements OrcamentosAdminRepository {
  OrcamentosAdminRepositoryImpl(this.remote);

  final OrcamentosAdminRemoteDatasource remote;

  @override
  Future<List<OrcamentoAdmin>> listarOrcamentosComEventoDetalhes() {
    return remote.listarOrcamentosComEventoDetalhes();
  }
}
