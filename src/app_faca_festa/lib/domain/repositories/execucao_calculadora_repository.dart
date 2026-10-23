import '../services/plano_execucao_service.dart';

abstract interface class ExecucaoCalculadoraRepository {
  Future<ContextoExecucaoPlano> carregarContextoExecucao(String evento);

  /// false significa pedido já aplicado; preserva o resultado anterior.
  Future<bool> aplicarPlanoExecucao(PropostaExecucaoPlano proposta);
}
