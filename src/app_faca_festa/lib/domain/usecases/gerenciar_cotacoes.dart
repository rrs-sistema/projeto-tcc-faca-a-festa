import '../../data/models/cotacao/cotacao_chat_model.dart';
import '../../data/models/cotacao/cotacao_model.dart';
import '../repositories/cotacao_repository.dart';

class GerenciarCotacoes {
  GerenciarCotacoes(this.repository);

  final CotacaoRepository repository;

  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario) {
    return repository.observarMinhasCotacoes(idUsuario);
  }

  Stream<bool> observarCotacaoTemResposta(String idCotacao) {
    return repository.observarCotacaoTemResposta(idCotacao);
  }

  Stream<List<CotacaoConversaModel>> observarConversasFornecedor(
    String idFornecedor,
  ) {
    return repository.observarConversasFornecedor(idFornecedor);
  }

  Stream<List<CotacaoMensagemModel>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return repository.observarMensagens(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  Stream<List<CotacaoFornecedorResumoModel>> observarFornecedoresDaCotacao(
    String idCotacao,
  ) {
    return repository.observarFornecedoresDaCotacao(idCotacao);
  }

  Stream<List<CotacaoServicoResumoModel>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return repository.observarServicosFornecedorCotacao(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  Future<CotacaoConversaModel?> buscarConversaFornecedor({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return repository.buscarConversaFornecedor(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  Future<void> marcarMensagensComoLidas({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
  }) {
    return repository.marcarMensagensComoLidas(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
    );
  }

  Future<void> enviarMensagem({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
    required String nomeUsuario,
    required String mensagem,
  }) {
    return repository.enviarMensagem(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
      nomeUsuario: nomeUsuario,
      mensagem: mensagem,
    );
  }

  Future<String> criarCotacao({
    required String idEvento,
    required String categoriaNome,
    required String observacao,
    required double valorEstimadoTotal,
    required DateTime dataLimiteResposta,
    required List<String> fornecedoresSelecionados,
    required List<Map<String, dynamic>> servicos,
  }) {
    return repository.criarCotacao(
      idEvento: idEvento,
      categoriaNome: categoriaNome,
      observacao: observacao,
      valorEstimadoTotal: valorEstimadoTotal,
      dataLimiteResposta: dataLimiteResposta,
      fornecedoresSelecionados: fornecedoresSelecionados,
      servicos: servicos,
    );
  }

  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    String? observacaoFornecedor,
  }) {
    return repository.responderCotacao(
      idCotacao: idCotacao,
      aceitou: aceitou,
      prazoEntrega: prazoEntrega,
      condicaoPagamento: condicaoPagamento,
      observacaoFornecedor: observacaoFornecedor,
    );
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
