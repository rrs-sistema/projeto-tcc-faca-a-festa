import 'package:drift/wasm.dart';

import 'app_database.dart';

Future<AppDatabase> constructDb() async {
  final result = await WasmDatabase.open(
    databaseName: 'faca_festa_db',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  );

  return AppDatabase(result.resolvedExecutor);
}
