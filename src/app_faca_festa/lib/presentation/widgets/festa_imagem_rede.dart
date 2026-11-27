import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/no_sqflite_cache_manager.dart';

/// Imagem remota com cache em disco: o que já foi visto abre sem internet.
class FestaImagemRede extends StatelessWidget {
  const FestaImagemRede(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.erro,
    this.carregando,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? erro;
  final Widget? carregando;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AdaptiveCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => carregando ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) =>
          erro ??
          const Center(
            child:
                Icon(Icons.image_not_supported_outlined, color: Colors.black38),
          ),
    );
  }
}

/// Para `CircleAvatar`, `DecorationImage` e afins.
ImageProvider festaImagemProvider(String url) => CachedNetworkImageProvider(url,
    cacheManager: AdaptiveCacheManager.instance);
