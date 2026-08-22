import '../../data/models/cotacao/cotacao_model.dart';

abstract interface class CotacaoRepository {
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario);

  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  });
}
