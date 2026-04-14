import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:flutter/foundation.dart';

import './../../datasources/remote/gift_remote_datasource.dart';
import './../../datasources/local/gift_local_datasource.dart';
import './../../models/gift/gif_local_converte.dart';

class GiftSyncService {
  final GiftRemoteDatasource remote;
  final GiftLocalDatasource local;

  GiftSyncService({
    required this.local,
    required this.remote,
  });

  Future<void> syncPendentes() async {
    final pendentes = await local.getUnsynced();

    for (final gift in pendentes) {
      try {
        if (gift.deleted) {
          await remote.deleteGift(gift.eventoId, gift.giftId);
        } else {
          await remote.createGift(gift.eventoId, gift.toModel());
        }

        await local.markSynced(gift.giftId);
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao sincronizar gift ${gift.giftId}: $e');
        }
        continue;
      }
    }

    await _syncContributionsPendentes();
  }

  Future<void> _syncContributionsPendentes() async {
    final pendentes = await local.getUnsyncedContributions();

    for (final contribution in pendentes) {
      try {
        await remote.saveContribution(
          contribution.eventoId,
          contribution.giftId,
          contribution.toEntity(),
        );

        await local.markContributionSynced(contribution.contributionId);
      } catch (e) {
        if (kDebugMode) {
          print(
            'Erro ao sincronizar contribution ${contribution.contributionId}: $e',
          );
        }
        continue;
      }
    }
  }
}

extension GiftContributionRowMapper on GiftContributionLocal {
  GiftContribution toEntity() {
    return GiftContribution(
      id: contributionId,
      nome: nome,
      uid: uid,
      valor: valor,
      mensagem: mensagem,
      data: createdAt,
    );
  }
}
