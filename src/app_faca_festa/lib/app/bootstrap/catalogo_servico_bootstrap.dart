import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/catalogo_servico_remote_datasource.dart';
import '../../data/repositories_impl/catalogo_servico_repository_impl.dart';
import '../../domain/repositories/catalogo_servico_repository.dart';
import '../../domain/usecases/gerenciar_catalogo_servico.dart';
import '../../presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import '../../presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';

abstract final class CatalogoServicoBootstrap {
  static void register() {
    if (!Get.isRegistered<CatalogoServicoRemoteDatasource>()) {
      Get.lazyPut<CatalogoServicoRemoteDatasource>(
        () => CatalogoServicoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CatalogoServicoRepository>()) {
      Get.lazyPut<CatalogoServicoRepository>(
        () => CatalogoServicoRepositoryImpl(
          Get.find<CatalogoServicoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GerenciarCatalogoServico>()) {
      Get.lazyPut<GerenciarCatalogoServico>(
        () => GerenciarCatalogoServico(Get.find<CatalogoServicoRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CategoriaServicoController>()) {
      Get.put(
        CategoriaServicoController(
          catalogo: Get.find<GerenciarCatalogoServico>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<SubcategoriaServicoController>()) {
      Get.put(
        SubcategoriaServicoController(
          catalogo: Get.find<GerenciarCatalogoServico>(),
        ),
        permanent: true,
      );
    }
  }
}
