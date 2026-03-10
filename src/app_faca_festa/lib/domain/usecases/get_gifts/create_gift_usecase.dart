import './../../repositories/gift_repository.dart';
import './../../entities/gift/gift.dart';

class CreateGiftUseCase {
  final GiftRepository repository;

  CreateGiftUseCase(this.repository);

  Future<void> call(
    String eventoId,
    Gift gift,
  ) {
    return repository.createGift(eventoId, gift);
  }
}
