import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../controllers/evento_controller.dart';
import '../../data/datasources/remote/evento_remote_ds.dart';
import '../../data/local/evento_ativo_store.dart';
import '../../data/repositories_impl/evento_repository_impl.dart';
import '../../domain/repositories/evento_repository.dart';
import '../../presentation/coordinators/evento_session_coordinator.dart';

/// Global composition root for the current-event session.
abstract final class EventoBootstrap {
  static void register() {
    if (!Get.isRegistered<EventoRemoteDatasource>()) {
      Get.put<EventoRemoteDatasource>(
        EventoRemoteDatasource(FirebaseFirestore.instance),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventoRepository>()) {
      Get.put<EventoRepository>(
        EventoRepositoryImpl(Get.find<EventoRemoteDatasource>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventoSessionCoordinator>()) {
      Get.put<EventoSessionCoordinator>(
        GetxEventoSessionCoordinator(),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventoController>()) {
      Get.put<EventoController>(
        EventoController(
          repository: Get.find<EventoRepository>(),
          sessionCoordinator: Get.find<EventoSessionCoordinator>(),
          eventoAtivoStore: GetStorageEventoAtivoStore(),
        ),
        permanent: true,
      );
    }
  }
}
