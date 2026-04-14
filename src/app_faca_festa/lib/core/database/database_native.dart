import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

Future<AppDatabase> constructDb() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'faca_festa.sqlite'));

  return AppDatabase(
    NativeDatabase.createInBackground(file),
  );
}
