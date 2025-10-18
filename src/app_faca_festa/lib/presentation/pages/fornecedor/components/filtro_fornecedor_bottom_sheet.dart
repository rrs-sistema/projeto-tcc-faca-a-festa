import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../../controllers/event_theme_controller.dart';

class FiltroFornecedorBottomSheet extends StatelessWidget {
  final FornecedorLocalizacaoController controller;

  const FiltroFornecedorBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;

      return Padding(
        padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === BARRA DE ARRASTE ===
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // === TÍTULO ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrar Fornecedores',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 10),

            // === SLIDER DE RAIO ===
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raio de busca: ${controller.raio.value.toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        activeTrackColor: primary,
                        inactiveTrackColor: primary.withValues(alpha: 40),
                        thumbColor: primary,
                        overlayColor: primary.withValues(alpha: 40),
                      ),
                      child: Slider(
                        value: controller.raio.value,
                        min: 1,
                        max: 50,
                        divisions: 10,
                        label: '${controller.raio.value.round()} km',
                        onChanged: controller.atualizarRaio,
                      ),
                    ),
                  ],
                )),

            const Divider(height: 24),

            // === FILTRO DE AVALIAÇÃO ===
            Text(
              'Avaliação mínima:',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _avaliacaoChips(controller, primary, gradient),

            const Divider(height: 24),

            // === BOTÃO APLICAR ===
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                  shadowColor: primary.withValues(alpha: 60),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Get.snackbar(
                    'Filtros aplicados',
                    'Resultados atualizados para ${controller.raio.value.toStringAsFixed(0)} km',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: primary,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 14,
                    duration: const Duration(seconds: 2),
                  );
                },
                icon: const Icon(Icons.done_rounded, color: Colors.white),
                label: const Text(
                  'Aplicar Filtros',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      );
    });
  }

  // 🔹 Chips para selecionar avaliação mínima com tema
  Widget _avaliacaoChips(
      FornecedorLocalizacaoController controller, Color primary, LinearGradient gradient) {
    final opcoes = [5.0, 4.5, 4.0, 3.5];
    return Wrap(
      spacing: 8,
      children: opcoes.map((nota) {
        return Obx(() {
          final selecionada = controller.avaliacaoMinima.value == nota;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${nota.toStringAsFixed(1)}+'),
              ],
            ),
            selected: selecionada,
            selectedColor: primary,
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selecionada ? primary : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            labelStyle: TextStyle(
              color: selecionada ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => controller.avaliacaoMinima.value = nota,
          );
        });
      }).toList(),
    );
  }
}
