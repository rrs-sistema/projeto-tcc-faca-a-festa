import 'package:get/get.dart';

import '../../controllers/contacao/solicitacoes_controller.dart';
import '../../data/datasources/remote/solicitacoes_remote_datasource.dart';
import '../../data/repositories_impl/solicitacoes_repository_impl.dart';
import '../../domain/repositories/solicitacoes_repository.dart';
import '../../domain/usecases/gerenciar_solicitacoes.dart';

class SolicitacoesBootstrap {
  SolicitacoesBootstrap._();

  static void register() {
    if (!Get.isRegistered<SolicitacoesRemoteDatasource>()) {
      Get.lazyPut<SolicitacoesRemoteDatasource>(
        () => SolicitacoesRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SolicitacoesRepository>()) {
      Get.lazyPut<SolicitacoesRepository>(
        () => SolicitacoesRepositoryImpl(
          Get.find<SolicitacoesRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarSolicitacoes>()) {
      Get.lazyPut<GerenciarSolicitacoes>(
        () => GerenciarSolicitacoes(Get.find<SolicitacoesRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SolicitacoesController>()) {
      Get.put(
        SolicitacoesController(
          solicitacoesFornecedor: Get.find<GerenciarSolicitacoes>(),
        ),
        permanent: true,
      );
    }
  }

  static SolicitacoesController findController() {
    register();
    return Get.find<SolicitacoesController>();
  }
}
