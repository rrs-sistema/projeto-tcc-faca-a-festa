import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/evento_remote_ds.dart';
import '../../data/local/evento_ativo_store.dart';
import '../../data/repositories_impl/evento_repository_impl.dart';
import '../../domain/repositories/evento_repository.dart';
import '../../presentation/coordinators/evento_session_coordinator.dart';
import '../../presentation/modules/eventos/controllers/home_event_nav_controller.dart';
import '../../presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import '../../presentation/modules/eventos/controllers/evento_controller.dart';

/// Global composition root for the current-event session.
abstract final class EventoBootstrap {
  static void register() {
    if (!Get.isRegistered<EventoRemoteDatasource>()) {
      Get.put<EventoRemoteDatasource>(
        EventoRemoteDatasource(
          Get.find<FirebaseFirestore>(),
          storage: Get.find<FirebaseStorage>(),
        ),
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

    if (!Get.isRegistered<EventoCadastroController>()) {
      Get.put(
        EventoCadastroController(repository: Get.find<EventoRepository>()),
        permanent: true,
      ).carregarTiposEvento();
    }

    if (!Get.isRegistered<HomeEventNavController>()) {
      Get.put(HomeEventNavController(), permanent: true);
    }
  }
}
