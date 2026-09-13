import '../repositories/fornecedor_migracao_repository.dart';
import '../entities/resultados_operacao.dart';

class ExecutarMigracaoFornecedores {
  ExecutarMigracaoFornecedores(this.repository);

  final FornecedorMigracaoRepository repository;

  Future<ResultadoMigracaoTiposEvento> migrarTiposEventoFornecedores({
    required bool dryRun,
    required bool aplicar,
    required bool sobrescrever,
    required int limite,
  }) {
    return repository.migrarTiposEventoFornecedores(
      dryRun: dryRun,
      aplicar: aplicar,
      sobrescrever: sobrescrever,
      limite: limite,
    );
  }
}
