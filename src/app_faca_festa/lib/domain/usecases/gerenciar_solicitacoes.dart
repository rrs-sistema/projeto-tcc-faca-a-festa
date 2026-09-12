import '../entities/cotacao.dart';
import '../repositories/solicitacoes_repository.dart';

class GerenciarSolicitacoes {
  GerenciarSolicitacoes(this.repository);

  final SolicitacoesRepository repository;

  Stream<List<Cotacao>> observarSolicitacoesFornecedor(
    String idFornecedor,
  ) {
    return repository.observarSolicitacoesFornecedor(idFornecedor);
  }

  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  }) {
    return repository.cancelarCotacao(
      idCotacao: idCotacao,
      canceladoPor: canceladoPor,
    );
  }
}
