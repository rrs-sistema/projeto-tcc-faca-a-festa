import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> initLocalNotifications() async {
  // Web: sem flutter_local_notifications aqui
}

Future<void> setupNotificationChannel() async {
  // Web: não usa Android channel
}

Future<void> initPushNotifications({
  required FirebaseMessaging messaging,
}) async {
  await messaging.requestPermission();
  await messaging.getToken();
}
