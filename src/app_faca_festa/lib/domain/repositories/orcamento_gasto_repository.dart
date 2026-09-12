import '../entities/orcamento_gasto.dart';
import '../entities/orcamento_validacao_resultado.dart';

abstract class OrcamentoGastoRepository {
  Stream<List<OrcamentoGasto>> observarGastos(String idOrcamento);

  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  });

  Future<void> marcarComoPago({
    required String idOrcamento,
    required String idGasto,
    required double valorTotal,
  });

  Future<void> removerGasto({
    required String idOrcamento,
    required String idGasto,
  });
}
