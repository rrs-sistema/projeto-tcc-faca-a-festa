import '../../entities/gift/gift.dart';
import '../../repositories/gift_repository.dart';

class UpdateGiftUseCase {
  final GiftRepository repository;
  UpdateGiftUseCase(this.repository);
  Future<void> call(String eventoId, Gift gift) {
    return repository.updateGift(eventoId, gift);
  }
}
