import '../../domain/repositories/orcamento_repository.dart';
import '../datasources/remote/orcamento_remote_datasource.dart';
import '../models/orcamento/orcamento_model.dart';

class OrcamentoRepositoryImpl implements OrcamentoRepository {
  OrcamentoRepositoryImpl(this.remote);

  final OrcamentoRemoteDatasource remote;

  @override
  Stream<List<OrcamentoModel>> observarOrcamentosDoEvento(String idEvento) {
    return remote.observarOrcamentosDoEvento(idEvento);
  }

  @override
  Stream<List<OrcamentoModel>> observarOrcamentosDoFornecedor(
    String idFornecedor,
  ) {
    return remote.observarOrcamentosDoFornecedor(idFornecedor);
  }

  @override
  Future<void> criarOrcamento(OrcamentoModel model) {
    return remote.criarOrcamento(model);
  }

  @override
  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    required bool fechar,
  }) {
    return remote.responderOrcamento(
      idOrcamento: idOrcamento,
      custoEstimado: custoEstimado,
      anotacoes: anotacoes,
      fechar: fechar,
    );
  }

  @override
  Future<void> excluirOrcamento(String idOrcamento) {
    return remote.excluirOrcamento(idOrcamento);
  }
}
