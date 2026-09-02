import './../../repositories/gift_repository.dart';

class DeleteGiftUseCase {
  final GiftRepository repository;

  DeleteGiftUseCase(this.repository);

  Future<void> call(
    String eventoId,
    String giftId,
  ) {
    return repository.deleteGift(
      eventoId,
      giftId,
    );
  }
}
