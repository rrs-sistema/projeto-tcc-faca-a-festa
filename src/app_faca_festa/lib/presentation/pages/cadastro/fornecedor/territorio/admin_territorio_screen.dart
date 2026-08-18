import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/biblioteca.dart';
import './../../../../../controllers/admin/admin_territorio_controller.dart';
import './../../../../../controllers/tema/event_theme_controller.dart';
import '../../../../../controllers/fornecedor/fornecedor_controller.dart';
import '../../../../../data/models/model.dart';

class AdminTerritorioScreen extends StatelessWidget {
  final controller = Get.put(AdminTerritorioController());
  final fornecedorController = Get.find<FornecedorController>();

  AdminTerritorioScreen({super.key}) {
    Future.microtask(controller.carregarTerritorios);
  }

  String _getNomeFornecedor(String idFornecedor) {
    final f =
        fornecedorController.fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
    return f?.razaoSocial ?? 'Fornecedor não encontrado';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final cor = theme.primaryColor.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gerenciar Territórios',
          style: GoogleFonts.poppins(color: Colors.white),
          selectionColor: Colors.white,
        ),
        backgroundColor: cor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recarregar',
            onPressed: controller.carregarTerritorios,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogTerritorio(context),
        backgroundColor: cor,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text(
          "Novo Território",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Row(
        children: [
          // ====================== LISTA LATERAL ======================
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Text(
                      "Territórios Cadastrados",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      final lista = controller.territorios;
                      if (lista.isEmpty) {
                        return Center(
                          child: Text(
                            "Nenhum território cadastrado",
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: lista.length,
                        itemBuilder: (_, i) {
                          final t = lista[i];
                          final nomeFornecedor = _getNomeFornecedor(t.idFornecedor);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 2,
                            child: ListTile(
                              leading: Icon(
                                t.tipoCobertura == 'raio'
                                    ? Icons.circle_outlined
                                    : Icons.map_outlined,
                                color: t.ativo ? Colors.green : Colors.grey.shade500,
                              ),
                              title: Text(
                                t.descricao?.isNotEmpty == true ? t.descricao! : 'Sem descrição',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Fornecedor: $nomeFornecedor\n'
                                'Cobertura: ${t.tipoCobertura ?? '-'}'
                                '${t.raioKm != null ? " • Raio: ${t.raioKm!.toStringAsFixed(0)} km" : ""}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: Switch(
                                value: t.ativo,
                                activeColor: Colors.green,
                                onChanged: (v) => controller.toggleAtivo(t, v),
                              ),
                              onTap: () => _abrirDialogTerritorio(context, existente: t),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ====================== MAPA INTERATIVO ======================
          Expanded(
            flex: 5,
            child: Obx(() => FlutterMap(
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-15.78, -47.93),
                    initialZoom: 4.3,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'app_faca_festa',
                    ),

                    // Territórios tipo RAIO
                    CircleLayer(
                      circles: controller.territorios
                          .where((t) =>
                              t.tipoCobertura == 'raio' &&
                              t.latitude != null &&
                              t.longitude != null &&
                              t.ativo)
                          .map((t) => CircleMarker(
                                point: LatLng(t.latitude!, t.longitude!),
                                radius: (t.raioKm ?? 10) * 1000,
                                color: Colors.blueAccent.withValues(alpha: 0.25),
                                borderStrokeWidth: 2,
                                borderColor: Colors.blueAccent,
                                useRadiusInMeter: true,
                              ))
                          .toList(),
                    ),

                    // Territórios tipo REGIÃO
                    PolygonLayer(
                      polygons: controller.territorios
                          .where((t) => t.tipoCobertura == 'regiao' && t.regioes != null && t.ativo)
                          .map((t) => Polygon(
                                points: t.regioes!.map((r) {
                                  final parts = r.split(',');
                                  return LatLng(double.parse(parts[0]), double.parse(parts[1]));
                                }).toList(),
                                color: Colors.greenAccent.withValues(alpha: 0.25),
                                borderColor: Colors.green,
                                borderStrokeWidth: 1.5,
                              ))
                          .toList(),
                    ),

                    // Marcadores
                    MarkerLayer(
                      markers: controller.territorios
                          .where((t) => t.latitude != null && t.longitude != null && t.ativo)
                          .map((t) {
                        final nomeFornecedor = _getNomeFornecedor(t.idFornecedor);
                        return Marker(
                          point: LatLng(t.latitude!, t.longitude!),
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: "Fornecedor: $nomeFornecedor\n${t.descricao ?? ''}",
                            child: const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  void _abrirDialogTerritorio(BuildContext context, {TerritorioModel? existente}) {
    final theme = Get.find<EventThemeController>();
    final cor = theme.primaryColor.value;
    final formKey = GlobalKey<FormState>();

    var t = existente ??
        TerritorioModel(
          idTerritorio: DateTime.now().millisecondsSinceEpoch.toString(),
          idFornecedor: '',
          tipoCobertura: 'raio',
          ativo: true,
          raioKm: 10,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Cabeçalho com ícone e título
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: cor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  existente == null
                                      ? Icons.add_location_alt_rounded
                                      : Icons.edit_location_alt_rounded,
                                  color: cor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                existente == null ? 'Novo Território' : 'Editar Território',
                                style: GoogleFonts.poppins(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 🔹 Fornecedor
                          Text(
                            'Fornecedor',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: t.idFornecedor.isNotEmpty ? t.idFornecedor : null,
                            items: fornecedorController.fornecedores
                                .map((f) => DropdownMenuItem(
                                      value: f.idFornecedor,
                                      child: Text(f.razaoSocial, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cor.withValues(alpha: 0.3)),
                              ),
                            ),
                            onChanged: (v) => setState(() {
                              t = t.copyWith(idFornecedor: v ?? '');
                            }),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Selecione um fornecedor' : null,
                          ),
                          const SizedBox(height: 16),

                          // 🔹 Tipo de cobertura
                          Text(
                            'Tipo de Cobertura',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: t.tipoCobertura,
                            items: const [
                              DropdownMenuItem(value: 'raio', child: Text('Cobertura por Raio')),
                              DropdownMenuItem(
                                  value: 'regiao', child: Text('Cobertura por Região')),
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                            onChanged: (v) => setState(() {
                              t = t.copyWith(tipoCobertura: v ?? 'raio');
                            }),
                          ),
                          const SizedBox(height: 16),

                          // 🔹 Raio
                          if (t.tipoCobertura == 'raio') ...[
                            Text(
                              'Raio de Cobertura (km)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: t.raioKm?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                hintText: 'Ex: 10',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: cor.withValues(alpha: 0.3)),
                                ),
                              ),
                              onChanged: (v) => setState(() {
                                t = t.copyWith(raioKm: Biblioteca.toDouble(v));
                              }),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 🔹 Descrição
                          Text(
                            'Descrição',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: t.descricao,
                            maxLines: 2,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              hintText: 'Ex: Zona Sul - raio de atendimento principal',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cor.withValues(alpha: 0.3)),
                              ),
                            ),
                            onChanged: (v) => setState(() {
                              t = t.copyWith(descricao: v);
                            }),
                          ),
                          const SizedBox(height: 16),

                          // 🔹 Ativo
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade100,
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'Ativo',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              value: t.ativo,
                              activeColor: cor,
                              onChanged: (v) => setState(() {
                                t = t.copyWith(ativo: v);
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 🔹 Botões de ação
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: Get.back,
                                icon: const Icon(Icons.close),
                                label: const Text('Cancelar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save_rounded, color: Colors.white),
                                label: Text(
                                  existente == null ? 'Salvar Território' : 'Atualizar',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  elevation: 4,
                                ),
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    controller.salvarTerritorio(t);
                                    Get.back();
                                    Get.snackbar(
                                      'Sucesso!',
                                      existente == null
                                          ? 'Território cadastrado com sucesso.'
                                          : 'Território atualizado com sucesso.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: cor.withValues(alpha: 0.1),
                                      colorText: Colors.black87,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}
