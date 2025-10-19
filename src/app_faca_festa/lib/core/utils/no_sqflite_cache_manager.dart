import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 🔹 Gerenciador de cache adaptável (sem uso de sqflite no Web/Desktop)
class AdaptiveCacheManager {
  static CacheManager get instance {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      // ✅ Modo leve: cache temporário em memória e arquivos HTTP
      return CacheManager(
        Config(
          'faca_festa_web_cache',
          stalePeriod: const Duration(days: 3),
          maxNrOfCacheObjects: 50,
          fileService: HttpFileService(), // usa HTTP puro
        ),
      );
    }

    // ✅ Modo completo: usa cache em disco (Android/iOS)
    return CacheManager(
      Config(
        'faca_festa_mobile_cache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 100,
      ),
    );
  }
}
