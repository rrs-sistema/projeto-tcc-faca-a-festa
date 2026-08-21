import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget capaRede({
  required String url,
  required BoxFit fit,
  required Widget fallback,
  Alignment alignment = Alignment.center,
}) {
  return CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    alignment: alignment,
    fadeInDuration: const Duration(milliseconds: 180),
    placeholder: (_, __) => fallback,
    errorWidget: (_, __, ___) => fallback,
  );
}
