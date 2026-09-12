import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/inspiracao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/inspiracao_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/inspiracao_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_inspiracoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';

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
      Get.put(
        InspiracaoController(
          inspiracoes: Get.find<GerenciarInspiracoes>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<InspiracaoAdminController>()) {
      // Lazy: evita criar o controller (e qualquer efeito colateral) antes do login.
      Get.lazyPut<InspiracaoAdminController>(
        () => InspiracaoAdminController(
          inspiracoes: Get.find<GerenciarInspiracoes>(),
          usuarioAutenticado: () =>
              Get.isRegistered<AppController>() &&
              Get.find<AppController>().usuarioLogado.value != null,
        ),
        fenix: true,
      );
    }
  }
}
