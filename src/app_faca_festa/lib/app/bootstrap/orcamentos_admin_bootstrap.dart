import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/orcamentos_admin_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/orcamentos_admin_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/orcamentos_admin_repository.dart';
import 'package:app_faca_festa/domain/usecases/carregar_orcamentos_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/orcamentos_admin_controller.dart';

class OrcamentosAdminBootstrap {
  OrcamentosAdminBootstrap._();

  static void register() {
    if (!Get.isRegistered<OrcamentosAdminRemoteDatasource>()) {
      Get.lazyPut<OrcamentosAdminRemoteDatasource>(
        () => OrcamentosAdminRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
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
