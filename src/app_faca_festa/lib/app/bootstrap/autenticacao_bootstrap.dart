import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/autenticacao_remote_datasource.dart';
import '../../data/repositories_impl/autenticacao_repository_impl.dart';
import '../../data/services/functions/callable_https_client.dart';
import '../../domain/repositories/autenticacao_repository.dart';
import '../../presentation/modules/auth/controllers/login_controller.dart';
import '../../presentation/modules/auth/controllers/password_reset_controller.dart';
import '../../presentation/modules/auth/controllers/register_controller.dart';
import '../../presentation/modules/auth/controllers/totp_mfa_controller.dart';

abstract final class AutenticacaoBootstrap {
  static void register() {
    if (!Get.isRegistered<AutenticacaoRemoteDatasource>()) {
      Get.put<AutenticacaoRemoteDatasource>(
        FirebaseAutenticacaoRemoteDatasource(
          Get.find<FirebaseAuth>(),
          functions: Get.find<FirebaseFunctions>(),
          httpsClient: Get.find<CallableHttpsClient>(),
        ),
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
    if (!Get.isRegistered<LoginController>()) {
      Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    }
    if (!Get.isRegistered<RegisterController>()) {
      Get.lazyPut<RegisterController>(() => RegisterController(), fenix: true);
    }
    if (!Get.isRegistered<PasswordResetController>()) {
      Get.lazyPut<PasswordResetController>(
        () => PasswordResetController(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<TotpMfaController>()) {
      Get.lazyPut<TotpMfaController>(() => TotpMfaController(), fenix: true);
    }
  }
}
