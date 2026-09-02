import '../../data/models/cotacao/cotacao_chat_model.dart';
import '../../data/models/cotacao/cotacao_model.dart';

abstract interface class CotacaoRepository {
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario);

  Stream<bool> observarCotacaoTemResposta(String idCotacao);

  Stream<List<CotacaoConversaModel>> observarConversasFornecedor(
    String idFornecedor,
  );

  Stream<List<CotacaoMensagemModel>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  });

  Stream<List<CotacaoFornecedorResumoModel>> observarFornecedoresDaCotacao(
    String idCotacao,
  );

  Stream<List<CotacaoServicoResumoModel>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  });

  Future<CotacaoConversaModel?> buscarConversaFornecedor({
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
    required List<Map<String, dynamic>> servicos,
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
