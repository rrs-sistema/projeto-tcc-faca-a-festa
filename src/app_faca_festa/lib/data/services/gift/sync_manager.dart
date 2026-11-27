import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'gift_sync_service.dart';
import 'dart:async';

class SyncManager {
  final GiftSyncService giftSync;

  StreamSubscription? _subscription;
  StreamSubscription<void>? _reconexao;
  bool _syncing = false;

  SyncManager(this.giftSync);

  Future<void> start() async {
    // 🔹 Primeiro sync ao abrir o app, sem segurar a abertura
    unawaited(_trySync());

    // 🔹 Escuta mudanças de conexão. O Wi-Fi conectado não garante internet;
    // a confirmação do ConectividadeService também dispara o envio.
    _subscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        await _trySync();
      }
    });
    _reconexao = ConectividadeService.instancia?.aoReconectar
        .listen((_) => unawaited(_trySync()));
  }

  Future<void> _trySync() async {
    if (_syncing || ConectividadeService.offlineAgora) return;

    _syncing = true;

    try {
      await giftSync.syncPendentes();
    } catch (_) {
    } finally {
      _syncing = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _reconexao?.cancel();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await _reconexao?.cancel();
    _subscription = null;
    _reconexao = null;
  }
}
