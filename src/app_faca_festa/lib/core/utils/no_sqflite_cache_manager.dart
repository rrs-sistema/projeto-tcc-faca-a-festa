import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cache de imagens. Um único [CacheManager] por chave — várias instâncias
/// corrompem o JSON de índice no Windows (`FormatException` no decode).
class AdaptiveCacheManager {
  AdaptiveCacheManager._();

  static const desktopKey = 'faca_festa_web_cache';
  static const mobileKey = 'faca_festa_mobile_cache';

  static CacheManager? _instance;

  static CacheManager get instance => _instance ??= _create();

  static CacheManager _create() {
    if (kIsWeb) {
      return CacheManager(
        Config(
          desktopKey,
          stalePeriod: const Duration(days: 3),
          maxNrOfCacheObjects: 50,
          fileService: HttpFileService(),
        ),
      );
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      return CacheManager(
        Config(
          desktopKey,
          stalePeriod: const Duration(days: 3),
          maxNrOfCacheObjects: 50,
          repo: _ResilientJsonCacheInfoRepository(databaseName: desktopKey),
          fileService: HttpFileService(),
        ),
      );
    }

    return CacheManager(
      Config(
        mobileKey,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 100,
      ),
    );
  }
}

class _ResilientJsonCacheInfoRepository extends JsonCacheInfoRepository {
  _ResilientJsonCacheInfoRepository({required String databaseName})
      : _databaseName = databaseName,
        super(databaseName: databaseName);

  final String _databaseName;

  @override
  Future<bool> open() async {
    await _deleteIndexIfCorrupted();
    return super.open();
  }

  Future<void> _deleteIndexIfCorrupted() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File(p.join(directory.path, '$_databaseName.json'));
      if (!await file.exists()) return;

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        await file.delete();
        return;
      }
      jsonDecode(content);
    } catch (_) {
      try {
        await deleteDataFile();
      } catch (_) {}
    }
  }
}
