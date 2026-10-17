import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/repositories/convidado_repository.dart';
import '../datasources/remote/convidado_remote_datasource.dart';
import '../models/convidado/convidado_model.dart';

class ConvidadoRepositoryImpl implements ConvidadoRepository {
  ConvidadoRepositoryImpl(this.remote);

  final ConvidadoRemoteDatasource remote;

  @override
  Future<Convidado?> buscarPorId(String idConvidado) {
    return UpdateOperations.run(() async {
      return remote.buscarPorId(idConvidado);
    });
  }

  @override
  Future<Convidado?> buscarPrimeiroPorEvento(String idEvento) {
    return UpdateOperations.run(() async {
      return remote.buscarPrimeiroPorEvento(idEvento);
    });
  }

  @override
  Future<Convidado?> buscarPorToken(String token) {
    return UpdateOperations.run(() async {
      return remote.buscarPorToken(token);
    });
  }

  @override
  Stream<List<Convidado>> observarPorEvento(String idEvento) {
    return remote.observarPorEvento(idEvento);
  }

  @override
  Future<void> salvar(Convidado convidado) {
    return UpdateOperations.run(() async {
      final model = convidado is ConvidadoModel
          ? convidado
          : ConvidadoModel.fromEntity(convidado);
      return remote.salvar(model);
    });
  }

  @override
  Future<void> excluir(String idConvidado) {
    return UpdateOperations.run(() async {
      return remote.excluir(idConvidado);
    });
  }

  @override
  Future<void> atualizarStatus(
    String idConvidado,
    StatusConvidado status,
    DateTime dataResposta,
  ) {
    return UpdateOperations.run(() async {
      return remote.atualizarStatus(idConvidado, status, dataResposta);
    });
  }

  @override
  Future<MigracaoTipoConvidadoResultado> migrarTiposLegados() {
    return UpdateOperations.run(() async {
      return remote.migrarTiposLegados();
    });
  }

  @override
  Future<void> garantirTokensConvite(Map<String, String> tokensPorId) {
    return UpdateOperations.run(() async {
      return remote.garantirTokensConvite(tokensPorId);
    });
  }
}
