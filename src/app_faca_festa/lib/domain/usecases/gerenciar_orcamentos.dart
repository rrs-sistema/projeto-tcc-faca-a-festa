import '../../data/models/orcamento/orcamento_model.dart';
import '../repositories/orcamento_repository.dart';

class GerenciarOrcamentos {
  GerenciarOrcamentos(this.repository);

  final OrcamentoRepository repository;

  Future<OrcamentoModel?> buscarPorId(String idOrcamento) {
    return repository.buscarPorId(idOrcamento);
  }

  Stream<List<OrcamentoModel>> observarOrcamentosDoEvento(String idEvento) {
    return repository.observarOrcamentosDoEvento(idEvento);
  }

  Stream<List<OrcamentoModel>> observarOrcamentosDoFornecedor(
    String idFornecedor,
  ) {
    return repository.observarOrcamentosDoFornecedor(idFornecedor);
  }

  Future<void> criarOrcamento(OrcamentoModel model) {
    return repository.criarOrcamento(model);
  }

  Future<void> confirmarReserva({
    required String idOrcamento,
    required double? custoEstimado,
    required String? anotacoes,
    required DateTime? dataReserva,
    required StatusOrcamento status,
  }) {
    return repository.confirmarReserva(
      idOrcamento: idOrcamento,
      custoEstimado: custoEstimado,
      anotacoes: anotacoes,
      dataReserva: dataReserva,
      status: status,
    );
  }

  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    required bool fechar,
  }) {
    return repository.responderOrcamento(
      idOrcamento: idOrcamento,
      custoEstimado: custoEstimado,
      anotacoes: anotacoes,
      fechar: fechar,
    );
  }

  Future<void> excluirOrcamento(String idOrcamento) {
    return repository.excluirOrcamento(idOrcamento);
  }
}
