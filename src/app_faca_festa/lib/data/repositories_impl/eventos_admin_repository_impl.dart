import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/domain/repositories/eventos_admin_repository.dart';
import '../datasources/remote/eventos_admin_remote_datasource.dart';

class EventosAdminRepositoryImpl implements EventosAdminRepository {
  EventosAdminRepositoryImpl(this.remote);

  final EventosAdminRemoteDatasource remote;

  @override
  Future<List<EventoAdmin>> listarEventosComTipo() {
    return UpdateOperations.run(() async {
      return remote.listarEventosComTipo();
    });
  }

  @override
  Future<void> aprovarEvento(String id) {
    return UpdateOperations.run(() async {
      return remote.aprovarEvento(id);
    });
  }

  @override
  Future<void> excluirEvento(String id) {
    return UpdateOperations.run(() async {
      return remote.excluirEvento(id);
    });
  }

  @override
  Future<List<FornecedorSugestaoAdmin>> sugerirFornecedores({
    required String idEvento,
    int limite = 5,
  }) {
    return UpdateOperations.run(() async {
      return remote.sugerirFornecedores(idEvento: idEvento, limite: limite);
    });
  }

  @override
  Future<FollowUpComercial> marcarFollowUp({
    required String idEvento,
    String nota = '',
    DateTime? proximoContato,
  }) {
    return UpdateOperations.run(() async {
      return remote.marcarFollowUp(
        idEvento: idEvento,
        nota: nota,
        proximoContato: proximoContato,
      );
    });
  }

  @override
  Future<void> limparFollowUp(String idEvento) {
    return UpdateOperations.run(() async {
      return remote.limparFollowUp(idEvento);
    });
  }

  @override
  Future<({NudgeCotacao nudge, List<FornecedorSugestaoAdmin> recomendacoes})>
      enviarNudgeOrganizador({
    required String idEvento,
    String? mensagem,
    bool gerarRecomendacoes = true,
  }) {
    return UpdateOperations.run(() async {
      return remote.enviarNudgeOrganizador(
        idEvento: idEvento,
        mensagem: mensagem,
        gerarRecomendacoes: gerarRecomendacoes,
      );
    });
  }
}
