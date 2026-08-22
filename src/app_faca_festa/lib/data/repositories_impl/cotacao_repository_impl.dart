import '../../domain/repositories/cotacao_repository.dart';
import '../datasources/remote/cotacao_remote_datasource.dart';

class CotacaoRepositoryImpl implements CotacaoRepository {
  CotacaoRepositoryImpl(this.remote);

  final CotacaoRemoteDatasource remote;

  @override
  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  }) {
    return remote.confirmarFornecedorEscolhido(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      nomeFornecedor: nomeFornecedor,
      idSolicitante: idSolicitante,
      nomeSolicitante: nomeSolicitante,
    );
  }
}
