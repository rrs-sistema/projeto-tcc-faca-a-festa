import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/database/app_database.dart';
import '../../core/services/desktop_update_service.dart';
import '../../core/services/update_operations.dart';
import '../../core/services/flush_settings.dart';
import '../../core/services/update_preparation.dart';
import '../../data/services/gift/sync_manager.dart';
import '../../presentation/modules/app/controllers/app_controller.dart';

abstract final class DesktopUpdateBootstrap {
  static void initialize() {
    if (DesktopUpdateService.supported) {
      unawaited(
          DesktopUpdateService.instance.initialize().catchError((Object e) {
        DesktopUpdateService.instance
            .reportError('Não foi possível iniciar o atualizador: $e');
      }));
    }
  }

  static void assertIdle() {
    if (EasyLoading.isShow || UpdateOperations.active != 0) {
      throw StateError(
          'Aguarde as operações, exportações e gravações em andamento.');
    }
    if (Get.isRegistered<AppController>() &&
        Get.find<AppController>().servicosSelecionados.isNotEmpty) {
      throw StateError(
          'Conclua ou limpe o carrinho de cotação antes de atualizar.');
    }
  }

  static Future<void> prepare() async {
    assertIdle();
    UpdateOperations.seal();
    // Never sign out, clear the storage, or change the database path.
    await UpdatePreparation(
      stopSynchronization: () async {
        if (Get.isRegistered<SyncManager>()) {
          await Get.find<SyncManager>().stop();
        }
      },
      persistSettings: () async {
        final storage = GetStorage();
        await storage.save();
        // GetStorage.save() only schedules a microtask in 2.1.1; await its queue.
        await Future<void>.delayed(Duration.zero);
        await storage.queue.add(() async {});
        await flushSettings(
            Map<String, dynamic>.from(storage.listenable.value));
      },
      flushPendingWrites: () async {
        if (Get.isRegistered<FirebaseFirestore>()) {
          await Get.find<FirebaseFirestore>().waitForPendingWrites();
        }
      },
      closeDatabase: () async {
        if (Get.isRegistered<AppDatabase>()) {
          await Get.find<AppDatabase>().close();
        }
      },
    ).run();
  }
}
