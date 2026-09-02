import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/tema_festa_remote_datasource.dart';
import '../../data/repositories_impl/tema_festa_repository_impl.dart';
import '../../data/services/functions/callable_https_client.dart';
import '../../domain/repositories/evento_repository.dart';
import '../../domain/repositories/tema_festa_repository.dart';
import '../../domain/usecases/gerenciar_temas_festa.dart';
import '../../presentation/modules/tema/controllers/event_theme_controller.dart';
import '../../presentation/modules/tema/controllers/tema_festa_controller.dart';

class TemaFestaBootstrap {
  TemaFestaBootstrap._();

  static void register() {
    if (!Get.isRegistered<TemaFestaRemoteDatasource>()) {
      Get.lazyPut<TemaFestaRemoteDatasource>(
        () => TemaFestaRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
          httpsClient: Get.find<CallableHttpsClient>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<TemaFestaRepository>()) {
      Get.lazyPut<TemaFestaRepository>(
        () => TemaFestaRepositoryImpl(Get.find<TemaFestaRemoteDatasource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarTemasFesta>()) {
      Get.lazyPut<GerenciarTemasFesta>(
        () => GerenciarTemasFesta(Get.find<TemaFestaRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<TemaFestaController>()) {
      Get.put(
        TemaFestaController(temasFesta: Get.find<GerenciarTemasFesta>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventThemeController>()) {
      Get.put(
        EventThemeController(
          temasFesta: Get.find<GerenciarTemasFesta>(),
          eventoRepository: Get.find<EventoRepository>(),
        ),
        permanent: true,
      );
    }
  }

  static TemaFestaController findController() {
    register();
    return Get.find<TemaFestaController>();
  }
}
