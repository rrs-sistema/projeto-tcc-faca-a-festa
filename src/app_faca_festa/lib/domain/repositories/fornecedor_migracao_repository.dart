class FornecedorMigracaoException implements Exception {
  FornecedorMigracaoException(this.message);

  final String message;
}

abstract interface class FornecedorMigracaoRepository {
  Future<Map<String, dynamic>> migrarTiposEventoFornecedores({
    required bool dryRun,
    required bool aplicar,
    required bool sobrescrever,
    required int limite,
  });
}
