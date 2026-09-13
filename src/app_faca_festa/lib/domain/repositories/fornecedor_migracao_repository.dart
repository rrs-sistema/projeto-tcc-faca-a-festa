import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';

class FornecedorMigracaoException implements Exception {
  FornecedorMigracaoException(this.message);

  final String message;
}

abstract interface class FornecedorMigracaoRepository {
  Future<ResultadoMigracaoTiposEvento> migrarTiposEventoFornecedores({
    required bool dryRun,
    required bool aplicar,
    required bool sobrescrever,
    required int limite,
  });
}
