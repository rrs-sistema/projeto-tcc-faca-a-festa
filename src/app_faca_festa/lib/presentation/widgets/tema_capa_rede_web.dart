// Arquivo carregado só via import condicional (`dart.library.html`).
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final Set<String> _viewsRegistradas = <String>{};

Widget capaRede({
  required String url,
  required BoxFit fit,
  required Widget fallback,
  Alignment alignment = Alignment.center,
}) {
  final viewType = 'faca-festa-capa-${url.hashCode}-${alignment.x}-${alignment.y}';
  if (_viewsRegistradas.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..draggable = false;
      final x = ((alignment.x + 1) * 50).clamp(0, 100);
      final y = ((alignment.y + 1) * 50).clamp(0, 100);
      img.style
        ..width = '100%'
        ..height = '100%'
        ..border = '0'
        ..objectFit = _cssFit(fit)
        ..objectPosition = '$x% $y%'
        ..pointerEvents = 'none';
      return img;
    });
  }
  return HtmlElementView(viewType: viewType);
}

String _cssFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
    default:
      return 'cover';
  }
}
