import 'package:flutter/foundation.dart';

/// Detecção de plataforma usada pela camada de dados, sem importar Flutter nela.
abstract final class PlataformaApp {
  static bool get ehWeb => kIsWeb;

  static bool get ehWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get ehAndroidOuIos =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get identificador =>
      kIsWeb ? 'WEB' : defaultTargetPlatform.name.toUpperCase();
}
