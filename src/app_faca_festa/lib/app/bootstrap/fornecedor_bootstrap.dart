import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/fornecedor_remote_datasource.dart';
import '../../data/repositories_impl/fornecedor_repository_impl.dart';
import '../../domain/repositories/fornecedor_repository.dart';
import '../../domain/usecases/gerenciar_fornecedores.dart';

abstract final class FornecedorBootstrap {
  static void register() {
    if (!Get.isRegistered<FornecedorRemoteDatasource>()) {
      Get.put<FornecedorRemoteDatasource>(
        FirebaseFornecedorRemoteDatasource(FirebaseFirestore.instance),
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
  }
}
