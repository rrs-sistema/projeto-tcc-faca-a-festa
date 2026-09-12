import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/core/database/database.dart';
import 'package:app_faca_festa/data/datasources/local/gift_local_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/gift_remote_datasource.dart';
import 'package:app_faca_festa/data/services/gift/gift_sync_service.dart';
import 'package:app_faca_festa/data/services/gift/sync_manager.dart';
import 'package:app_faca_festa/data/repositories_impl/gift_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/gift_repository.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';

/// Composes and starts the app-wide offline-first infrastructure for Gifts.
///
/// [GiftController] stays route-scoped in [GiftBootstrap.registerRoute].
/// These dependencies are permanent because synchronization starts with the
/// application and continues independently from the Gifts screens.
abstract final class GiftOfflineBootstrap {
  static Future<void> initialize() async {
    final remoteDatasource =
        GiftRemoteDatasource(Get.find<FirebaseFirestore>());
    Get.put<GiftRemoteDatasource>(remoteDatasource, permanent: true);

    final database = await constructDb();
    Get.put<AppDatabase>(database, permanent: true);

    final localDatasource = GiftLocalDatasource(database);
    Get.put<GiftLocalDatasource>(localDatasource, permanent: true);

    Get.put<GiftRepository>(
      GiftRepositoryImpl(
        local: localDatasource,
        remote: remoteDatasource,
      ),
      permanent: true,
    );
    Get.put<GiftUseCases>(
      GiftUseCases(Get.find<GiftRepository>()),
      permanent: true,
    );

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
