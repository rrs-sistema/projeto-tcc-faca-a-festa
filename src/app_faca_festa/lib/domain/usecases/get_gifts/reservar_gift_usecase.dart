import './../../repositories/gift_repository.dart';

class ReservarGiftUseCase {
  final GiftRepository repository;

  ReservarGiftUseCase(this.repository);

  Future<bool> call(
    String eventoId,
    String giftId,
    String nome,
    String uid,
  ) {
    return repository.reservarGift(
      eventoId,
      giftId,
      nome,
      uid,
    );
  }
}
