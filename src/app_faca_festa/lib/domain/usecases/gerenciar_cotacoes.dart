import '../../data/models/cotacao/cotacao_model.dart';
import '../repositories/cotacao_repository.dart';

class GerenciarCotacoes {
  GerenciarCotacoes(this.repository);

  final CotacaoRepository repository;

  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario) {
    return repository.observarMinhasCotacoes(idUsuario);
  }

  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  }) {
    return repository.confirmarFornecedorEscolhido(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      nomeFornecedor: nomeFornecedor,
      idSolicitante: idSolicitante,
      nomeSolicitante: nomeSolicitante,
    );
  }
}
