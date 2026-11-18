import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class TerritorioMapaZoom extends StatelessWidget {
  const TerritorioMapaZoom({super.key, required this.cor});

  final Color cor;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final mapa = MapController.of(context);

    void alterarZoom(double passo) {
      final atual = mapa.camera;
      mapa.move(atual.center, atual.clampZoom(atual.zoom + passo));
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Aproximar mapa',
            icon: const Icon(Icons.add_rounded),
            color: cor,
            onPressed: camera.clampZoom(camera.zoom + 1) > camera.zoom
                ? () => alterarZoom(1)
                : null,
          ),
          IconButton(
            tooltip: 'Afastar mapa',
            icon: const Icon(Icons.remove_rounded),
            color: cor,
            onPressed: camera.clampZoom(camera.zoom - 1) < camera.zoom
                ? () => alterarZoom(-1)
                : null,
          ),
        ],
      ),
    );
  }
}
