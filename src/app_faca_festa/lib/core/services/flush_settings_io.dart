import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> flushSettings(Map<String, dynamic> snapshot) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, 'GetStorage.gs'));
  final actual = jsonDecode(await file.readAsString());
  if (!const DeepCollectionEquality().equals(actual, snapshot)) {
    throw StateError('Configurações ainda não foram gravadas no disco.');
  }
  final handle = await file.open(mode: FileMode.append);
  try {
    await handle.flush();
  } finally {
    await handle.close();
  }
  // Explicit awaited backup, unlike GetStorage's fire-and-forget backup.
  await File(p.join(directory.path, 'GetStorage.bak'))
      .writeAsString(jsonEncode(snapshot), flush: true);
}
