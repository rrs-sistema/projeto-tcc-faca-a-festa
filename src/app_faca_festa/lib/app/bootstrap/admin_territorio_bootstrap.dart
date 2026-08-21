import 'package:get/get.dart';

import '../../controllers/admin/admin_territorio_controller.dart';
import '../../data/datasources/remote/admin_territorio_remote_datasource.dart';
import '../../data/repositories_impl/admin_territorio_repository_impl.dart';
import '../../domain/repositories/admin_territorio_repository.dart';
import '../../domain/usecases/gerenciar_admin_territorios.dart';

class AdminTerritorioBootstrap {
  AdminTerritorioBootstrap._();

  static void register() {
    if (!Get.isRegistered<AdminTerritorioRemoteDatasource>()) {
      Get.lazyPut<AdminTerritorioRemoteDatasource>(
        () => AdminTerritorioRemoteDatasource(),
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
