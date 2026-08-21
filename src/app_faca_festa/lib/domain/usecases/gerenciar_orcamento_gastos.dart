import '../../data/models/orcamento/orcamento_gasto_model.dart';
import '../../data/models/orcamento/orcamento_validacao_resultado.dart';
import '../repositories/orcamento_gasto_repository.dart';

class GerenciarOrcamentoGastos {
  GerenciarOrcamentoGastos(this.repository);

  final OrcamentoGastoRepository repository;

  Stream<List<OrcamentoGastoModel>> observarGastos(String idOrcamento) {
    return repository.observarGastos(idOrcamento);
  }

  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) {
    return repository.adicionarGasto(
      idOrcamento: idOrcamento,
      nome: nome,
      custo: custo,
      pago: pago,
    );
  }

  Future<void> marcarComoPago({
    required String idOrcamento,
    required String idGasto,
    required double valorTotal,
  }) {
    return repository.marcarComoPago(
      idOrcamento: idOrcamento,
      idGasto: idGasto,
      valorTotal: valorTotal,
    );
  }

  Future<void> removerGasto({
    required String idOrcamento,
    required String idGasto,
  }) {
    return repository.removerGasto(
      idOrcamento: idOrcamento,
      idGasto: idGasto,
    );
  }
}
