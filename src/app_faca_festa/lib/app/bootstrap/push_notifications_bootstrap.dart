import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/push/notification_service.dart';

abstract final class PushNotificationsBootstrap {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await initLocalNotifications();
    await setupNotificationChannel();
    await initPushNotifications(messaging: Get.find<FirebaseMessaging>());
  }
}
