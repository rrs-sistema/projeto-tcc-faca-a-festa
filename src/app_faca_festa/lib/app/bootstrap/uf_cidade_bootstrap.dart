import 'package:get/get.dart';

import '../../controllers/uf_cidade_controller.dart';
import '../../data/datasources/remote/uf_cidade_remote_datasource.dart';
import '../../data/repositories_impl/uf_cidade_repository_impl.dart';
import '../../domain/repositories/uf_cidade_repository.dart';
import '../../domain/usecases/gerenciar_ufs_cidades.dart';

class UfCidadeBootstrap {
  UfCidadeBootstrap._();

  static void register() {
    if (!Get.isRegistered<UfCidadeRemoteDatasource>()) {
      Get.lazyPut<UfCidadeRemoteDatasource>(
        () => UfCidadeRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<UfCidadeRepository>()) {
      Get.lazyPut<UfCidadeRepository>(
        () => UfCidadeRepositoryImpl(Get.find<UfCidadeRemoteDatasource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarUfsCidades>()) {
      Get.lazyPut<GerenciarUfsCidades>(
        () => GerenciarUfsCidades(Get.find<UfCidadeRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<UFCidadeController>()) {
      Get.put(
        UFCidadeController(ufsCidades: Get.find<GerenciarUfsCidades>()),
        permanent: true,
      );
    }
  }

  static UFCidadeController findController() {
    register();
    return Get.find<UFCidadeController>();
  }
}
