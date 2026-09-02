import 'package:cloud_functions/cloud_functions.dart';

class FornecedorMigracaoRemoteDatasource {
  FornecedorMigracaoRemoteDatasource({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> migrarTiposEventoFornecedores({
    required bool dryRun,
    required bool aplicar,
    required bool sobrescrever,
    required int limite,
  }) async {
    final warmupCallable = _functions.httpsCallable(
      'atualizarFornecedoresTiposEventoManual',
    );
    await warmupCallable.call({
      'dryRun': true,
      'aplicar': false,
      'sobrescrever': true,
      'limparCache': false,
    });

    final callable = _functions.httpsCallable(
      'atualizarFornecedoresTiposEventoManual',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 120),
      ),
    );

    final response = await callable.call({
      'dryRun': dryRun,
      'aplicar': aplicar,
      'sobrescrever': sobrescrever,
      'limite': limite,
    });

    return Map<String, dynamic>.from(response.data as Map);
  }
}
