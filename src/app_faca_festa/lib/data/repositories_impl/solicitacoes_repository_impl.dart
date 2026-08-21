import '../../domain/repositories/solicitacoes_repository.dart';
import '../datasources/remote/solicitacoes_remote_datasource.dart';
import '../models/cotacao/cotacao_model.dart';

class SolicitacoesRepositoryImpl implements SolicitacoesRepository {
  SolicitacoesRepositoryImpl(this.remote);

  final SolicitacoesRemoteDatasource remote;

  @override
  Stream<List<CotacaoModel>> observarSolicitacoesFornecedor(
    String idFornecedor,
  ) {
    return remote.observarSolicitacoesFornecedor(idFornecedor);
  }

  @override
  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  }) {
    return remote.cancelarCotacao(
      idCotacao: idCotacao,
      canceladoPor: canceladoPor,
    );
  }
}
