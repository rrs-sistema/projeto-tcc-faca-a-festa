import '../../domain/repositories/cotacao_repository.dart';
import '../datasources/remote/cotacao_remote_datasource.dart';
import '../models/cotacao/cotacao_chat_model.dart';
import '../models/cotacao/cotacao_model.dart';

class CotacaoRepositoryImpl implements CotacaoRepository {
  CotacaoRepositoryImpl(this.remote);

  final CotacaoRemoteDatasource remote;

  @override
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario) {
    return remote.observarMinhasCotacoes(idUsuario);
  }

  @override
  Stream<bool> observarCotacaoTemResposta(String idCotacao) {
    return remote.observarCotacaoTemResposta(idCotacao);
  }

  @override
  Stream<List<CotacaoConversaModel>> observarConversasFornecedor(
    String idFornecedor,
  ) {
    return remote.observarConversasFornecedor(idFornecedor);
  }

  @override
  Stream<List<CotacaoMensagemModel>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return remote.observarMensagens(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  @override
  Stream<List<CotacaoFornecedorResumoModel>> observarFornecedoresDaCotacao(
    String idCotacao,
  ) {
    return remote.observarFornecedoresDaCotacao(idCotacao);
  }

  @override
  Stream<List<CotacaoServicoResumoModel>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return remote.observarServicosFornecedorCotacao(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  @override
  Future<CotacaoConversaModel?> buscarConversaFornecedor({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return remote.buscarConversaFornecedor(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
    );
  }

  @override
  Future<void> marcarMensagensComoLidas({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
  }) {
    return remote.marcarMensagensComoLidas(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
    );
  }

  @override
  Future<void> enviarMensagem({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
    required String nomeUsuario,
    required String mensagem,
  }) {
    return remote.enviarMensagem(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
      nomeUsuario: nomeUsuario,
      mensagem: mensagem,
    );
  }

  @override
  Future<String> criarCotacao({
    required String idEvento,
    required String categoriaNome,
    required String observacao,
    required double valorEstimadoTotal,
    required DateTime dataLimiteResposta,
    required List<String> fornecedoresSelecionados,
    required List<Map<String, dynamic>> servicos,
  }) {
    return remote.criarCotacao(
      idEvento: idEvento,
      categoriaNome: categoriaNome,
      observacao: observacao,
      valorEstimadoTotal: valorEstimadoTotal,
      dataLimiteResposta: dataLimiteResposta,
      fornecedoresSelecionados: fornecedoresSelecionados,
      servicos: servicos,
    );
  }

  @override
  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    String? observacaoFornecedor,
  }) {
    return remote.responderCotacao(
      idCotacao: idCotacao,
      aceitou: aceitou,
      prazoEntrega: prazoEntrega,
      condicaoPagamento: condicaoPagamento,
      observacaoFornecedor: observacaoFornecedor,
    );
  }

  @override
  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  }) {
    return remote.confirmarFornecedorEscolhido(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      nomeFornecedor: nomeFornecedor,
      idSolicitante: idSolicitante,
      nomeSolicitante: nomeSolicitante,
    );
  }
}
