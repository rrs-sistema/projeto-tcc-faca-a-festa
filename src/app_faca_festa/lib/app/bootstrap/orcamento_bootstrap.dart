import 'package:get/get.dart';

import '../../controllers/orcamento_controller.dart';
import '../../data/datasources/remote/orcamento_remote_datasource.dart';
import '../../data/repositories_impl/orcamento_repository_impl.dart';
import '../../domain/repositories/orcamento_repository.dart';
import '../../domain/usecases/gerenciar_orcamentos.dart';

class OrcamentoBootstrap {
  OrcamentoBootstrap._();

  static void register() {
    if (!Get.isRegistered<OrcamentoRemoteDatasource>()) {
      Get.lazyPut<OrcamentoRemoteDatasource>(
        () => OrcamentoRemoteDatasource(),
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
