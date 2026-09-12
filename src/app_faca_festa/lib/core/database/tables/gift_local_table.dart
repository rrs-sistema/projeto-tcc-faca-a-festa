import 'package:drift/drift.dart';

class GiftLocals extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get giftId => text().unique()();
  TextColumn get eventoId => text()();
  TextColumn get nome => text()();

  TextColumn get descricao => text().nullable()();
  TextColumn get categoria => text().nullable()();
  TextColumn get tipo => text()();

  RealColumn get valor => real().nullable()();
  RealColumn get valorArrecadado => real().withDefault(const Constant(0.0))();
  RealColumn get metaValor => real().nullable()();

  TextColumn get loja => text().nullable()();
  TextColumn get link => text().nullable()();
  TextColumn get pix => text().nullable()();
  TextColumn get imagem => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('disponivel'))();

  TextColumn get reservadoPor => text().nullable()();
  TextColumn get reservadoUid => text().nullable()();
  DateTimeColumn get dataReserva => dateTime().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
