import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/orcamento_gasto_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/orcamento_gasto_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/orcamento_gasto_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamento_gastos.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';

class OrcamentoGastoBootstrap {
  OrcamentoGastoBootstrap._();

  static void register() {
    if (!Get.isRegistered<OrcamentoGastoRemoteDatasource>()) {
      Get.lazyPut<OrcamentoGastoRemoteDatasource>(
        () => OrcamentoGastoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
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
      atualizarResumoGeral: () async {
        if (Get.isRegistered<OrcamentoController>()) {
          await Get.find<OrcamentoController>().calcularTotalPagoGeral();
        }
      },
    );
  }
}
