import '../entities/evento_admin.dart';
import '../repositories/eventos_admin_repository.dart';

class GerenciarEventosAdmin {
  GerenciarEventosAdmin(this.repository);

  final EventosAdminRepository repository;

  Future<List<EventoAdmin>> listarEventosComTipo() {
    return repository.listarEventosComTipo();
  }

  Future<void> aprovarEvento(String id) {
    return repository.aprovarEvento(id);
  }

  Future<void> excluirEvento(String id) {
    return repository.excluirEvento(id);
  }

  Future<List<FornecedorSugestaoAdmin>> sugerirFornecedores({
    required String idEvento,
    int limite = 5,
  }) {
    return repository.sugerirFornecedores(idEvento: idEvento, limite: limite);
  }

  Future<FollowUpComercial> marcarFollowUp({
    required String idEvento,
    String nota = '',
    DateTime? proximoContato,
  }) {
    return repository.marcarFollowUp(
      idEvento: idEvento,
      nota: nota,
      proximoContato: proximoContato,
    );
  }

  Future<void> limparFollowUp(String idEvento) {
    return repository.limparFollowUp(idEvento);
  }

  Future<({NudgeCotacao nudge, List<FornecedorSugestaoAdmin> recomendacoes})>
      enviarNudgeOrganizador({
    required String idEvento,
    String? mensagem,
    bool gerarRecomendacoes = true,
  }) {
    return repository.enviarNudgeOrganizador(
      idEvento: idEvento,
      mensagem: mensagem,
      gerarRecomendacoes: gerarRecomendacoes,
    );
  }
}
