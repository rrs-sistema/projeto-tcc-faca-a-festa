import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';

import '../../data/models/gift/gift_contribution_local.dart';
import './../../data/models/gift/gift_local.dart';

class IsarDatabase {
  static Isar? _isar;

  static Future<Isar?> init() async {
    if (kIsWeb) {
      return null;
    }

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      //[GiftLocalSchema],
      [GiftContributionLocalSchema, GiftLocalSchema],
      directory: dir.path,
      name: 'db_faca_festa',
    );

    return _isar;
  }

  static Isar? get instance => _isar;
}
