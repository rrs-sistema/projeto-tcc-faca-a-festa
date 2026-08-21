import '../../domain/repositories/avaliacao_servico_repository.dart';
import '../datasources/remote/avaliacao_servico_remote_datasource.dart';

class AvaliacaoServicoRepositoryImpl implements AvaliacaoServicoRepository {
  AvaliacaoServicoRepositoryImpl(this.remote);

  final AvaliacaoServicoRemoteDatasource remote;

  @override
  Stream<List<Map<String, dynamic>>> observarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  }) {
    return remote.observarAvaliacoesServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
    );
  }

  @override
  Future<double> getMediaServico({
    required String idFornecedor,
    required String idServico,
  }) {
    return remote.getMediaServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
    );
  }

  @override
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
    return remote.adicionarAvaliacaoServico(
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

  @override
  Stream<List<Map<String, dynamic>>> observarAvaliacoesFornecedor(
    String idFornecedor,
  ) {
    return remote.observarAvaliacoesFornecedor(idFornecedor);
  }

  @override
  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) {
    return remote.adicionarAvaliacaoFornecedor(
      idFornecedor: idFornecedor,
      idCliente: idCliente,
      nomeCliente: nomeCliente,
      nota: nota,
      comentario: comentario,
      idEvento: idEvento,
      nomeEvento: nomeEvento,
    );
  }

  @override
  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) {
    return remote.podeAvaliarFornecedor(
      idFornecedor: idFornecedor,
      idEvento: idEvento,
      idUsuario: idUsuario,
    );
  }

  @override
  Future<bool> podeAvaliarCotacao({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) {
    return remote.podeAvaliarCotacao(
      idFornecedor: idFornecedor,
      idEvento: idEvento,
      idUsuario: idUsuario,
    );
  }
}
