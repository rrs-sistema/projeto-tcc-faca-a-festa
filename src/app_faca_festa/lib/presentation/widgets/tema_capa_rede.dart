import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/no_sqflite_cache_manager.dart';

Widget capaRede({
  required String url,
  required BoxFit fit,
  required Widget fallback,
  Alignment alignment = Alignment.center,
}) {
  return CachedNetworkImage(
    imageUrl: url,
    cacheManager: AdaptiveCacheManager.instance,
    fit: fit,
    alignment: alignment,
    fadeInDuration: const Duration(milliseconds: 180),
    placeholder: (_, __) => fallback,
    errorWidget: (_, __, ___) => fallback,
  );
}
