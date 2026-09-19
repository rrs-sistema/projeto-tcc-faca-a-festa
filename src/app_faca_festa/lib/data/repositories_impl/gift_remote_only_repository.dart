import 'package:app_faca_festa/data/datasources/remote/gift_remote_datasource.dart';
import 'package:app_faca_festa/data/models/gift/gift_contribution_model.dart';
import 'package:app_faca_festa/data/models/gift/gift_model.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:app_faca_festa/domain/repositories/gift_repository.dart';

/// Lista e reserva presentes só pelo Firestore.
/// Usado na web quando o Drift/Wasm local não sobe.
class GiftRemoteOnlyRepository implements GiftRepository {
  GiftRemoteOnlyRepository(this.remote);

  final GiftRemoteDatasource remote;

  @override
  Stream<List<Gift>> getGifts(String eventoId) => watchRemoteGifts(eventoId);

  @override
  Stream<List<Gift>> watchRemoteGifts(String eventoId) {
    return remote.watchRemote(eventoId).map(List<Gift>.from);
  }

  @override
  Future<void> createGift(String eventoId, Gift gift) {
    return remote.createGift(eventoId, GiftModel.fromEntity(gift));
  }

  @override
  Future<void> updateGift(String eventoId, Gift gift) {
    return remote.updateGift(eventoId, GiftModel.fromEntity(gift));
  }

  @override
  Future<void> deleteGift(String eventoId, String giftId) {
    return remote.deleteGift(eventoId, giftId);
  }

  @override
  Future<bool> reservarGift(
    String eventoId,
    String giftId,
    String nome,
    String uid,
  ) {
    return remote.reservarGift(eventoId, giftId, nome, uid);
  }

  @override
  Future<void> contribuirPix(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) {
    return remote.saveContribution(
      eventoId,
      giftId,
      GiftContributionModel.fromEntity(contribution),
    );
  }
}
