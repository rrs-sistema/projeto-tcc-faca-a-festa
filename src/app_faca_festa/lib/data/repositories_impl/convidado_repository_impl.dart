import '../../domain/entities/convidado.dart';
import '../../domain/repositories/convidado_repository.dart';
import '../datasources/remote/convidado_remote_datasource.dart';
import '../models/convidado/convidado_model.dart'
    hide Convidado, StatusConvidado, TipoConvidado;

class ConvidadoRepositoryImpl implements ConvidadoRepository {
  ConvidadoRepositoryImpl(this.remote);

  final ConvidadoRemoteDatasource remote;

  @override
  Future<Convidado?> buscarPorId(String idConvidado) {
    return remote.buscarPorId(idConvidado);
  }

  @override
  Future<Convidado?> buscarPrimeiroPorEvento(String idEvento) {
    return remote.buscarPrimeiroPorEvento(idEvento);
  }

  @override
  Future<Convidado?> buscarPorToken(String token) {
    return remote.buscarPorToken(token);
  }

  @override
  Stream<List<Convidado>> observarPorEvento(String idEvento) {
    return remote.observarPorEvento(idEvento);
  }

  @override
  Future<void> salvar(Convidado convidado) {
    final model = convidado is ConvidadoModel
        ? convidado
        : ConvidadoModel.fromEntity(convidado);
    return remote.salvar(model);
  }

  @override
  Future<void> excluir(String idConvidado) {
    return remote.excluir(idConvidado);
  }

  @override
  Future<void> atualizarStatus(
    String idConvidado,
    StatusConvidado status,
    DateTime dataResposta,
  ) {
    return remote.atualizarStatus(idConvidado, status, dataResposta);
  }

  @override
  Future<MigracaoTipoConvidadoResultado> migrarTiposLegados() {
    return remote.migrarTiposLegados();
  }

  @override
  Future<void> garantirTokensConvite(Map<String, String> tokensPorId) {
    return remote.garantirTokensConvite(tokensPorId);
  }
}
