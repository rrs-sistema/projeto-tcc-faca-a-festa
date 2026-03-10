import 'package:isar/isar.dart';

import './../../../domain/entities/gift/gift_contribution.dart';
import './../../models/gift/gift_contribution_local.dart';
import './../../models/gift/gift_local.dart';

class GiftLocalDatasource {
  final Isar isar;

  GiftLocalDatasource(this.isar);

  // ======================================================
  // STREAM DE PRESENTES
  // ======================================================
  Stream<List<GiftLocal>> watchGifts(String eventoId) {
    return isar.giftLocals.filter().eventoIdEqualTo(eventoId).watch(fireImmediately: true);
  }

  // ======================================================
  // BUSCAR PRESENTE
  // ======================================================
  Future<GiftLocal?> getGift(String giftId) async {
    return isar.giftLocals.filter().giftIdEqualTo(giftId).findFirst();
  }

  // ======================================================
  // SALVAR / ATUALIZAR
  // ======================================================
  Future<void> saveGift(GiftLocal gift) async {
    await isar.writeTxn(() async {
      await isar.giftLocals.put(gift);
    });
  }

  // ======================================================
  // SALVAR LISTA (sync remoto)
  // ======================================================
  Future<void> saveAll(List<GiftLocal> gifts) async {
    await isar.writeTxn(() async {
      await isar.giftLocals.putAll(gifts);
    });
  }

  // ======================================================
  // REMOVER
  // ======================================================
  Future<void> deleteGift(int id) async {
    await isar.writeTxn(() async {
      await isar.giftLocals.delete(id);
    });
  }

  // ======================================================
  // LISTAR NÃO SINCRONIZADOS
  // ======================================================
  Future<List<GiftLocal>> getUnsynced() async {
    return isar.giftLocals.filter().syncedEqualTo(false).findAll();
  }

  // ======================================================
  // MARCAR COMO SINCRONIZADO
  // ======================================================
  Future<void> markSynced(GiftLocal gift) async {
    gift.synced = true;

    await isar.writeTxn(() async {
      await isar.giftLocals.put(gift);
    });
  }

  // ======================================================
  // LIMPAR BANCO LOCAL
  // ======================================================
  Future<void> clear() async {
    await isar.writeTxn(() async {
      await isar.giftLocals.clear();
    });
  }

  // ===============================
  // NOVO MÉTODO
  // ===============================

  Future<void> saveContribution(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) async {
    final local = GiftContributionLocal()
      ..contributionId = contribution.id
      ..eventoId = eventoId
      ..giftId = giftId
      ..nome = contribution.nome
      ..uid = contribution.uid
      ..valor = contribution.valor
      ..mensagem = contribution.mensagem
      ..createdAt = contribution.data
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.giftContributionLocals.put(local);
    });
  }

  // ===============================
  // LISTAR CONTRIBUTIONS NÃO SINCRONIZADAS
  // ===============================

  Future<List<GiftContributionLocal>> getUnsyncedContributions() {
    return isar.giftContributionLocals.filter().syncedEqualTo(false).findAll();
  }
}
