import 'package:get/get.dart';

import '../../controllers/orcamento_gasto_controller.dart';
import '../../data/datasources/remote/orcamento_gasto_remote_datasource.dart';
import '../../data/repositories_impl/orcamento_gasto_repository_impl.dart';
import '../../domain/repositories/orcamento_gasto_repository.dart';
import '../../domain/usecases/gerenciar_orcamento_gastos.dart';

class OrcamentoGastoBootstrap {
  OrcamentoGastoBootstrap._();

  static void register() {
    if (!Get.isRegistered<OrcamentoGastoRemoteDatasource>()) {
      Get.lazyPut<OrcamentoGastoRemoteDatasource>(
        () => OrcamentoGastoRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<OrcamentoGastoRepository>()) {
      Get.lazyPut<OrcamentoGastoRepository>(
        () => OrcamentoGastoRepositoryImpl(
          Get.find<OrcamentoGastoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarOrcamentoGastos>()) {
      Get.lazyPut<GerenciarOrcamentoGastos>(
        () => GerenciarOrcamentoGastos(Get.find<OrcamentoGastoRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<OrcamentoGastoController>()) {
      Get.put(
        _novoController(),
        permanent: true,
      );
    }
  }

  static OrcamentoGastoController putController({
    String? tag,
    bool permanent = false,
  }) {
    register();
    if (Get.isRegistered<OrcamentoGastoController>(tag: tag)) {
      return Get.find<OrcamentoGastoController>(tag: tag);
    }

    return Get.put(
      _novoController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static OrcamentoGastoController findController({String? tag}) {
    register();
    return Get.find<OrcamentoGastoController>(tag: tag);
  }

  static OrcamentoGastoController _novoController() {
    return OrcamentoGastoController(
      gastosOrcamento: Get.find<GerenciarOrcamentoGastos>(),
    );
  }
}
