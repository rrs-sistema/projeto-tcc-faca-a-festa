import '../repositories/fornecedor_migracao_repository.dart';

class ExecutarMigracaoFornecedores {
  ExecutarMigracaoFornecedores(this.repository);

  final FornecedorMigracaoRepository repository;

  Future<Map<String, dynamic>> migrarTiposEventoFornecedores({
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
