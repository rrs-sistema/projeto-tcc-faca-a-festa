import '../entities/cotacao.dart';

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
  Stream<List<Cotacao>> observarSolicitacoesFornecedor(String idFornecedor);

  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  });
}
