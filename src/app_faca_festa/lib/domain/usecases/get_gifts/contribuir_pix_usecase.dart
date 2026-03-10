import '../../entities/gift/gift_contribution.dart';
import '../../repositories/gift_repository.dart';

class ContribuirPixUseCase {
  final GiftRepository repository;

  ContribuirPixUseCase(this.repository);

  Future<void> call(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) {
    return repository.contribuirPix(
      eventoId,
      giftId,
      contribution,
    );
  }
}
