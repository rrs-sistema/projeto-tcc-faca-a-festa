import 'package:intl/date_symbol_data_local.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'app/faca_festa_app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'app/bootstrap/app_check_bootstrap.dart';
import 'app/bootstrap/firebase_services_bootstrap.dart';
import 'app/bootstrap/gift_offline_bootstrap.dart';
import 'app/bootstrap/push_notifications_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseServicesBootstrap.initialize();
  unawaited(AppCheckBootstrap.activate());

  try {
    await GetStorage.init().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('⚠️ GetStorage.init: $e');
  }

  try {
    await GiftOfflineBootstrap.initialize()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('⚠️ Falha ao iniciar banco local: $e');
  }

  try {
    await initializeDateFormatting('pt_BR', null)
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('⚠️ initializeDateFormatting: $e');
  }

  await PushNotificationsBootstrap.initialize();

  configLoading();
  AppBootstrap.registerControllers();

  runApp(const FacaFestaApp());
}
