import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/fornecedor_localizacao_remote_datasource.dart';
import '../../data/datasources/remote/fornecedor_remote_datasource.dart';
import '../../data/repositories_impl/fornecedor_localizacao_repository_impl.dart';
import '../../data/repositories_impl/fornecedor_repository_impl.dart';
import '../../data/services/fornecedor_ai_generativa_service.dart';
import '../../domain/repositories/fornecedor_localizacao_repository.dart';
import '../../domain/repositories/fornecedor_repository.dart';
import '../../domain/usecases/gerenciar_fornecedor_localizacao.dart';
import '../../domain/usecases/gerenciar_fornecedores.dart';
import '../../presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import '../../presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';

abstract final class FornecedorBootstrap {
  static void register() {
    if (!Get.isRegistered<FornecedorRemoteDatasource>()) {
      Get.put<FornecedorRemoteDatasource>(
        FirebaseFornecedorRemoteDatasource(
          Get.find<FirebaseFirestore>(),
          storage: Get.find<FirebaseStorage>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FornecedorRepository>()) {
      Get.put<FornecedorRepository>(
        FornecedorRepositoryImpl(Get.find<FornecedorRemoteDatasource>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GerenciarFornecedores>()) {
      Get.put<GerenciarFornecedores>(
        GerenciarFornecedores(Get.find<FornecedorRepository>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FornecedorAiGenerativaService>()) {
      Get.lazyPut<FornecedorAiGenerativaService>(
        () => FornecedorAiGenerativaService(
          functions: Get.find<FirebaseFunctions>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorController>()) {
      Get.put(
        FornecedorController(
          fornecedorAiGenerativaService:
              Get.find<FornecedorAiGenerativaService>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FornecedorLocalizacaoRemoteDatasource>()) {
      Get.lazyPut<FornecedorLocalizacaoRemoteDatasource>(
        () => FornecedorLocalizacaoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorLocalizacaoRepository>()) {
      Get.lazyPut<FornecedorLocalizacaoRepository>(
        () => FornecedorLocalizacaoRepositoryImpl(
          Get.find<FornecedorLocalizacaoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GerenciarFornecedorLocalizacao>()) {
      Get.lazyPut<GerenciarFornecedorLocalizacao>(
        () => GerenciarFornecedorLocalizacao(
          Get.find<FornecedorLocalizacaoRepository>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorLocalizacaoController>()) {
      Get.lazyPut<FornecedorLocalizacaoController>(
        () => FornecedorLocalizacaoController(
          localizacao: Get.find<GerenciarFornecedorLocalizacao>(),
        ),
        fenix: true,
      );
    }
  }
}
