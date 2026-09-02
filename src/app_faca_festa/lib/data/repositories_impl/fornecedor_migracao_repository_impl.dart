import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/fornecedor_migracao_repository.dart';
import '../datasources/remote/fornecedor_migracao_remote_datasource.dart';

class FornecedorMigracaoRepositoryImpl implements FornecedorMigracaoRepository {
  FornecedorMigracaoRepositoryImpl(this.remote);

  final FornecedorMigracaoRemoteDatasource remote;

  @override
  Future<Map<String, dynamic>> migrarTiposEventoFornecedores({
    required bool dryRun,
    required bool aplicar,
    required bool sobrescrever,
    required int limite,
  }) async {
    try {
      return await remote.migrarTiposEventoFornecedores(
        dryRun: dryRun,
        aplicar: aplicar,
        sobrescrever: sobrescrever,
        limite: limite,
      );
    } on FirebaseFunctionsException catch (e) {
      throw FornecedorMigracaoException(
        e.message ?? 'Erro ao executar migração.',
      );
    }
  }
}
