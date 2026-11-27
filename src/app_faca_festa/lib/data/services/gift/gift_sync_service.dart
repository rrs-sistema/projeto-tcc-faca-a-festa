import 'package:app_faca_festa/core/services/update_operations.dart';
import 'dart:developer' as developer;

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';

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

  /// Limite por item: sem resposta do servidor, a escrita segue na fila do
  /// Firestore e a próxima reconexão tenta de novo.
  static const limiteEnvio = Duration(seconds: 20);

  Future<void> syncPendentes() {
    return UpdateOperations.run(() async {
      if (ConectividadeService.offlineAgora) return;
      final pendentes = await local.getUnsynced();

      for (final gift in pendentes) {
        try {
          if (gift.deleted) {
            await remote
                .deleteGift(gift.eventoId, gift.giftId)
                .timeout(limiteEnvio);
          } else {
            await remote
                .enviarDoAparelho(gift.eventoId, gift.toModel())
                .timeout(limiteEnvio);
          }

          await local.markSyncedSeVersao(gift.giftId, gift.updatedAt);
        } catch (e) {
          developer.log(
            'Erro ao sincronizar gift ${gift.giftId}',
            name: 'GiftSyncService',
            error: e,
          );
          continue;
        }
      }

      await _syncContributionsPendentes();
    });
  }

  Future<void> _syncContributionsPendentes() {
    return UpdateOperations.run(() async {
      final pendentes = await local.getUnsyncedContributions();

      for (final contribution in pendentes) {
        try {
          await remote.saveContribution(
            contribution.eventoId,
            contribution.giftId,
            contribution.toEntity(),
          ).timeout(limiteEnvio);

          await local.markContributionSynced(contribution.contributionId);
        } catch (e) {
          developer.log(
            'Erro ao sincronizar contribution ${contribution.contributionId}',
            name: 'GiftSyncService',
            error: e,
          );
          continue;
        }
      }
    });
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
