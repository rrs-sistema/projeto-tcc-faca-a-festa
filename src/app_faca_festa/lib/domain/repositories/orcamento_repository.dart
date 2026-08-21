import '../../data/models/orcamento/orcamento_model.dart';

abstract class OrcamentoRepository {
  Stream<List<OrcamentoModel>> observarOrcamentosDoEvento(String idEvento);

  Stream<List<OrcamentoModel>> observarOrcamentosDoFornecedor(
    String idFornecedor,
  );

  Future<void> criarOrcamento(OrcamentoModel model);

  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    required bool fechar,
  });

  Future<void> excluirOrcamento(String idOrcamento);
}
