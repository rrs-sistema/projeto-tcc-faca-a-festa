import '../entities/fornecedor_recomendacao.dart';

abstract class FornecedorRecomendacaoRepository {
  Future<List<FornecedorRecomendacao>> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    required int limite,
  });

  Future<List<FornecedorRecomendacao>> gerarRecomendacoes({
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
