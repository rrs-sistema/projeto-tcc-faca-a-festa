import 'package:app_faca_festa/data/models/gift/gif_local_converte.dart';
import 'package:flutter/foundation.dart';

import './../../datasources/remote/gift_remote_datasource.dart';
import './../../datasources/local/gift_local_datasource.dart';

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
          // 💡 Lembrete: Garanta que o createGift do seu Datasource
          // use .set(dados, SetOptions(merge: true)) para funcionar como Upsert.
          await remote.createGift(gift.eventoId, gift.toModel());
        }

        // Se chegou aqui, o Firebase confirmou a gravação!
        gift.synced = true;

        // Aqui, a dica do @Index(unique: true, replace: true) que te passei
        // na classe GiftLocal brilha: ele vai atualizar o status no Isar sem duplicar.
        await local.saveGift(gift);
      } catch (e) {
        if (kDebugMode) {
          print("Erro ao sincronizar gift ${gift.giftId}: $e");
        }
        // 🔥 MUDANÇA CRÍTICA: De 'break' para 'continue'
        // Ignora o item problemático e tenta salvar o resto da fila.
        continue;
      }
    }
  }
}
