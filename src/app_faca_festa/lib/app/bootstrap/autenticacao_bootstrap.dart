import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/autenticacao_remote_datasource.dart';
import '../../data/repositories_impl/autenticacao_repository_impl.dart';
import '../../domain/repositories/autenticacao_repository.dart';

abstract final class AutenticacaoBootstrap {
  static void register() {
    if (!Get.isRegistered<AutenticacaoRemoteDatasource>()) {
      Get.put<AutenticacaoRemoteDatasource>(
        FirebaseAutenticacaoRemoteDatasource(FirebaseAuth.instance),
        permanent: true,
      );
    }
    if (!Get.isRegistered<AutenticacaoRepository>()) {
      Get.put<AutenticacaoRepository>(
        AutenticacaoRepositoryImpl(
          Get.find<AutenticacaoRemoteDatasource>(),
        ),
        permanent: true,
      );
    }
  }
}
