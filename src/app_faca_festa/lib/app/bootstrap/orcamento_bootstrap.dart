import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/bootstrap/orcamento_gasto_bootstrap.dart';
import 'package:app_faca_festa/data/datasources/remote/orcamento_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/orcamento_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/orcamento_repository.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamentos.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';

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
        OrcamentoController(
          orcamentos: Get.find<GerenciarOrcamentos>(),
          auditoria: Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : const AuditoriaRegistrarVazio(),
          eventoController: Get.isRegistered<EventoController>()
              ? Get.find<EventoController>()
              : null,
          gastoControllerOf: (idOrcamento) =>
              OrcamentoGastoBootstrap.putController(tag: idOrcamento),
        ),
        permanent: true,
      );
    }
  }

  static OrcamentoController findController() {
    register();
    return Get.find<OrcamentoController>();
  }
}
