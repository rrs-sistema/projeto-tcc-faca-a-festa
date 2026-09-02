import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

Future<AppDatabase> constructDb() async {
  final result = await WasmDatabase.open(
    databaseName: 'faca_festa_db',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  );

  debugPrint(
      '🌐 Drift Web implementação escolhida: ${result.chosenImplementation}');

  if (result.missingFeatures.isNotEmpty) {
    debugPrint('⚠️ Drift Web recursos ausentes: ${result.missingFeatures}');
  }

  return AppDatabase(result.resolvedExecutor);
}
