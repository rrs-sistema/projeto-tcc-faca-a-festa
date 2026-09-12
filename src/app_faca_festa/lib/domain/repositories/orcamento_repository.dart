import '../entities/orcamento.dart';

abstract class OrcamentoRepository {
  Future<Orcamento?> buscarPorId(String idOrcamento);

  Stream<List<Orcamento>> observarOrcamentosDoEvento(String idEvento);

  Stream<List<Orcamento>> observarOrcamentosDoFornecedor(
    String idFornecedor,
  );

  Future<void> criarOrcamento(Orcamento orcamento);

  Future<void> confirmarReserva({
    required String idOrcamento,
    required double? custoEstimado,
    required String? anotacoes,
    required DateTime? dataReserva,
    required StatusOrcamento status,
  });

  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    required bool fechar,
  });

  Future<void> excluirOrcamento(String idOrcamento);
}
