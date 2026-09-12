import 'package:drift/drift.dart';

import 'tables/gift_contribution_local_table.dart';
import 'tables/gift_local_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [GiftLocals, GiftContributionLocals])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
