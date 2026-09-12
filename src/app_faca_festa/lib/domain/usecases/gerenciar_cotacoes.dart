import '../entities/cotacao.dart';
import '../entities/cotacao_chat.dart';
import '../repositories/cotacao_repository.dart';

class GerenciarCotacoes {
  GerenciarCotacoes(this.repository);

  final CotacaoRepository repository;

  Stream<List<Cotacao>> observarMinhasCotacoes(String idUsuario) {
    return repository.observarMinhasCotacoes(idUsuario);
  }

  Stream<bool> observarCotacaoTemResposta(String idCotacao) {
    return repository.observarCotacaoTemResposta(idCotacao);
  }

  Stream<List<CotacaoConversa>> observarConversasFornecedor(
    String idFornecedor,
  ) {
    return repository.observarConversasFornecedor(idFornecedor);
  }

  Stream<List<CotacaoMensagem>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return repository.observarMensagens(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  Stream<List<CotacaoFornecedorResumo>> observarFornecedoresDaCotacao(
    String idCotacao,
  ) {
    return repository.observarFornecedoresDaCotacao(idCotacao);
  }

  Stream<List<CotacaoServicoResumo>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return repository.observarServicosFornecedorCotacao(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  Future<CotacaoConversa?> buscarConversaFornecedor({
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
