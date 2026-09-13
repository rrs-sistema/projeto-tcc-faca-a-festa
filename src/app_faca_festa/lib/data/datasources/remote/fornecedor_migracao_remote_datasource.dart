import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';

class FornecedorMigracaoRemoteDatasource {
  FornecedorMigracaoRemoteDatasource({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  Future<ResultadoMigracaoTiposEvento> migrarTiposEventoFornecedores({
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

    return _resultadoMigracaoDeMap(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

ResultadoMigracaoTiposEvento _resultadoMigracaoDeMap(Map<String, dynamic> map) {
  final rawResultados = map['resultados'];
  return ResultadoMigracaoTiposEvento(
    dryRun: map['dryRun'] == true,
    aplicar: map['aplicar'] == true,
    sobrescrever: map['sobrescrever'] == true,
    limparCache: map['limparCache'] == true,
    totalMapeados: _asInt(map['totalMapeados']),
    totalEncontrados: _asInt(map['totalEncontrados']),
    totalAtualizados: _asInt(map['totalAtualizados']),
    totalIgnorados: _asInt(map['totalIgnorados']),
    totalNaoEncontrados: _asInt(map['totalNaoEncontrados']),
    totalCacheRemovido: _asInt(map['totalCacheRemovido']),
    resultados: rawResultados is List
        ? rawResultados
            .whereType<Map>()
            .map((item) => _itemMigracaoDeMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : const [],
  );
}

ItemMigracaoTipoEvento _itemMigracaoDeMap(Map<String, dynamic> map) {
  final nomes = map['tipoEventoNomes'];
  return ItemMigracaoTipoEvento(
    fornecedorId: (map['fornecedorId'] ?? '').toString(),
    nomeEsperado: (map['nomeEsperado'] ?? '').toString(),
    documentId: (map['documentId'] ?? '').toString().trim().isEmpty
        ? null
        : map['documentId'].toString(),
    encontrado: map['encontrado'] == true,
    atualizado: map['atualizado'] == true,
    jaPossuiaTipos: map['jaPossuiaTipos'] == true,
    tipoEventoNomes: nomes is List
        ? nomes.map((item) => item.toString()).toList()
        : const [],
    mensagem: (map['mensagem'] ?? '').toString(),
  );
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
