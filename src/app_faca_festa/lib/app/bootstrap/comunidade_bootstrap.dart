import 'package:get/get.dart';

import '../../controllers/comunidade_controller.dart';
import '../../data/datasources/remote/comunidade_remote_datasource.dart';
import '../../data/repositories_impl/comunidade_repository_impl.dart';
import '../../domain/repositories/comunidade_repository.dart';
import '../../domain/usecases/gerenciar_comunidade.dart';

class ComunidadeBootstrap {
  ComunidadeBootstrap._();

  static void register() {
    if (!Get.isRegistered<ComunidadeRemoteDatasource>()) {
      Get.lazyPut<ComunidadeRemoteDatasource>(
        () => ComunidadeRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ComunidadeRepository>()) {
      Get.lazyPut<ComunidadeRepository>(
        () => ComunidadeRepositoryImpl(Get.find<ComunidadeRemoteDatasource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarComunidade>()) {
      Get.lazyPut<GerenciarComunidade>(
        () => GerenciarComunidade(Get.find<ComunidadeRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ComunidadeController>()) {
      Get.put(
        ComunidadeController(comunidade: Get.find<GerenciarComunidade>()),
        permanent: true,
      );
    }
  }

  static ComunidadeController findController() {
    register();
    return Get.find<ComunidadeController>();
  }
}
