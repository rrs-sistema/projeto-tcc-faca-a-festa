import '../../domain/repositories/orcamento_gasto_repository.dart';
import '../datasources/remote/orcamento_gasto_remote_datasource.dart';
import '../models/orcamento/orcamento_gasto_model.dart';
import '../models/orcamento/orcamento_validacao_resultado.dart';

class OrcamentoGastoRepositoryImpl implements OrcamentoGastoRepository {
  OrcamentoGastoRepositoryImpl(this.remote);

  final OrcamentoGastoRemoteDatasource remote;

  @override
  Stream<List<OrcamentoGastoModel>> observarGastos(String idOrcamento) {
    return remote.observarGastos(idOrcamento);
  }

  @override
  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) {
    return remote.adicionarGasto(
      idOrcamento: idOrcamento,
      nome: nome,
      custo: custo,
      pago: pago,
    );
  }

  @override
  Future<void> marcarComoPago({
    required String idOrcamento,
    required String idGasto,
    required double valorTotal,
  }) {
    return remote.marcarComoPago(
      idOrcamento: idOrcamento,
      idGasto: idGasto,
      valorTotal: valorTotal,
    );
  }

  @override
  Future<void> removerGasto({
    required String idOrcamento,
    required String idGasto,
  }) {
    return remote.removerGasto(
      idOrcamento: idOrcamento,
      idGasto: idGasto,
    );
  }
}
