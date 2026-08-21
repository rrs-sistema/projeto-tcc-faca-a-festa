import '../../data/models/admin/orcamento_admin_model.dart';

abstract class OrcamentosAdminRepository {
  Future<List<OrcamentoAdminModel>> listarOrcamentosComEventoDetalhes();
}
