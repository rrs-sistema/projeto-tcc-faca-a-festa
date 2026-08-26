import 'package:get/get.dart';

import '../../controllers/contacao/cotacao_controller.dart';
import '../../data/datasources/remote/cotacao_functions_datasource.dart';
import '../../data/datasources/remote/cotacao_remote_datasource.dart';
import '../../data/repositories_impl/cotacao_repository_impl.dart';
import '../../domain/repositories/cotacao_repository.dart';
import '../../domain/usecases/gerenciar_cotacoes.dart';

abstract final class CotacaoBootstrap {
  static void register() {
    if (!Get.isRegistered<CotacaoFunctionsDatasource>()) {
      Get.put<CotacaoFunctionsDatasource>(
        CotacaoFunctionsDatasource(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CotacaoRemoteDatasource>()) {
      Get.put<CotacaoRemoteDatasource>(
        FirebaseCotacaoRemoteDatasource(),
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
  }

  static CotacaoController findController() {
    register();
    if (!Get.isRegistered<CotacaoController>()) {
      Get.put(CotacaoController(), permanent: true);
    }
    return Get.find<CotacaoController>();
  }
}
