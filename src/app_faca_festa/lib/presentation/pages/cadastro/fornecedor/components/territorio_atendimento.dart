// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import './../../../../../controllers/event_theme_controller.dart';
import '../../../../../data/models/model.dart';

Future<void> showAddTerritorioBottomSheet(
  BuildContext context,
  String idFornecedor,
) async {
  final theme = Get.find<EventThemeController>();
  final gradiente = theme.gradient.value;
  final cor = theme.primaryColor.value;

  final descricaoCtrl = TextEditingController();
  final raioKm = 10.0.obs;
  final RxList<LatLng> pontos = <LatLng>[].obs;
  final RxList<String> cidadesSelecionadas = <String>[].obs;
  final RxList<TerritorioModel> territoriosCadastrados = <TerritorioModel>[].obs;
  final RxString modoAtendimento = "raio".obs;
  final mapController = MapController();

  // 🔹 Carrega territórios cadastrados do fornecedor
  Future<void> carregarTerritoriosFornecedor() async {
    final snap = await FirebaseFirestore.instance
        .collection('territorio')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('ativo', isEqualTo: true)
        .get();
    territoriosCadastrados.value = snap.docs.map((d) => TerritorioModel.fromMap(d.data())).toList();
  }

  await carregarTerritoriosFornecedor();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradiente,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 20),
        child: SafeArea(
          child: Stack(
            children: [
              // === MAPA ===

              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-15.78, -47.93),
                  initialZoom: 5.2,
                  onTap: (tapPosition, latLng) async {
                    try {
                      HapticFeedback.lightImpact();
                      pontos.add(latLng);

                      // Verifica permissão antes de tentar geocoding
                      LocationPermission permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied ||
                          permission == LocationPermission.deniedForever) {
                        permission = await Geolocator.requestPermission();
                      }

                      String cidade = "Local desconhecido";
                      try {
                        final placemarks = await placemarkFromCoordinates(
                          latLng.latitude,
                          latLng.longitude,
                        );
                        if (placemarks.isNotEmpty && placemarks.first.locality != null) {
                          cidade = placemarks.first.locality!;
                        }
                      } catch (e) {
                        debugPrint("⚠️ Erro no geocoding: $e");
                      }
                      cidadesSelecionadas.add(cidade);

                      // Auto-detecção de macroregião
                      if (modoAtendimento.value == "regiao") {
                        final lat = latLng.latitude;
                        String regiao;
                        if (lat < -25) {
                          regiao = "Sul";
                        } else if (lat < -15) {
                          regiao = "Sudeste";
                        } else if (lat < -5) {
                          regiao = "Centro-Oeste";
                        } else {
                          regiao = "Nordeste";
                        }

                        if (!cidadesSelecionadas.contains(regiao)) {
                          cidadesSelecionadas.add(regiao);
                          Get.snackbar(
                            "Região detectada automaticamente",
                            regiao,
                            backgroundColor: Colors.white,
                            colorText: theme.primaryColor.value,
                          );
                        }
                      }
                    } catch (e) {
                      Get.snackbar(
                        "Erro",
                        "Não foi possível obter o nome da cidade.",
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                    }
                  },
                ),

                // Agora apenas os layers são reativos
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'app_faca_festa',
                  ),

                  // === Territórios existentes (raio) ===
                  Obx(() {
                    if (territoriosCadastrados.isEmpty) return const SizedBox();
                    final listaRaio = territoriosCadastrados
                        .where((t) => t.tipoCobertura == 'raio' && t.latitude != null)
                        .toList();
                    return CircleLayer(
                      circles: listaRaio
                          .map((t) => CircleMarker(
                                point: LatLng(t.latitude!, t.longitude!),
                                radius: (t.raioKm ?? 10) * 1000,
                                color: Colors.blueAccent.withValues(alpha: 0.25),
                                borderStrokeWidth: 2,
                                borderColor: Colors.blueAccent,
                                useRadiusInMeter: true,
                              ))
                          .toList(),
                    );
                  }),

                  // === Territórios existentes (região) ===
                  Obx(() {
                    if (territoriosCadastrados.isEmpty) return const SizedBox();
                    final listaRegiao = territoriosCadastrados
                        .where((t) =>
                            t.tipoCobertura == 'regiao' &&
                            t.regioes != null &&
                            t.regioes!.isNotEmpty)
                        .toList();
                    return PolygonLayer(
                      polygons: listaRegiao.expand((t) {
                        return t.regioes!.map((r) {
                          final idx = r.hashCode % 12;
                          final latBase = -30 + idx;
                          final lngBase = -55 + idx;
                          return Polygon(
                            points: [
                              LatLng(latBase.toDouble(), lngBase.toDouble()),
                              LatLng(latBase + 2.5, lngBase.toDouble()),
                              LatLng(latBase + 2.5, lngBase + 4),
                              LatLng(latBase.toDouble(), lngBase + 4),
                            ],
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            borderStrokeWidth: 1.5,
                            borderColor: Colors.blueAccent,
                          );
                        });
                      }).toList(),
                    );
                  }),

                  // === Marcadores existentes ===
                  Obx(() {
                    if (territoriosCadastrados.isEmpty) return const SizedBox();
                    return MarkerLayer(
                      markers: territoriosCadastrados
                          .where((t) => t.latitude != null && t.longitude != null)
                          .map((t) => Marker(
                                point: LatLng(t.latitude!, t.longitude!),
                                width: 40,
                                height: 40,
                                child: Tooltip(
                                  message:
                                      "${t.descricao ?? "Sem descrição"}\nRaio: ${t.raioKm?.toStringAsFixed(0) ?? 10} km",
                                  child: const Icon(Icons.location_on,
                                      color: Colors.blueAccent, size: 30),
                                ),
                              ))
                          .toList(),
                    );
                  }),

                  // === Pontos novos (raio/região) ===
                  Obx(() {
                    if (modoAtendimento.value == "raio") {
                      return CircleLayer(
                        circles: pontos
                            .map((p) => CircleMarker(
                                  point: p,
                                  radius: raioKm.value * 1000,
                                  color: theme.primaryColor.value.withValues(alpha: 0.25),
                                  borderStrokeWidth: 3,
                                  borderColor: theme.primaryColor.value,
                                  useRadiusInMeter: true,
                                ))
                            .toList(),
                      );
                    } else {
                      return PolygonLayer(
                        polygons: cidadesSelecionadas.map((r) {
                          final idx = r.hashCode % 8;
                          final latBase = -30 + idx;
                          final lngBase = -50 + idx;
                          return Polygon(
                            points: [
                              LatLng(latBase.toDouble(), lngBase.toDouble()),
                              LatLng(latBase + 2, lngBase.toDouble()),
                              LatLng(latBase + 2, lngBase + 3),
                              LatLng(latBase.toDouble(), lngBase + 3),
                            ],
                            color: theme.primaryColor.value.withValues(alpha: 0.3),
                            borderStrokeWidth: 1.5,
                            borderColor: theme.primaryColor.value,
                          );
                        }).toList(),
                      );
                    }
                  }),

                  // === Marcadores novos ===
                  Obx(() => MarkerLayer(
                        markers: pontos
                            .map((p) => Marker(
                                  point: p,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on,
                                      color: Colors.redAccent, size: 34),
                                ))
                            .toList(),
                      )),
                ],
              ),

              // === LEGENDA FLUTUANTE ===
              Positioned(
                bottom: 110,
                left: 10,
                child: Obx(() {
                  final isRaio = modoAtendimento.value == "raio";
                  final regioesAtivas = cidadesSelecionadas.toList();
                  return Container(
                    width: isRaio ? 180 : 230,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: cor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "Legenda do mapa",
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _LegendaItem(
                          cor: Colors.blueAccent.withValues(alpha: 0.25),
                          icone: Icons.map,
                          descricao: "Territórios existentes",
                        ),
                        _LegendaItem(
                          cor: cor.withValues(alpha: 0.25),
                          icone: Icons.circle,
                          descricao: "Novo território",
                        ),
                        _LegendaItem(
                          cor: Colors.red.shade400,
                          icone: Icons.location_on,
                          descricao: "Ponto de atendimento",
                        ),
                        if (!isRaio && regioesAtivas.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Regiões: ${regioesAtivas.join(', ')}",
                              style: GoogleFonts.poppins(fontSize: 11.5),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),

              // === FABs laterais ===
              Positioned(
                right: 12,
                bottom: 180,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'gps',
                      backgroundColor: Colors.white,
                      onPressed: () async {
                        final loc = await Geolocator.getCurrentPosition();
                        mapController.move(LatLng(loc.latitude, loc.longitude), 12);
                      },
                      child: Icon(Icons.gps_fixed, color: cor),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'refresh',
                      backgroundColor: Colors.white,
                      onPressed: carregarTerritoriosFornecedor,
                      child: const Icon(Icons.refresh, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'clear',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        pontos.clear();
                        cidadesSelecionadas.clear();
                      },
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),

              // === RODAPÉ FIXO COM BOTÕES ===
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cor.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text("Cancelar",
                              style: GoogleFonts.poppins(color: cor, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_outlined, color: Colors.white),
                          label: Text("Salvar Território",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (pontos.isEmpty) {
                              Get.snackbar("Aviso", "Adicione pelo menos um ponto no mapa.",
                                  backgroundColor: Colors.orange.shade400, colorText: Colors.white);
                              return;
                            }

                            final id = const Uuid().v4();
                            for (int i = 0; i < pontos.length; i++) {
                              final p = pontos[i];
                              final model = TerritorioModel(
                                idTerritorio: "${id}_$i",
                                idFornecedor: idFornecedor,
                                latitude: p.latitude,
                                longitude: p.longitude,
                                raioKm: raioKm.value,
                                descricao: descricaoCtrl.text,
                                ativo: true,
                                tipoCobertura: modoAtendimento.value,
                                regioes: cidadesSelecionadas.isNotEmpty
                                    ? cidadesSelecionadas.toList()
                                    : null, // ✅ lista
                              );

                              await FirebaseFirestore.instance
                                  .collection('territorio')
                                  .doc(model.idTerritorio)
                                  .set(model.toMap());
                            }

                            await carregarTerritoriosFornecedor();
                            Get.snackbar("Sucesso", "Território salvo e atualizado com sucesso!",
                                backgroundColor: Colors.green.shade600, colorText: Colors.white);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final IconData icone;
  final String descricao;
  const _LegendaItem({
    required this.cor,
    required this.icone,
    required this.descricao,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Icon(icone, color: Colors.black54, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            descricao,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
