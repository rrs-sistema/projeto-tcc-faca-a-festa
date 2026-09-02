import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupNotificationChannel() async {
  if (!Platform.isAndroid) return;

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações Importantes',
    description: 'Canal usado para notificações de avaliações',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  const windowsSettings = WindowsInitializationSettings(
    appName: 'Faça a Festa',
    appUserModelId: 'com.rrs.system.technology.facafesta',
    guid: 'd49b0314-ee7f-4b6d-9b1b-7b0f4d2f8f10',
  );

  const settings = InitializationSettings(
    android: androidSettings,
    windows: windowsSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);
}

Future<void> initPushNotifications({
  required FirebaseMessaging messaging,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    await messaging.requestPermission();
    await messaging.getToken();
  } else {
    debugPrint('Push FCM não suportado nesta plataforma.');
  }
}
