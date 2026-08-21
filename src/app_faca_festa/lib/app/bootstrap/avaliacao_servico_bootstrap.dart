import 'package:get/get.dart';

import '../../controllers/avaliacao/avaliacao_servico_controller.dart';
import '../../data/datasources/remote/avaliacao_servico_remote_datasource.dart';
import '../../data/repositories_impl/avaliacao_servico_repository_impl.dart';
import '../../domain/repositories/avaliacao_servico_repository.dart';
import '../../domain/usecases/gerenciar_avaliacoes_servico.dart';

class AvaliacaoServicoBootstrap {
  AvaliacaoServicoBootstrap._();

  static void register() {
    if (!Get.isRegistered<AvaliacaoServicoRemoteDatasource>()) {
      Get.lazyPut<AvaliacaoServicoRemoteDatasource>(
        () => AvaliacaoServicoRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AvaliacaoServicoRepository>()) {
      Get.lazyPut<AvaliacaoServicoRepository>(
        () => AvaliacaoServicoRepositoryImpl(
          Get.find<AvaliacaoServicoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarAvaliacoesServico>()) {
      Get.lazyPut<GerenciarAvaliacoesServico>(
        () => GerenciarAvaliacoesServico(
          Get.find<AvaliacaoServicoRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AvaliacaoServicoController>()) {
      Get.put(
        AvaliacaoServicoController(
          avaliacoes: Get.find<GerenciarAvaliacoesServico>(),
        ),
        permanent: true,
      );
    }
  }

  static AvaliacaoServicoController findController() {
    register();
    return Get.find<AvaliacaoServicoController>();
  }
}
