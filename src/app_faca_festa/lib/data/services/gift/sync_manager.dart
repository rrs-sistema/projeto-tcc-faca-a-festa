import 'package:connectivity_plus/connectivity_plus.dart';
import 'gift_sync_service.dart';
import 'dart:async';

class SyncManager {
  final GiftSyncService giftSync;

  StreamSubscription? _subscription;
  bool _syncing = false;

  SyncManager(this.giftSync);

  Future<void> start() async {
    // 🔹 Primeiro sync ao abrir o app
    await _trySync();

    // 🔹 Escuta mudanças de conexão
    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        await _trySync();
      }
    });
  }

  Future<void> _trySync() async {
    if (_syncing) return;

    _syncing = true;

    try {
      await giftSync.syncPendentes();
    } catch (_) {}

    _syncing = false;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
