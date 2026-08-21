import 'package:get/get.dart';

import '../../controllers/tema/tema_festa_controller.dart';
import '../../data/datasources/remote/tema_festa_remote_datasource.dart';
import '../../data/repositories_impl/tema_festa_repository_impl.dart';
import '../../domain/repositories/tema_festa_repository.dart';
import '../../domain/usecases/gerenciar_temas_festa.dart';

class TemaFestaBootstrap {
  TemaFestaBootstrap._();

  static void register() {
    if (!Get.isRegistered<TemaFestaRemoteDatasource>()) {
      Get.lazyPut<TemaFestaRemoteDatasource>(
        () => TemaFestaRemoteDatasource(),
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
  }

  static TemaFestaController findController() {
    register();
    return Get.find<TemaFestaController>();
  }
}
