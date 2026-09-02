import '../../data/models/cotacao/cotacao_model.dart';

class SolicitacaoNaoEncontradaException implements Exception {
  const SolicitacaoNaoEncontradaException();
}

class SolicitacaoNaoCancelavelException implements Exception {
  const SolicitacaoNaoCancelavelException(this.status);

  final String status;
}

class SolicitacaoSemFornecedorException implements Exception {
  const SolicitacaoSemFornecedorException();
}

abstract class SolicitacoesRepository {
  Stream<List<CotacaoModel>> observarSolicitacoesFornecedor(
      String idFornecedor);

  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  });
}
