import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/cotacao_functions_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/cotacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/cotacao_repository_impl.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/domain/repositories/cotacao_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';

abstract final class CotacaoBootstrap {
  static void register() {
    if (!Get.isRegistered<CotacaoFunctionsDatasource>()) {
      Get.put<CotacaoFunctionsDatasource>(
        CotacaoFunctionsDatasource(
          functions: Get.find<FirebaseFunctions>(),
          httpsClient: Get.find<CallableHttpsClient>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CotacaoRemoteDatasource>()) {
      Get.put<CotacaoRemoteDatasource>(
        FirebaseCotacaoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
          functions: Get.find<CotacaoFunctionsDatasource>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CotacaoRepository>()) {
      Get.put<CotacaoRepository>(
        CotacaoRepositoryImpl(Get.find<CotacaoRemoteDatasource>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GerenciarCotacoes>()) {
      Get.put<GerenciarCotacoes>(
        GerenciarCotacoes(Get.find<CotacaoRepository>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CotacaoController>()) {
      Get.put(
        CotacaoController(
          gerenciarCotacoes: Get.find<GerenciarCotacoes>(),
          appController: Get.isRegistered<AppController>()
              ? Get.find<AppController>()
              : null,
          appControllerResolver: () => Get.isRegistered<AppController>()
              ? Get.find<AppController>()
              : null,
          fornecedorController: Get.isRegistered<FornecedorController>()
              ? Get.find<FornecedorController>()
              : null,
          fornecedorControllerResolver: () =>
              Get.isRegistered<FornecedorController>()
                  ? Get.find<FornecedorController>()
                  : null,
          orcamentoController: Get.isRegistered<OrcamentoController>()
              ? Get.find<OrcamentoController>()
              : null,
          orcamentoControllerResolver: () =>
              Get.isRegistered<OrcamentoController>()
                  ? Get.find<OrcamentoController>()
                  : null,
        ),
        permanent: true,
      );
    }
  }

  static CotacaoController findController() {
    register();
    return Get.find<CotacaoController>();
  }
}
