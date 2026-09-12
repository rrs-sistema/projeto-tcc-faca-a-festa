import '../entities/orcamento_admin.dart';

abstract class OrcamentosAdminRepository {
  Future<List<OrcamentoAdmin>> listarOrcamentosComEventoDetalhes();
}
