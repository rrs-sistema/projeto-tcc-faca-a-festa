import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/cotacao_functions_datasource.dart';
import '../../data/datasources/remote/cotacao_remote_datasource.dart';
import '../../data/repositories_impl/cotacao_repository_impl.dart';
import '../../data/services/functions/callable_https_client.dart';
import '../../domain/repositories/cotacao_repository.dart';
import '../../domain/usecases/gerenciar_cotacoes.dart';
import '../../presentation/modules/cotacao/controllers/cotacao_controller.dart';

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
      Get.put(CotacaoController(), permanent: true);
    }
  }

  static CotacaoController findController() {
    register();
    return Get.find<CotacaoController>();
  }
}
