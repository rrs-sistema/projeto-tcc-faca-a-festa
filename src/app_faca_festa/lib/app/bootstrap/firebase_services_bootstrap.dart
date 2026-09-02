import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../../data/services/functions/callable_https_client.dart';

abstract final class FirebaseServicesBootstrap {
  static void register() {
    if (!Get.isRegistered<FirebaseFirestore>()) {
      Get.put<FirebaseFirestore>(FirebaseFirestore.instance, permanent: true);
    }
    if (!Get.isRegistered<FirebaseAuth>()) {
      Get.put<FirebaseAuth>(FirebaseAuth.instance, permanent: true);
    }
    if (!Get.isRegistered<CallableHttpsClient>()) {
      Get.put<CallableHttpsClient>(
        CallableHttpsClient(auth: Get.find<FirebaseAuth>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FirebaseStorage>()) {
      Get.put<FirebaseStorage>(FirebaseStorage.instance, permanent: true);
    }
    if (!Get.isRegistered<FirebaseMessaging>()) {
      Get.put<FirebaseMessaging>(FirebaseMessaging.instance, permanent: true);
    }
    if (!Get.isRegistered<FirebaseFunctions>()) {
      Get.put<FirebaseFunctions>(
        FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
        permanent: true,
      );
    }
  }
}
