import '../repositories/avaliacao_servico_repository.dart';

class GerenciarAvaliacoesServico {
  GerenciarAvaliacoesServico(this.repository);

  final AvaliacaoServicoRepository repository;

  Stream<List<Map<String, dynamic>>> observarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  }) {
    return repository.observarAvaliacoesServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
    );
  }

  Future<double> getMediaServico({
    required String idFornecedor,
    required String idServico,
  }) {
    return repository.getMediaServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
    );
  }

  Future<void> adicionarAvaliacaoServico({
    required String idFornecedor,
    required String idServico,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) {
    return repository.adicionarAvaliacaoServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
      idCliente: idCliente,
      nomeCliente: nomeCliente,
      nota: nota,
      comentario: comentario,
      idEvento: idEvento,
      nomeEvento: nomeEvento,
    );
  }

  Stream<List<Map<String, dynamic>>> observarAvaliacoesFornecedor(
    String idFornecedor,
  ) {
    return repository.observarAvaliacoesFornecedor(idFornecedor);
  }

  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) {
    return repository.adicionarAvaliacaoFornecedor(
      idFornecedor: idFornecedor,
      idCliente: idCliente,
      nomeCliente: nomeCliente,
      nota: nota,
      comentario: comentario,
      idEvento: idEvento,
      nomeEvento: nomeEvento,
    );
  }

  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) {
    return repository.podeAvaliarFornecedor(
      idFornecedor: idFornecedor,
      idEvento: idEvento,
      idUsuario: idUsuario,
    );
  }

  Future<bool> podeAvaliarCotacao({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) {
    return repository.podeAvaliarCotacao(
      idFornecedor: idFornecedor,
      idEvento: idEvento,
      idUsuario: idUsuario,
    );
  }
}
