import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/eventos_admin_remote_datasource.dart';
import '../../data/repositories_impl/eventos_admin_repository_impl.dart';
import '../../domain/repositories/eventos_admin_repository.dart';
import '../../domain/usecases/gerenciar_eventos_admin.dart';
import '../../presentation/modules/admin/controllers/eventos_admin_controller.dart';

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
        EventosAdminController(eventosAdmin: Get.find<GerenciarEventosAdmin>()),
        permanent: true,
      );
    }
  }

  static EventosAdminController findController() {
    register();
    return Get.find<EventosAdminController>();
  }
}
