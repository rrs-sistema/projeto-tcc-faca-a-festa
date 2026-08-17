import 'package:flutter/foundation.dart';

import './../datasources/remote/gift_remote_datasource.dart';
import './../../domain/entities/gift/gift_contribution.dart';
import './../datasources/local/gift_local_datasource.dart';
import './../../domain/repositories/gift_repository.dart';
import './../models/gift/gif_local_converte.dart';
import './../../core/database/app_database.dart';
import './../../domain/entities/gift/gift.dart';
import './../models/gift/gift_model.dart';

class GiftRepositoryImpl implements GiftRepository {
  final GiftLocalDatasource local;
  final GiftRemoteDatasource remote;

  bool _syncing = false;

  GiftRepositoryImpl({
    required this.local,
    required this.remote,
  });

  @override
  Stream<List<Gift>> getGifts(String eventoId) {
    return local.watchGifts(eventoId).map(
          (list) => list.map((e) => e.toEntity()).toList(),
        );
  }

  @override
  Future<void> createGift(String eventoId, Gift gift) async {
    final model = GiftModel.fromEntity(gift);

    final companion = model.toCompanion(
      eventoId: eventoId,
      synced: false,
      deleted: false,
      updatedAtOverride: DateTime.now(),
    );

    await local.saveGift(companion);

    final saved = await local.getGift(model.id);
    if (saved != null) {
      await _trySyncRemote(saved);
    }
  }

  @override
  Future<void> updateGift(String eventoId, Gift gift) async {
    final model = GiftModel.fromEntity(gift);

    final existing = await local.getGift(model.id);

    final updated = model.toCompanion(
      eventoId: eventoId,
      synced: false,
      deleted: existing?.deleted ?? false,
      updatedAtOverride: DateTime.now(),
    );

    await local.saveGift(updated);

    final saved = await local.getGift(model.id);
    if (saved != null) {
      await _trySyncRemote(saved);
    }
  }

  @override
  Future<void> deleteGift(String eventoId, String giftId) async {
    final gift = await local.getGift(giftId);
    if (gift == null) return;

    await local.markDeleted(giftId);

    final updated = await local.getGift(giftId);
    if (updated != null) {
      await _trySyncRemote(updated);
    }
  }

  @override
  Future<bool> reservarGift(
    String eventoId,
    String giftId,
    String nome,
    String uid,
  ) async {
    final gift = await local.getGift(giftId);
    if (gift == null || gift.status != 'disponivel') return false;

    await local.updateReservation(
      giftId: giftId,
      status: 'reservado',
      reservadoPor: nome,
      reservadoUid: uid,
      dataReserva: DateTime.now(),
      synced: false,
    );

    final updated = await local.getGift(giftId);
    if (updated != null) {
      await _trySyncRemote(updated);
    }

    return true;
  }

  @override
  Future<void> contribuirPix(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) async {
    final gift = await local.getGift(giftId);
    if (gift == null) return;

    await local.updateValorArrecadado(
      giftId: giftId,
      valorArrecadado: gift.valorArrecadado + contribution.valor,
      synced: false,
    );

    await local.saveContribution(
      eventoId,
      giftId,
      contribution,
    );

    try {
      await remote.saveContribution(eventoId, giftId, contribution);

      final updated = await local.getGift(giftId);
      if (updated != null) {
        await _trySyncRemote(updated);
      }
    } catch (_) {}
  }

  Future<void> _trySyncRemote(GiftLocal localGift) async {
    if (_syncing) return;
    _syncing = true;

    try {
      if (localGift.deleted) {
        await remote.deleteGift(localGift.eventoId, localGift.giftId);
      } else {
        await remote.createGift(localGift.eventoId, localGift.toModel());
      }

      await local.markSynced(localGift.giftId);
    } catch (e) {
      if (kDebugMode) {
        print('Erro sync gift ${localGift.giftId}: $e');
      }
    } finally {
      _syncing = false;
    }
  }
}
