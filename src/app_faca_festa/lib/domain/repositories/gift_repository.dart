import './../entities/gift/gift_contribution.dart';
import './../entities/gift/gift.dart';

abstract class GiftRepository {
  Stream<List<Gift>> getGifts(String eventoId);

  Stream<List<Gift>> watchRemoteGifts(String eventoId);

  Future<void> createGift(
    String eventoId,
    Gift gift,
  );

  Future<void> updateGift(String eventoId, Gift gift);

  Future<void> deleteGift(
    String eventoId,
    String giftId,
  );

  Future<bool> reservarGift(
    String eventoId,
    String giftId,
    String nome,
    String uid,
  );

  Future<void> contribuirPix(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  );
}
