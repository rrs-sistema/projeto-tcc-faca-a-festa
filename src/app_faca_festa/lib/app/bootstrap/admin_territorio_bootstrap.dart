import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/admin_territorio_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/admin_territorio_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/admin_territorio_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_admin_territorios.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';

class AdminTerritorioBootstrap {
  AdminTerritorioBootstrap._();

  static void register() {
    if (!Get.isRegistered<AdminTerritorioRemoteDatasource>()) {
      Get.lazyPut<AdminTerritorioRemoteDatasource>(
        () => AdminTerritorioRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AdminTerritorioRepository>()) {
      Get.lazyPut<AdminTerritorioRepository>(
        () => AdminTerritorioRepositoryImpl(
          Get.find<AdminTerritorioRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarAdminTerritorios>()) {
      Get.lazyPut<GerenciarAdminTerritorios>(
        () => GerenciarAdminTerritorios(
          Get.find<AdminTerritorioRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AdminTerritorioController>()) {
      Get.put(
        AdminTerritorioController(
          territoriosAdmin: Get.find<GerenciarAdminTerritorios>(),
        ),
        permanent: true,
      );
    }
  }

  static AdminTerritorioController findController() {
    register();
    return Get.find<AdminTerritorioController>();
  }
}
