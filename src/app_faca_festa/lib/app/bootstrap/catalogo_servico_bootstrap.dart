import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/catalogo_servico_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/catalogo_servico_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_servico_repository.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_catalogo_servico.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';

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
          auditoria: Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : const AuditoriaRegistrarVazio(),
          auditoriaResolver: () => Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : null,
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<SubcategoriaServicoController>()) {
      Get.put(
        SubcategoriaServicoController(
          catalogo: Get.find<GerenciarCatalogoServico>(),
          sincronizarCategorias: () =>
              Get.find<CategoriaServicoController>().carregarCategorias(),
        ),
        permanent: true,
      );
    }
  }
}
