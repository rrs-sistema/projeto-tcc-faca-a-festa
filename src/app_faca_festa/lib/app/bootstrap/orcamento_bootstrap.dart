import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/orcamento_remote_datasource.dart';
import '../../data/repositories_impl/orcamento_repository_impl.dart';
import '../../domain/repositories/orcamento_repository.dart';
import '../../domain/usecases/gerenciar_orcamentos.dart';
import '../../presentation/modules/orcamento/orcamento_controller.dart';

class OrcamentoBootstrap {
  OrcamentoBootstrap._();

  static void register() {
    if (!Get.isRegistered<OrcamentoRemoteDatasource>()) {
      Get.lazyPut<OrcamentoRemoteDatasource>(
        () => OrcamentoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
          auth: Get.find<FirebaseAuth>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<OrcamentoRepository>()) {
      Get.lazyPut<OrcamentoRepository>(
        () => OrcamentoRepositoryImpl(Get.find<OrcamentoRemoteDatasource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarOrcamentos>()) {
      Get.lazyPut<GerenciarOrcamentos>(
        () => GerenciarOrcamentos(Get.find<OrcamentoRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<OrcamentoController>()) {
      Get.put(
        OrcamentoController(orcamentos: Get.find<GerenciarOrcamentos>()),
        permanent: true,
      );
    }
  }

  static OrcamentoController findController() {
    register();
    return Get.find<OrcamentoController>();
  }
}
