import '../../data/models/cotacao/cotacao_model.dart';

abstract class SolicitacoesRepository {
  Stream<List<CotacaoModel>> observarSolicitacoesFornecedor(
      String idFornecedor);

  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  });
}
