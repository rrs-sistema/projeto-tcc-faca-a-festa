
import './../../repositories/gift_repository.dart';
import './../../entities/gift/gift.dart';

class GetGiftsUseCase {
  final GiftRepository repository;

  GetGiftsUseCase(this.repository);

  Stream<List<Gift>> call(String eventoId) {
    return repository.getGifts(eventoId);
  }
}
