import 'package:app_faca_festa/data/models/gift/gif_local_converte.dart';
import 'package:flutter/foundation.dart';

import './../datasources/remote/gift_remote_datasource.dart';
import './../../domain/entities/gift/gift_contribution.dart';
import './../datasources/local/gift_local_datasource.dart';
import './../../domain/repositories/gift_repository.dart';
import './../../domain/entities/gift/gift.dart';
import './../models/gift/gift_local.dart';
import './../models/gift/gift_model.dart';

class GiftRepositoryImpl implements GiftRepository {
  final GiftLocalDatasource local;
  final GiftRemoteDatasource remote;
  bool _syncing = false;

  GiftRepositoryImpl({
    required this.local,
    required this.remote,
  });

  // ================================
  // GET GIFTS
  // ================================
  @override
  Stream<List<Gift>> getGifts(String eventoId) {
    return local.watchGifts(eventoId).map(
          (list) => list.map((e) => e.toEntity()).toList(),
        );
  }

  // ================================
  // CREATE GIFT
  // ================================
  @override
  Future<void> createGift(String eventoId, Gift gift) async {
    final model = gift as GiftModel;

    final localGift = GiftLocal()
      ..giftId = model.id
      ..eventoId = eventoId
      ..nome = model.nome
      ..descricao = model.descricao
      ..tipo = model.tipo.name
      ..valor = model.valor
      ..valorArrecadado = model.valorArrecadado
      ..loja = model.loja
      ..link = model.link
      ..pix = model.pix
      ..metaValor = model.metaValor
      ..status = model.status.name
      ..synced = false // Sempre falso no início
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await local.saveGift(localGift);

    // 🔥 Tenta enviar para o Firebase imediatamente
    await _trySyncRemote(localGift);
  }

// ================================
  // UPDATE GIFT
  // ================================
  @override
  Future<void> updateGift(String eventoId, Gift gift) async {
    final model = gift as GiftModel;
    final existing = await local.getGift(model.id);
    if (existing == null) return;

    existing.nome = model.nome;
    existing.descricao = model.descricao;
    existing.tipo = model.tipo.name;
    existing.valor = model.valor;
    existing.loja = model.loja;
    existing.link = model.link;
    existing.pix = model.pix;
    existing.imagem = model.imagem;
    existing.metaValor = model.metaValor;
    existing.synced = false;
    existing.updatedAt = DateTime.now();

    await local.saveGift(existing);

    // 🔥 Sincroniza atualização
    await _trySyncRemote(existing);
  }

  // ================================
  // DELETE GIFT
  // ================================
  @override
  Future<void> deleteGift(String eventoId, String giftId) async {
    final gift = await local.getGift(giftId);

    if (gift == null) return;

    gift.deleted = true;
    gift.synced = false;
    gift.updatedAt = DateTime.now();

    await local.saveGift(gift);
  }

  // ================================
  // RESERVAR
  // ================================
  @override
  Future<bool> reservarGift(String eventoId, String giftId, String nome, String uid) async {
    final gift = await local.getGift(giftId);
    if (gift == null || gift.status != "disponivel") return false;

    gift.status = "reservado";
    gift.reservadoPor = nome;
    gift.reservadoUid = uid;
    gift.dataReserva = DateTime.now();
    gift.synced = false;
    gift.updatedAt = DateTime.now();

    await local.saveGift(gift);

    // 🔥 Sincroniza reserva
    await _trySyncRemote(gift);
    return true;
  }

  // ================================
  // CONTRIBUIR PIX
  // ================================
  @override
  Future<void> contribuirPix(String eventoId, String giftId, GiftContribution contribution) async {
    final gift = await local.getGift(giftId);
    if (gift == null) return;

    gift.valorArrecadado += contribution.valor;
    gift.synced = false;
    gift.updatedAt = DateTime.now();

    await local.saveGift(gift);

    // Salva contribuição local e remota
    await local.saveContribution(eventoId, giftId, contribution);

    try {
      await remote.saveContribution(eventoId, giftId, contribution);
      await _trySyncRemote(gift); // Atualiza o valor total do presente no remoto
    } catch (_) {}
  }

  // Helper para tentar sincronizar remotamente sem travar o fluxo local
  Future<void> _trySyncRemote(GiftLocal localGift) async {
    if (_syncing) return;

    _syncing = true;

    try {
      if (localGift.deleted) {
        await remote.deleteGift(localGift.eventoId, localGift.giftId);
      } else {
        await remote.createGift(localGift.eventoId, localGift.toModel());
      }

      localGift.synced = true;
      await local.saveGift(localGift);
    } catch (e) {
      if (kDebugMode) {
        print("Erro sync gift ${localGift.giftId}: $e");
      }
    }

    _syncing = false;
  }
}
