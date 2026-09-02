import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/servico_foto_remote_datasource.dart';
import '../../data/repositories_impl/servico_foto_repository_impl.dart';
import '../../domain/repositories/servico_foto_repository.dart';
import '../../domain/usecases/gerenciar_servico_fotos.dart';
import '../../presentation/modules/catalogo/controllers/servico_foto_controller.dart';

class ServicoFotoBootstrap {
  ServicoFotoBootstrap._();

  static void register() {
    if (!Get.isRegistered<ServicoFotoRemoteDatasource>()) {
      Get.lazyPut<ServicoFotoRemoteDatasource>(
        () => ServicoFotoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
          storage: Get.find<FirebaseStorage>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServicoFotoRepository>()) {
      Get.lazyPut<ServicoFotoRepository>(
        () =>
            ServicoFotoRepositoryImpl(Get.find<ServicoFotoRemoteDatasource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarServicoFotos>()) {
      Get.lazyPut<GerenciarServicoFotos>(
        () => GerenciarServicoFotos(Get.find<ServicoFotoRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServicoFotoController>()) {
      Get.put(
        ServicoFotoController(fotosServico: Get.find<GerenciarServicoFotos>()),
        permanent: true,
      );
    }
  }

  static ServicoFotoController findController() {
    register();
    return Get.find<ServicoFotoController>();
  }
}
