import 'package:drift/drift.dart';

import './../../data/models/gift/gift_contribution_local.dart';
import './../../data/models/gift/gift_local.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [GiftLocals, GiftContributionLocals])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
