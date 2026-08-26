import 'package:get/get.dart';

import '../../controllers/auditoria/auditoria_controller.dart';
import '../../data/datasources/remote/auditoria_remote_datasource.dart';
import '../../data/repositories_impl/auditoria_repository_impl.dart';
import '../../domain/repositories/auditoria_repository.dart';
import '../../domain/usecases/gerenciar_auditoria.dart';

class AuditoriaBootstrap {
  AuditoriaBootstrap._();

  static void register() {
    if (!Get.isRegistered<AuditoriaRemoteDatasource>()) {
      Get.lazyPut<AuditoriaRemoteDatasource>(
        () => AuditoriaRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AuditoriaRepository>()) {
      Get.lazyPut<AuditoriaRepository>(
        () => AuditoriaRepositoryImpl(Get.find<AuditoriaRemoteDatasource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarAuditoria>()) {
      Get.lazyPut<GerenciarAuditoria>(
        () => GerenciarAuditoria(Get.find<AuditoriaRepository>()),
        fenix: true,
      );
    }
  }

  static AuditoriaController controllerAdmin() {
    register();
    final tag = 'auditoria_admin';
    if (Get.isRegistered<AuditoriaController>(tag: tag)) {
      return Get.find<AuditoriaController>(tag: tag);
    }
    return Get.put(
      AuditoriaController(
        gerenciarAuditoria: Get.find<GerenciarAuditoria>(),
        escopoAdmin: true,
      ),
      tag: tag,
    );
  }

  static AuditoriaController controllerFornecedor(String idFornecedor) {
    register();
    final tag = 'auditoria_fornecedor_$idFornecedor';
    if (Get.isRegistered<AuditoriaController>(tag: tag)) {
      return Get.find<AuditoriaController>(tag: tag);
    }
    return Get.put(
      AuditoriaController(
        gerenciarAuditoria: Get.find<GerenciarAuditoria>(),
        escopoAdmin: false,
        idFornecedor: idFornecedor,
      ),
      tag: tag,
    );
  }
}
