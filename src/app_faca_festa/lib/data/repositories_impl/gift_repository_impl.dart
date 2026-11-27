import 'package:app_faca_festa/core/services/update_operations.dart';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import './../datasources/remote/gift_remote_datasource.dart';
import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import './../datasources/local/gift_local_datasource.dart';
import 'package:app_faca_festa/domain/repositories/gift_repository.dart';
import './../models/gift/gif_local_converte.dart';
import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import './../models/gift/gift_model.dart';
import 'package:app_faca_festa/core/conectividade/recarregar_ao_reconectar.dart';

/// Presentes local-first: a tela lê do SQLite do aparelho, que espelha o
/// servidor enquanto está aberta. Toda alteração grava primeiro no aparelho;
/// o envio acontece em segundo plano e o `SyncManager` retoma o que faltar.
class GiftRepositoryImpl implements GiftRepository {
  final GiftLocalDatasource local;
  final GiftRemoteDatasource remote;

  GiftRepositoryImpl({
    required this.local,
    required this.remote,
  });

  @override
  Stream<List<Gift>> getGifts(String eventoId) {
    StreamSubscription<List<GiftLocal>>? locais;
    StreamSubscription<({List<GiftModel> presentes, bool doServidor})>?
        servidor;
    StreamSubscription<void>? reconexao;
    late final StreamController<List<Gift>> controller;
    void escutarServidor() {
      servidor = remote.observarServidor(eventoId).listen(
            (lote) => unawaited(
              mesclarDoServidor(eventoId, lote.presentes,
                      doServidor: lote.doServidor)
                  .catchError((Object e) => _log('mesclar $eventoId', e)),
            ),
            onError: (Object e) {
              _log('observar $eventoId', e);
              // A escuta do servidor encerra no erro; a lista local segue.
              servidor = null;
              reconexao ??= sinalDeReconexao().listen((_) {
                unawaited(reconexao?.cancel());
                reconexao = null;
                if (servidor == null && controller.hasListener) {
                  escutarServidor();
                }
              });
            },
          );
    }

    controller = StreamController<List<Gift>>(
      onListen: () {
        escutarServidor();
        locais = local.watchGifts(eventoId).listen(
              (lista) => controller.add([for (final g in lista) g.toEntity()]),
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await reconexao?.cancel();
        await servidor?.cancel();
        await locais?.cancel();
      },
    );
    return controller.stream;
  }

  /// Traz a versão do servidor para o aparelho.
  ///
  /// Linhas com alteração local pendente ficam como estão até o envio. Ao
  /// valor arrecadado do servidor somam-se as contribuições ainda não enviadas.
  Future<void> mesclarDoServidor(
    String eventoId,
    List<GiftModel> presentes, {
    required bool doServidor,
  }) async {
    final contribuicoes = await local.getUnsyncedContributions();
    final linhas = <GiftLocalsCompanion>[];
    for (final presente in presentes) {
      final atual = await local.getGift(presente.id);
      if (atual != null && !atual.synced) continue;
      final aEnviar = contribuicoes
          .where((c) => c.giftId == presente.id)
          .fold<double>(0, (soma, c) => soma + c.valor);
      linhas.add(_comArrecadado(presente, presente.valorArrecadado + aEnviar)
          .toCompanion(
            eventoId: eventoId,
            synced: true,
            updatedAtOverride: atual?.updatedAt ?? presente.createdAt,
          ));
    }
    await local.saveAll(linhas);
    if (doServidor) {
      await local.removerSincronizadosAusentes(
        eventoId,
        {for (final p in presentes) p.id},
      );
    }
  }

  @override
  Stream<List<Gift>> watchRemoteGifts(String eventoId) {
    return remote.watchRemote(eventoId).map(
          (list) => list.map((model) => model as Gift).toList(),
        );
  }

  @override
  Future<void> createGift(String eventoId, Gift gift) {
    return UpdateOperations.run(() async {
      final model = GiftModel.fromEntity(gift);

      final companion = model.toCompanion(
        eventoId: eventoId,
        synced: false,
        deleted: false,
        updatedAtOverride: DateTime.now(),
      );

      await local.saveGift(companion);
      await _enviarEmSegundoPlano(model.id, 'presente "${gift.nome}"');
    });
  }

  @override
  Future<void> updateGift(String eventoId, Gift gift) {
    return UpdateOperations.run(() async {
      final model = GiftModel.fromEntity(gift);

      final existing = await local.getGift(model.id);

      final updated = model.toCompanion(
        eventoId: eventoId,
        synced: false,
        deleted: existing?.deleted ?? false,
        updatedAtOverride: DateTime.now(),
      );

      await local.saveGift(updated);
      await _enviarEmSegundoPlano(model.id, 'presente "${gift.nome}"');
    });
  }

  @override
  Future<void> deleteGift(String eventoId, String giftId) {
    return UpdateOperations.run(() async {
      final gift = await local.getGift(giftId);
      if (gift == null) return;

      await local.markDeleted(giftId);
      await _enviarEmSegundoPlano(giftId, 'exclusão do presente "${gift.nome}"');
    });
  }

  @override
  Future<bool> reservarGift(
    String eventoId,
    String giftId,
    String nome,
    String uid,
  ) {
    return UpdateOperations.run(() async {
      final gift = await local.getGift(giftId);
      if (gift == null || gift.status != 'disponivel') return false;

      await local.updateReservation(
        giftId: giftId,
        status: 'reservado',
        reservadoPor: nome,
        reservadoUid: uid,
        dataReserva: DateTime.now(),
        synced: false,
      );

      await _enviarEmSegundoPlano(giftId, 'reserva do presente "${gift.nome}"');
      return true;
    });
  }

  @override
  Future<void> contribuirPix(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) {
    return UpdateOperations.run(() async {
      final gift = await local.getGift(giftId);
      if (gift == null) return;

      // Id estável: o reenvio pelo SyncManager não duplica a contribuição.
      final registro = contribution.id.trim().isNotEmpty
          ? contribution
          : GiftContribution(
              id: const Uuid().v4(),
              nome: contribution.nome,
              uid: contribution.uid,
              valor: contribution.valor,
              mensagem: contribution.mensagem,
              data: contribution.data,
            );

      await local.saveContribution(eventoId, giftId, registro);
      // O valor do presente acompanha a contribuição; o presente em si não
      // fica pendente, para o espelho do servidor continuar atualizando.
      await local.updateValorArrecadado(
        giftId: giftId,
        valorArrecadado: gift.valorArrecadado + registro.valor,
        synced: gift.synced,
      );

      if (ConectividadeService.offlineAgora) return;
      final envio = remote.saveContribution(eventoId, giftId, registro);
      EstadoSincronizacao.instancia?.registrar(
        envio,
        descricao: 'contribuição para "${gift.nome}"',
        chave: registro.id,
      );
      unawaited(envio
          .then((_) => local.markContributionSynced(registro.id))
          .catchError((Object e) => _log('contribuição ${registro.id}', e)));
    });
  }

  /// O Firestore confirma a escrita só quando o servidor responde; esperar
  /// aqui travaria a tela sem internet.
  Future<void> _enviarEmSegundoPlano(String giftId, String descricao) async {
    final linha = await local.getGift(giftId);
    if (linha == null) return;
    final Future<void> envio = linha.deleted
        ? remote.deleteGift(linha.eventoId, linha.giftId)
        : remote.enviarDoAparelho(linha.eventoId, linha.toModel());
    EstadoSincronizacao.instancia
        ?.registrar(envio, descricao: descricao, chave: giftId);
    unawaited(envio
        .then((_) => local.markSyncedSeVersao(giftId, linha.updatedAt))
        .catchError((Object e) => _log('presente $giftId', e)));
  }

  GiftModel _comArrecadado(GiftModel p, double valorArrecadado) => GiftModel(
        id: p.id,
        nome: p.nome,
        descricao: p.descricao,
        categoria: p.categoria,
        tipo: p.tipo,
        valor: p.valor,
        loja: p.loja,
        link: p.link,
        pix: p.pix,
        metaValor: p.metaValor,
        valorArrecadado: valorArrecadado,
        imagem: p.imagem,
        status: p.status,
        reservadoPor: p.reservadoPor,
        reservadoUid: p.reservadoUid,
        dataReserva: p.dataReserva,
        createdAt: p.createdAt,
      );

  void _log(String contexto, Object erro) {
    developer.log(
      'Erro sync gift: $contexto',
      name: 'GiftRepositoryImpl',
      error: erro,
    );
  }
}
