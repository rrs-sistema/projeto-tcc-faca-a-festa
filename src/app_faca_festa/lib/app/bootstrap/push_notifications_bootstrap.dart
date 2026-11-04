import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/push/notification_service.dart';
import 'package:app_faca_festa/core/platform/plataforma_app.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/chat_notifications_controller.dart';

abstract final class PushNotificationsBootstrap {
  static Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        await initLocalNotifications();
        await setupNotificationChannel();
      }
      if (!kIsWeb && !PlataformaApp.ehAndroidOuIos) return;
      final controller = Get.put(
        ChatNotificationsController(Get.find<FirebaseMessaging>()),
        permanent: true,
      );
      await controller.initialize();
    } catch (e) {
      debugPrint('Falha ao iniciar notificações: ${e.runtimeType}');
    }
  }
}
