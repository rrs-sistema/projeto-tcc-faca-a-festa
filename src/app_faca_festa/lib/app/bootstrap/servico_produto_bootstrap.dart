import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/servico_produto_remote_datasource.dart';
import '../../data/repositories_impl/servico_produto_repository_impl.dart';
import '../../domain/repositories/servico_produto_repository.dart';
import '../../domain/usecases/gerenciar_servicos_produto.dart';
import '../../presentation/modules/catalogo/controllers/servico_produto_controller.dart';

class ServicoProdutoBootstrap {
  ServicoProdutoBootstrap._();

  static void register() {
    if (!Get.isRegistered<ServicoProdutoRemoteDatasource>()) {
      Get.lazyPut<ServicoProdutoRemoteDatasource>(
        () => ServicoProdutoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServicoProdutoRepository>()) {
      Get.lazyPut<ServicoProdutoRepository>(
        () => ServicoProdutoRepositoryImpl(
          Get.find<ServicoProdutoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarServicosProduto>()) {
      Get.lazyPut<GerenciarServicosProduto>(
        () => GerenciarServicosProduto(Get.find<ServicoProdutoRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServicoProdutoController>()) {
      Get.put(
        ServicoProdutoController(
          servicos: Get.find<GerenciarServicosProduto>(),
        ),
        permanent: true,
      );
    }
  }

  static ServicoProdutoController findController() {
    register();
    return Get.find<ServicoProdutoController>();
  }
}
