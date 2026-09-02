import 'package:drift/drift.dart';

class GiftContributionLocals extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get contributionId => text().unique()();
  TextColumn get eventoId => text()();
  TextColumn get giftId => text()();
  TextColumn get nome => text()();
  TextColumn get uid => text().nullable()();

  RealColumn get valor => real().withDefault(const Constant(0.0))();
  TextColumn get mensagem => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
