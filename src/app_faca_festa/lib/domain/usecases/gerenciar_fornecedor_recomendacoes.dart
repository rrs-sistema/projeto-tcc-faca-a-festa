import '../../data/models/fornecedor/fornecedor_recomendacao_model.dart';
import '../repositories/fornecedor_recomendacao_repository.dart';

class GerenciarFornecedorRecomendacoes {
  GerenciarFornecedorRecomendacoes(this.repository);

  final FornecedorRecomendacaoRepository repository;

  Future<List<FornecedorRecomendacaoModel>> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    required int limite,
  }) {
    return repository.carregarRecomendacoesSalvas(
      idEvento: idEvento,
      idUsuario: idUsuario,
      limite: limite,
    );
  }

  Future<List<FornecedorRecomendacaoModel>> gerarRecomendacoes({
    required String idEvento,
    required int limite,
    required bool modoDemo,
  }) {
    return repository.gerarRecomendacoes(
      idEvento: idEvento,
      limite: limite,
      modoDemo: modoDemo,
    );
  }

  Future<void> registrarInteracao({
    required String idEvento,
    required String idFornecedor,
    required String acao,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return repository.registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: acao,
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }
}
