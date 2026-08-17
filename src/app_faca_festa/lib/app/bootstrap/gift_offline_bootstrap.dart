import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database.dart';
import '../../data/datasources/local/gift_local_datasource.dart';
import '../../data/datasources/remote/gift_remote_datasource.dart';
import '../../data/services/gift/gift_sync_service.dart';
import '../../data/services/gift/sync_manager.dart';

/// Composes and starts the app-wide offline-first infrastructure for Gifts.
///
/// Feature route dependencies remain in [GiftBinding]. These dependencies are
/// permanent because synchronization starts with the application and continues
/// independently from the Gifts screens.
abstract final class GiftOfflineBootstrap {
  static Future<void> initialize() async {
    final remoteDatasource = GiftRemoteDatasource(FirebaseFirestore.instance);
    Get.put<GiftRemoteDatasource>(remoteDatasource, permanent: true);

    final database = await constructDb();
    Get.put<AppDatabase>(database, permanent: true);

    final localDatasource = GiftLocalDatasource(database);
    Get.put<GiftLocalDatasource>(localDatasource, permanent: true);

    final syncService = GiftSyncService(
      local: localDatasource,
      remote: remoteDatasource,
    );
    Get.put<GiftSyncService>(syncService, permanent: true);

    final syncManager = SyncManager(syncService);
    Get.put<SyncManager>(syncManager, permanent: true);
    await syncManager.start();

    debugPrint(
      kIsWeb
          ? '🌐 [WEB] Offline-First com Drift/Wasm ativado!'
          : '📱/🖥️ Offline-First com Drift ativado!',
    );
  }
}
