import '../entities/avaliacao.dart';
import '../entities/avaliacao_servico.dart';

abstract class AvaliacaoServicoRepository {
  Stream<List<AvaliacaoServico>> observarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  });

  Future<double> getMediaServico({
    required String idFornecedor,
    required String idServico,
  });

  Future<void> adicionarAvaliacaoServico({
    required String idFornecedor,
    required String idServico,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  });

  Stream<List<Avaliacao>> observarAvaliacoesFornecedor(
    String idFornecedor,
  );

  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  });

  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  });

  Future<bool> podeAvaliarCotacao({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  });
}
