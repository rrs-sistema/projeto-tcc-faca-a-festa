import 'package:app_faca_festa/presentation/modules/gifts/controllers/gift_controller.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:app_faca_festa/domain/repositories/gift_repository.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _GiftRepositoryFake repository;
  late GiftController controller;

  setUp(() {
    repository = _GiftRepositoryFake();
    controller = GiftController(
      eventoId: 'evento-1',
      usecases: GiftUseCases(repository),
    );
  });

  tearDown(() {
    controller.onClose();
  });

  test('create delegates the unchanged event id and entity', () async {
    final gift = _gift();

    await controller.criarPresente(gift);

    expect(repository.createdEventoId, 'evento-1');
    expect(repository.createdGift, same(gift));
    expect(controller.loading.value, isFalse);
  });

  test('loading returns to false when repository throws', () async {
    repository.createError = StateError('failure');

    await expectLater(controller.criarPresente(_gift()), throwsStateError);

    expect(controller.loading.value, isFalse);
  });

  test('reserve delegates parameters and returns repository result', () async {
    repository.reserveResult = true;

    final result = await controller.reservarPresente(
      'gift-1',
      'Maria',
      'uid-1',
    );

    expect(result, isTrue);
    expect(repository.reservation, ('evento-1', 'gift-1', 'Maria', 'uid-1'));
    expect(controller.loading.value, isFalse);
  });
}

Gift _gift() {
  return Gift(
    id: 'gift-1',
    nome: 'Presente',
    categoria: 'geral',
    tipo: GiftType.fisico,
    status: GiftStatus.disponivel,
    createdAt: DateTime(2026, 8, 13),
  );
}

class _GiftRepositoryFake implements GiftRepository {
  String? createdEventoId;
  Gift? createdGift;
  Object? createError;
  bool reserveResult = false;
  (String, String, String, String)? reservation;

  @override
  Future<void> createGift(String eventoId, Gift gift) async {
    if (createError case final error?) {
      throw error;
    }
    createdEventoId = eventoId;
    createdGift = gift;
  }

  @override
  Future<bool> reservarGift(
    String eventoId,
    String giftId,
    String nome,
    String uid,
  ) async {
    reservation = (eventoId, giftId, nome, uid);
    return reserveResult;
  }

  @override
  Stream<List<Gift>> getGifts(String eventoId) => const Stream.empty();

  @override
  Stream<List<Gift>> watchRemoteGifts(String eventoId) => const Stream.empty();

  @override
  Future<void> updateGift(String eventoId, Gift gift) async {}

  @override
  Future<void> deleteGift(String eventoId, String giftId) async {}

  @override
  Future<void> contribuirPix(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) async {}
}
