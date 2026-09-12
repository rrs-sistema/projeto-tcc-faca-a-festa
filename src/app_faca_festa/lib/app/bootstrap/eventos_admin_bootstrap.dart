import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/eventos_admin_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/eventos_admin_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/eventos_admin_repository.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_eventos_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/eventos_admin_controller.dart';

class EventosAdminBootstrap {
  EventosAdminBootstrap._();

  static void register() {
    if (!Get.isRegistered<EventosAdminRemoteDatasource>()) {
      Get.lazyPut<EventosAdminRemoteDatasource>(
        () => EventosAdminRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<EventosAdminRepository>()) {
      Get.lazyPut<EventosAdminRepository>(
        () => EventosAdminRepositoryImpl(
          Get.find<EventosAdminRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarEventosAdmin>()) {
      Get.lazyPut<GerenciarEventosAdmin>(
        () => GerenciarEventosAdmin(Get.find<EventosAdminRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<EventosAdminController>()) {
      Get.put(
        EventosAdminController(
          eventosAdmin: Get.find<GerenciarEventosAdmin>(),
          auditoria: Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : const AuditoriaRegistrarVazio(),
          auditoriaResolver: () => Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : null,
        ),
        permanent: true,
      );
    }
  }

  static EventosAdminController findController() {
    register();
    return Get.find<EventosAdminController>();
  }
}
