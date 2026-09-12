import '../entities/cotacao.dart';
import '../entities/cotacao_chat.dart';

abstract interface class CotacaoRepository {
  Stream<List<Cotacao>> observarMinhasCotacoes(String idUsuario);

  Stream<bool> observarCotacaoTemResposta(String idCotacao);

  Stream<List<CotacaoConversa>> observarConversasFornecedor(
    String idFornecedor,
  );

  Stream<List<CotacaoMensagem>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  });

  Stream<List<CotacaoFornecedorResumo>> observarFornecedoresDaCotacao(
    String idCotacao,
  );

  Stream<List<CotacaoServicoResumo>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  });

  Future<CotacaoConversa?> buscarConversaFornecedor({
    required String idCotacao,
    required String idFornecedor,
  });

  Future<void> marcarMensagensComoLidas({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
  });

  Future<void> enviarMensagem({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
    required String nomeUsuario,
    required String mensagem,
  });

  Future<String> criarCotacao({
    required String idEvento,
    required String categoriaNome,
    required String observacao,
    required double valorEstimadoTotal,
    required DateTime dataLimiteResposta,
    required List<String> fornecedoresSelecionados,
    required List<ItemServicoCotacao> servicos,
  });

  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    String? observacaoFornecedor,
  });

  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  });
}
