import 'package:get/get.dart';

import '../../controllers/admin/orcamentos_admin_controller.dart';
import '../../data/datasources/remote/orcamentos_admin_remote_datasource.dart';
import '../../data/repositories_impl/orcamentos_admin_repository_impl.dart';
import '../../domain/repositories/orcamentos_admin_repository.dart';
import '../../domain/usecases/carregar_orcamentos_admin.dart';

class OrcamentosAdminBootstrap {
  OrcamentosAdminBootstrap._();

  static void register() {
    if (!Get.isRegistered<OrcamentosAdminRemoteDatasource>()) {
      Get.lazyPut<OrcamentosAdminRemoteDatasource>(
        () => OrcamentosAdminRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<OrcamentosAdminRepository>()) {
      Get.lazyPut<OrcamentosAdminRepository>(
        () => OrcamentosAdminRepositoryImpl(
          Get.find<OrcamentosAdminRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CarregarOrcamentosAdmin>()) {
      Get.lazyPut<CarregarOrcamentosAdmin>(
        () => CarregarOrcamentosAdmin(Get.find<OrcamentosAdminRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<OrcamentosAdminController>()) {
      Get.put(
        OrcamentosAdminController(
          carregarOrcamentos: Get.find<CarregarOrcamentosAdmin>(),
        ),
        permanent: true,
      );
    }
  }

  static OrcamentosAdminController findController() {
    register();
    return Get.find<OrcamentosAdminController>();
  }
}
