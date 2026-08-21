import 'package:get/get.dart';

import '../../controllers/fornecedor/fornecedor_recomendacao_controller.dart';
import '../../data/datasources/remote/fornecedor_recomendacao_remote_datasource.dart';
import '../../data/repositories_impl/fornecedor_recomendacao_repository_impl.dart';
import '../../domain/repositories/fornecedor_recomendacao_repository.dart';
import '../../domain/usecases/gerenciar_fornecedor_recomendacoes.dart';

class FornecedorRecomendacaoBootstrap {
  FornecedorRecomendacaoBootstrap._();

  static void register() {
    if (!Get.isRegistered<FornecedorRecomendacaoRemoteDatasource>()) {
      Get.lazyPut<FornecedorRecomendacaoRemoteDatasource>(
        () => FornecedorRecomendacaoRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FornecedorRecomendacaoRepository>()) {
      Get.lazyPut<FornecedorRecomendacaoRepository>(
        () => FornecedorRecomendacaoRepositoryImpl(
          Get.find<FornecedorRecomendacaoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarFornecedorRecomendacoes>()) {
      Get.lazyPut<GerenciarFornecedorRecomendacoes>(
        () => GerenciarFornecedorRecomendacoes(
          Get.find<FornecedorRecomendacaoRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FornecedorRecomendacaoController>()) {
      Get.put(
        FornecedorRecomendacaoController(
          recomendacoesFornecedor: Get.find<GerenciarFornecedorRecomendacoes>(),
        ),
        permanent: true,
      );
    }
  }

  static FornecedorRecomendacaoController findController() {
    register();
    return Get.find<FornecedorRecomendacaoController>();
  }
}
