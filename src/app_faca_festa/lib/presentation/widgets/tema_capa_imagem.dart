import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tema_capa_rede.dart' if (dart.library.html) 'tema_capa_rede_web.dart'
    as rede;

class TemaCapaImagem extends StatelessWidget {
  const TemaCapaImagem({
    super.key,
    this.url,
    this.bytes,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallback,
    this.borderRadius,
  });

  final String? url;
  final Uint8List? bytes;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? fallback;
  final BorderRadius? borderRadius;

  bool get _temBytes => bytes != null && bytes!.isNotEmpty;
  bool get _temUrl => (url ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_temBytes) {
      child = Image.memory(
        bytes!,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
      );
    } else if (_temUrl) {
      child = rede.capaRede(
        url: url!.trim(),
        fit: fit,
        alignment: alignment,
        fallback: _placeholder(),
      );
    } else {
      child = _placeholder();
    }

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _placeholder() =>
      fallback ?? const ColoredBox(color: Color(0xFFE2E8F0));
}
