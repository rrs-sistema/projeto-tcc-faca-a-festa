import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories_impl/push_token_repository_impl.dart';
import '../../data/services/convite/abrir_convite_por_token_service.dart';
import '../../data/services/functions/callable_https_client.dart';
import '../../domain/repositories/push_token_repository.dart';
import '../../presentation/modules/app/controllers/app_controller.dart';

abstract final class AppControllerBootstrap {
  static void register() {
    if (!Get.isRegistered<PushTokenRepository>()) {
      Get.lazyPut<PushTokenRepository>(
        () => FirebasePushTokenRepository(
          messaging: Get.find<FirebaseMessaging>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AbrirConvitePorTokenService>()) {
      Get.lazyPut<AbrirConvitePorTokenService>(
        () => AbrirConvitePorTokenService(
          functions: Get.find<FirebaseFunctions>(),
          auth: Get.find<FirebaseAuth>(),
          httpsClient: Get.find<CallableHttpsClient>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AppController>()) {
      Get.lazyPut<AppController>(() => AppController(), fenix: true);
    }
  }
}
