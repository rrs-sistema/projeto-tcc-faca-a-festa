import './../../repositories/gift_repository.dart';

import './contribuir_pix_usecase.dart';
import './reservar_gift_usecase.dart';
import './create_gift_usecase.dart';
import './get_gifts_usecase.dart';
import 'delete_gift_usecase.dart';
import 'update_gift_use_case.dart';

class GiftUseCases {
  final GetGiftsUseCase getGifts;
  final CreateGiftUseCase createGift;
  final UpdateGiftUseCase updateGift; // 🔥 NOVO
  final DeleteGiftUseCase deleteGift;
  final ReservarGiftUseCase reservarGift;
  final ContribuirPixUseCase contribuirPix;

  GiftUseCases(GiftRepository repository)
      : getGifts = GetGiftsUseCase(repository),
        createGift = CreateGiftUseCase(repository),
        updateGift = UpdateGiftUseCase(repository), // 🔥 NOVO
        deleteGift = DeleteGiftUseCase(repository),
        reservarGift = ReservarGiftUseCase(repository),
        contribuirPix = ContribuirPixUseCase(repository);
}
