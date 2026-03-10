import 'package:get/get.dart';
import 'dart:async';

import './../../domain/usecases/get_gifts/gift_usecases.dart';
import './../../domain/entities/gift/gift_contribution.dart';
import './../../domain/entities/gift/gift.dart';

class GiftController extends GetxController {
  final loading = false.obs;
  final String eventoId;
  final GiftUseCases usecases;

  GiftController({
    required this.eventoId,
    required this.usecases,
  });

  final gifts = <Gift>[].obs;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _listenPresentes();
  }

  void _listenPresentes() {
    _sub = usecases.getGifts(eventoId).listen((data) {
      gifts.value = data;
    });
  }

  // ================================
  // MÉTODOS DE AÇÃO
  // ================================

  Future<void> criarPresente(Gift gift) async {
    try {
      loading.value = true;
      await usecases.createGift.call(eventoId, gift); // Assumindo o método .call no UseCase
    } finally {
      loading.value = false;
    }
  }

  Future<void> atualizarPresente(Gift gift) async {
    try {
      loading.value = true;
      await usecases.updateGift.call(eventoId, gift);
    } finally {
      loading.value = false;
    }
  }

  Future<void> excluirPresente(String giftId) async {
    try {
      loading.value = true;
      await usecases.deleteGift.call(eventoId, giftId);
    } finally {
      loading.value = false;
    }
  }

  Future<bool> reservarPresente(String giftId, String nome, String uid) async {
    try {
      loading.value = true;
      return await usecases.reservarGift.call(eventoId, giftId, nome, uid);
    } finally {
      loading.value = false;
    }
  }

  Future<void> contribuirPix(String giftId, GiftContribution contribution) async {
    try {
      loading.value = true;
      await usecases.contribuirPix.call(eventoId, giftId, contribution);
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
