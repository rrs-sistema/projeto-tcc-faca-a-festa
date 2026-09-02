import 'package:drift/drift.dart';

import './../../../domain/entities/gift/gift_contribution.dart';
import './../../../core/database/app_database.dart';

class GiftLocalDatasource {
  final AppDatabase db;

  GiftLocalDatasource(this.db);

  Stream<List<GiftLocal>> watchGifts(String eventoId) {
    final query = (db.select(db.giftLocals)
      ..where((t) => t.eventoId.equals(eventoId) & t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]));
    return query.watch();
  }

  Future<GiftLocal?> getGift(String giftId) {
    return (db.select(db.giftLocals)..where((t) => t.giftId.equals(giftId)))
        .getSingleOrNull();
  }

  Future<void> saveGift(GiftLocalsCompanion gift) async {
    final table = db.giftLocals;

    await db.into(table).insert(
          gift,
          onConflict: DoUpdate(
            (_) => gift,
            target: [table.giftId],
          ),
        );
  }

  Future<void> saveAll(List<GiftLocalsCompanion> gifts) async {
    if (gifts.isEmpty) return;

    final table = db.giftLocals;

    await db.batch((batch) {
      for (final gift in gifts) {
        batch.insert(
          table,
          gift,
          onConflict: DoUpdate(
            (_) => gift,
            target: [table.giftId],
          ),
        );
      }
    });
  }

  Future<void> deleteGift(int id) async {
    await (db.delete(db.giftLocals)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markDeleted(String giftId) async {
    await (db.update(db.giftLocals)..where((t) => t.giftId.equals(giftId)))
        .write(
      GiftLocalsCompanion(
        deleted: const Value(true),
        synced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<GiftLocal>> getUnsynced() {
    return (db.select(db.giftLocals)..where((t) => t.synced.equals(false)))
        .get();
  }

  Future<void> markSynced(String giftId) async {
    await (db.update(db.giftLocals)..where((t) => t.giftId.equals(giftId)))
        .write(
      const GiftLocalsCompanion(
        synced: Value(true),
      ),
    );
  }

  Future<void> clear() async {
    await db.delete(db.giftLocals).go();
  }

  Future<void> updateReservation({
    required String giftId,
    required String status,
    required String reservadoPor,
    required String reservadoUid,
    required DateTime dataReserva,
    required bool synced,
  }) async {
    await (db.update(db.giftLocals)..where((t) => t.giftId.equals(giftId)))
        .write(
      GiftLocalsCompanion(
        status: Value(status),
        reservadoPor: Value(reservadoPor),
        reservadoUid: Value(reservadoUid),
        dataReserva: Value(dataReserva),
        synced: Value(synced),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateValorArrecadado({
    required String giftId,
    required double valorArrecadado,
    required bool synced,
  }) async {
    await (db.update(db.giftLocals)..where((t) => t.giftId.equals(giftId)))
        .write(
      GiftLocalsCompanion(
        valorArrecadado: Value(valorArrecadado),
        synced: Value(synced),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> saveContribution(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) async {
    final table = db.giftContributionLocals;

    final row = GiftContributionLocalsCompanion(
      contributionId: Value(contribution.id),
      eventoId: Value(eventoId),
      giftId: Value(giftId),
      nome: Value(contribution.nome),
      uid: Value(contribution.uid),
      valor: Value(contribution.valor),
      mensagem: Value(contribution.mensagem),
      createdAt: Value(contribution.data),
      synced: const Value(false),
    );

    await db.into(table).insert(
          row,
          onConflict: DoUpdate(
            (_) => row,
            target: [table.contributionId],
          ),
        );
  }

  Future<List<GiftContributionLocal>> getUnsyncedContributions() {
    return (db.select(db.giftContributionLocals)
          ..where((t) => t.synced.equals(false)))
        .get();
  }

  Future<void> markContributionSynced(String contributionId) async {
    await (db.update(db.giftContributionLocals)
          ..where((t) => t.contributionId.equals(contributionId)))
        .write(
      const GiftContributionLocalsCompanion(
        synced: Value(true),
      ),
    );
  }
}
