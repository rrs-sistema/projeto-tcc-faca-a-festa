import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/inspiracao_remote_datasource.dart';
import '../../data/repositories_impl/inspiracao_repository_impl.dart';
import '../../domain/repositories/inspiracao_repository.dart';
import '../../domain/usecases/gerenciar_inspiracoes.dart';
import '../../presentation/modules/inspiracao/controllers/inspiracao_admin_controller.dart';
import '../../presentation/modules/inspiracao/controllers/inspiracao_controller.dart';

abstract final class InspiracaoBootstrap {
  static void register() {
    if (!Get.isRegistered<InspiracaoRemoteDatasource>()) {
      Get.put<InspiracaoRemoteDatasource>(
        InspiracaoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
          storage: Get.find<FirebaseStorage>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<InspiracaoRepository>()) {
      Get.put<InspiracaoRepository>(
        InspiracaoRepositoryImpl(Get.find<InspiracaoRemoteDatasource>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GerenciarInspiracoes>()) {
      Get.put<GerenciarInspiracoes>(
        GerenciarInspiracoes(Get.find<InspiracaoRepository>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<InspiracaoController>()) {
      Get.put(InspiracaoController(), permanent: true);
    }
    if (!Get.isRegistered<InspiracaoAdminController>()) {
      Get.put(InspiracaoAdminController(), permanent: true);
    }
  }
}
