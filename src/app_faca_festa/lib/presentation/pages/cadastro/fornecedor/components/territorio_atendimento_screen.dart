// ignore_for_file: use_build_context_synchronously

import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import '../../../../../controllers/admin/admin_territorio_controller.dart';
import '../../../../../controllers/tema/event_theme_controller.dart';
import './../../../../../data/models/model.dart';

import 'dart:ui';

Future<void> showAddTerritorioBottomSheet(
  BuildContext context,
  String idFornecedor, {
  TerritorioModel? existente,
}) async {
  final theme = Get.find<EventThemeController>();
  final cor = theme.primaryColor.value;
  final gradiente = theme.gradient.value;
  final controller = Get.find<AdminTerritorioController>();

  // 🔹 Controle inicial baseado no modo
  final descricaoCtrl = TextEditingController(text: existente?.descricao ?? '');
  final raioKm = (existente?.raioKm ?? 10.0).obs;
  final modo = (existente?.tipoCobertura ?? 'raio').obs;
  final desenhando = false.obs;

  // 🔹 Converte coordenadas existentes em pontos de mapa
  final pontos = <LatLng>[].obs;
  if (existente != null) {
    if (modo.value == 'raio' && existente.latitude != null && existente.longitude != null) {
      pontos.assign(LatLng(existente.latitude!, existente.longitude!));
    } else if (modo.value == 'regiao' && existente.regioes != null) {
      pontos.assignAll(existente.regioes!.map((r) {
        final parts = r.split(',');
        return LatLng(double.parse(parts[0]), double.parse(parts[1]));
      }));
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final isDarkMode = false.obs;

      return Obx(() => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              gradient: gradiente,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                // ================= MAPA =================
                FlutterMap(
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter:
                        pontos.isNotEmpty ? pontos.first : const LatLng(-25.4284, -49.2733),
                    initialZoom: pontos.isNotEmpty ? 12.5 : 11,
                    onTap: (tapPosition, latLng) {
                      if (modo.value == "raio") {
                        pontos.assignAll([latLng]);
                      } else if (modo.value == "regiao" && desenhando.value) {
                        pontos.add(latLng);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDarkMode.value
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'app_faca_festa',
                    ),

                    // Territórios existentes
                    Obx(() => CircleLayer(
                          circles: controller.territorios
                              .where((t) =>
                                  t.tipoCobertura == 'raio' &&
                                  t.latitude != null &&
                                  t.longitude != null)
                              .map((t) => CircleMarker(
                                    point: LatLng(t.latitude!, t.longitude!),
                                    radius: (t.raioKm ?? 10) * 1000,
                                    color: cor.withValues(alpha: 0.25),
                                    borderColor: cor.withValues(alpha: 0.6),
                                    borderStrokeWidth: 2,
                                    useRadiusInMeter: true,
                                  ))
                              .toList(),
                        )),

                    // Novo círculo (modo Raio)
                    if (modo.value == "raio" && pontos.isNotEmpty)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: pontos.first,
                            radius: raioKm.value * 1000,
                            color: cor.withValues(alpha: 0.25),
                            borderColor: cor,
                            borderStrokeWidth: 3,
                            useRadiusInMeter: true,
                          ),
                        ],
                      ),

                    // Novo polígono (modo Região)
                    if (modo.value == "regiao" && pontos.isNotEmpty)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: pontos.toList(),
                            color: cor.withValues(alpha: 0.25),
                            borderColor: cor,
                            borderStrokeWidth: 2.5,
                          ),
                        ],
                      ),

                    // Marcadores dos pontos
                    MarkerLayer(
                      markers: pontos
                          .map((p) => Marker(
                                point: p,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on,
                                    color: Colors.redAccent, size: 34),
                              ))
                          .toList(),
                    ),
                  ],
                ),

                // ================= HEADER =================
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        child: Column(
                          children: [
                            Text(
                              existente == null
                                  ? (modo.value == "raio"
                                      ? "Novo Território - Raio de Cobertura"
                                      : "Novo Território - Região Desenhada")
                                  : (modo.value == "raio"
                                      ? "Editar Território (Raio)"
                                      : "Editar Território (Região)"),
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: cor),
                            ),
                            const SizedBox(height: 4),
                            if (modo.value == "raio")
                              Column(
                                children: [
                                  Text(
                                    "Raio: ${raioKm.value.toStringAsFixed(1)} km",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Slider(
                                    value: raioKm.value,
                                    min: 1,
                                    max: 100,
                                    divisions: 99,
                                    label: "${raioKm.value.toStringAsFixed(0)} km",
                                    activeColor: cor,
                                    onChanged: (v) => raioKm.value = v,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                ),

                // ================= BOTÕES DE AÇÃO =================
                Positioned(
                  right: 12,
                  bottom: 200,
                  child: Column(
                    children: [
                      _mapButton(Icons.gps_fixed, "Centralizar", cor, () async {
                        final loc = await Geolocator.getCurrentPosition();
                        controller.mapController.move(LatLng(loc.latitude, loc.longitude), 13);
                      }),
                      const SizedBox(height: 10),
                      _mapButton(
                        modo.value == "raio" ? Icons.public : Icons.polyline_outlined,
                        "Alternar modo",
                        cor,
                        () {
                          modo.value = modo.value == "raio" ? "regiao" : "raio";
                          pontos.clear();
                          desenhando.value = false;
                        },
                      ),
                      const SizedBox(height: 10),
                      if (modo.value == "regiao")
                        _mapButton(
                          Icons.brush,
                          desenhando.value ? "Finalizar desenho" : "Desenhar região",
                          desenhando.value ? Colors.white : cor,
                          () => desenhando.toggle(),
                          active: desenhando.value,
                        ),
                      const SizedBox(height: 10),
                      _mapButton(Icons.delete_outline, "Limpar pontos", Colors.redAccent,
                          () => pontos.clear()),
                    ],
                  ),
                ),

                // ================= RODAPÉ =================
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Get.back(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: cor.withValues(alpha: 0.6)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text("Cancelar",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600, color: cor)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save, color: Colors.white),
                                label: Text(existente == null ? "Salvar" : "Atualizar",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (pontos.isEmpty) {
                                    Get.snackbar("Aviso", "Adicione ao menos um ponto no mapa.",
                                        backgroundColor: Colors.orange, colorText: Colors.white);
                                    return;
                                  }

                                  final model = TerritorioModel(
                                    idTerritorio: existente?.idTerritorio ?? const Uuid().v4(),
                                    idFornecedor: idFornecedor,
                                    ativo: true,
                                    descricao: descricaoCtrl.text.isEmpty
                                        ? "Território ${DateTime.now().day}/${DateTime.now().month}"
                                        : descricaoCtrl.text,
                                    tipoCobertura: modo.value,
                                    raioKm: modo.value == "raio" ? raioKm.value : null,
                                    latitude: modo.value == "raio" && pontos.isNotEmpty
                                        ? pontos.first.latitude
                                        : null,
                                    longitude: modo.value == "raio" && pontos.isNotEmpty
                                        ? pontos.first.longitude
                                        : null,
                                    regioes: modo.value == "regiao"
                                        ? pontos.map((p) => "${p.latitude},${p.longitude}").toList()
                                        : null,
                                  );

                                  await controller.salvarTerritorio(model);
                                  Get.back();

                                  Get.dialog(Center(
                                    child: Lottie.asset(
                                      'assets/animations/success.json',
                                      width: 180,
                                      repeat: false,
                                    ),
                                  ));
                                  await Future.delayed(const Duration(seconds: 2));
                                  Get.back();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                ),
              ],
            ),
          ));
    },
  );
}

// 🔹 Botão auxiliar
Widget _mapButton(IconData icon, String tooltip, Color cor, VoidCallback onTap,
    {bool active = false}) {
  return Tooltip(
    message: tooltip,
    child: FloatingActionButton.small(
      heroTag: tooltip,
      backgroundColor: active ? cor : Colors.white,
      onPressed: onTap,
      child: Icon(icon, color: active ? Colors.white : cor),
    ),
  ).animate().fadeIn(duration: 250.ms);
}
