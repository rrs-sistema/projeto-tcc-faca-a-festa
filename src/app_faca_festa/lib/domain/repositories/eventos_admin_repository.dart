import '../entities/evento_admin.dart';

abstract class EventosAdminRepository {
  Future<List<EventoAdmin>> listarEventosComTipo();

  Future<void> aprovarEvento(String id);

  Future<void> excluirEvento(String id);

  Future<List<FornecedorSugestaoAdmin>> sugerirFornecedores({
    required String idEvento,
    int limite = 5,
  });

  Future<FollowUpComercial> marcarFollowUp({
    required String idEvento,
    String nota = '',
    DateTime? proximoContato,
  });

  Future<void> limparFollowUp(String idEvento);

  Future<({NudgeCotacao nudge, List<FornecedorSugestaoAdmin> recomendacoes})>
      enviarNudgeOrganizador({
    required String idEvento,
    String? mensagem,
    bool gerarRecomendacoes = true,
  });
}
