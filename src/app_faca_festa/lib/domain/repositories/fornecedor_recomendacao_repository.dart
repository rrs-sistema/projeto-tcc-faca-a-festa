import '../../data/models/fornecedor/fornecedor_recomendacao_model.dart';

abstract class FornecedorRecomendacaoRepository {
  Future<List<FornecedorRecomendacaoModel>> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    required int limite,
  });

  Future<List<FornecedorRecomendacaoModel>> gerarRecomendacoes({
    required String idEvento,
    required int limite,
    required bool modoDemo,
  });

  Future<void> registrarInteracao({
    required String idEvento,
    required String idFornecedor,
    required String acao,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  });
}
