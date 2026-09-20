import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class FiltroFornecedorBottomSheet extends StatelessWidget {
  final FornecedorLocalizacaoController controller;
  final EventThemeController themeController;

  const FiltroFornecedorBottomSheet({
    super.key,
    required this.controller,
    required this.themeController,
  });

  static const double _raioIlimitado = 999;

  static Future<void> show({
    required BuildContext context,
    required FornecedorLocalizacaoController controller,
    required EventThemeController themeController,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => FiltroFornecedorBottomSheet(
        controller: controller,
        themeController: themeController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final primary = themeController.primaryColor.value;
      final onPrimary = themeController.onPrimaryColor.value;
      final raioAtual = controller.raio.value;
      final raioIlimitado = raioAtual >= _raioIlimitado;
      final sliderValue =
          raioIlimitado ? 100.0 : raioAtual.clamp(1.0, 100.0);

      return Theme(
        data: themeController.materialTheme.copyWith(
          iconTheme: IconThemeData(color: primary),
          sliderTheme: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: primary,
            inactiveTrackColor: primary.withValues(alpha: 0.22),
            thumbColor: primary,
            overlayColor: primary.withValues(alpha: 0.14),
            valueIndicatorColor: primary,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filtrar fornecedores',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    raioIlimitado
                        ? 'Onde buscar: qualquer lugar'
                        : 'Onde buscar: até ${raioAtual.toStringAsFixed(0)} km',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: sliderValue,
                    min: 1,
                    max: 100,
                    divisions: 20,
                    label: raioIlimitado
                        ? 'Qualquer lugar'
                        : '${sliderValue.round()} km',
                    activeColor: primary,
                    inactiveColor: primary.withValues(alpha: 0.22),
                    onChanged: controller.atualizarRaio,
                  ),
                  Text(
                    raioIlimitado
                        ? 'A lista mostra fornecedores de qualquer cidade.'
                        : 'A lista mostra só quem atende nessa distância.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(
                        Icons.public_rounded,
                        size: 18,
                        color: primary,
                      ),
                      label: const Text('Buscar em qualquer lugar'),
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        controller.atualizarRaio(_raioIlimitado);
                        Get.snackbar(
                          'Filtro atualizado',
                          'A lista agora mostra fornecedores de qualquer lugar.',
                          backgroundColor: primary,
                          colorText: onPrimary,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 14,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 28),
                  Text(
                    'Avaliação mínima',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AvaliacaoChips(
                    controller: controller,
                    primary: primary,
                    onPrimary: onPrimary,
                  ),
                  const Divider(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                        shadowColor: primary.withValues(alpha: 0.24),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        final mensagem = raioIlimitado
                            ? 'Mostrando fornecedores sem limite de distância'
                            : 'Mostrando fornecedores em até ${raioAtual.toStringAsFixed(0)} km';
                        Get.snackbar(
                          'Filtros aplicados',
                          mensagem,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: primary,
                          colorText: onPrimary,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 14,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      icon: Icon(Icons.done_rounded, color: onPrimary),
                      label: Text(
                        'Aplicar filtros',
                        style: GoogleFonts.poppins(
                          color: onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _AvaliacaoChips extends StatelessWidget {
  final FornecedorLocalizacaoController controller;
  final Color primary;
  final Color onPrimary;

  const _AvaliacaoChips({
    required this.controller,
    required this.primary,
    required this.onPrimary,
  });

  static const _opcoes = [5.0, 4.5, 4.0, 3.5];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _opcoes.map((nota) {
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
            checkmarkColor: onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selecionada ? primary : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            labelStyle: GoogleFonts.poppins(
              color: selecionada ? onPrimary : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (selected) {
              controller.avaliacaoMinima.value = selected ? nota : 0.0;
            },
          );
        });
      }).toList(),
    );
  }
}
