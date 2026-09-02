import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

abstract final class AppCheckBootstrap {
  static Future<void> activate() async {
    try {
      await FirebaseAppCheck.instance
          .activate(
            providerWeb: kDebugMode
                ? WebDebugProvider()
                : ReCaptchaV3Provider(
                    '6LcKnYstAAAAAM8kfpp132CwtRGEER1BrRTLiI8H',
                  ),
            providerAndroid: kDebugMode
                ? AndroidDebugProvider()
                : AndroidPlayIntegrityProvider(),
            providerApple:
                kDebugMode ? AppleDebugProvider() : AppleDeviceCheckProvider(),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('⚠️ App Check indisponível, seguindo sem ele: $e');
    }
  }
}
