import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../../data/models/convidado/grupo_convidado_model.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../widgets/custom_input_field.dart';

Future<void> abrirAdicionarGrupoBottomSheet({
  required BuildContext context,
  required String idEvento,
  required GrupoConvidadoController controller,
}) {
  final themeController = Get.find<EventThemeController>();
  final primary = themeController.primaryColor.value;
  final gradient = themeController.gradient.value;

  final nomeCtrl = TextEditingController();
  final numeroMesaCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  final RxString corSelecionada = primary.toHex().obs;
  final RxString iconeSelecionado = 'group'.obs;

  final cores = [
    primary.toHex(),
    '#FF7BAC',
    '#FF6F91',
    '#FFD36E',
    '#8ED1C7',
    '#A493E8',
    '#6EC3F4',
    '#F5A3C7',
    '#E4C1F9',
    '#D9ED92',
  ];

  final icones = {
    'group': Icons.group_rounded,
    'family': Icons.family_restroom_rounded,
    'star': Icons.star_rounded,
    'favorite': Icons.favorite_rounded,
    'chair': Icons.chair_rounded,
    'cake': Icons.cake_rounded,
    'music': Icons.music_note_rounded,
    'work': Icons.work_rounded,
    'pets': Icons.pets_rounded,
    'sports': Icons.sports_soccer_rounded,
    'emoji': Icons.emoji_people_rounded,
    'school': Icons.school_rounded,
    'travel': Icons.flight_takeoff_rounded,
  };

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===========================================================
                  // 🎀 Cabeçalho Premium
                  // ===========================================================
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          child: Icon(
                            Icons.group_add_rounded,
                            size: 46,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Criar Grupo",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Organize seus convidados em grupos personalizados",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===========================================================
                  // 📝 NOME DO GRUPO
                  // ===========================================================

                  const SizedBox(height: 6),
                  CustomInputField(
                    controller: nomeCtrl,
                    icon: Icons.badge_rounded,
                    label: 'Nome do grupo',
                    color: Colors.white,
                  ),

                  const SizedBox(height: 6),
                  CustomInputField(
                    controller: numeroMesaCtrl,
                    icon: Icons.table_bar_outlined,
                    label: 'Número de mesas',
                    color: Colors.white,
                    keyboardType: TextInputType.numberWithOptions(decimal: false),
                  ),

                  // ===========================================================
                  // ✏️ DESCRIÇÃO
                  // ===========================================================
                  const SizedBox(height: 6),
                  CustomInputField(
                    controller: descCtrl,
                    maxLines: 3,
                    icon: Icons.notes_rounded,
                    label: 'Descrição',
                    color: Colors.white,
                  ),
                  const SizedBox(height: 26),

                  // ===========================================================
                  // 🎨 Seleção de Cor
                  // ===========================================================
                  Text(
                    "Cor do grupo",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: cores.map((hex) {
                        final color = Color(int.parse(hex.replaceAll('#', '0xff')));
                        final selected = corSelecionada.value == hex;
                        return GestureDetector(
                          onTap: () => corSelecionada.value = hex,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: selected ? 42 : 36,
                            height: selected ? 42 : 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.white : Colors.white54,
                                width: selected ? 3 : 1.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),

                  const SizedBox(height: 24),

                  // ===========================================================
                  // 🧩 Ícone
                  // ===========================================================
                  Text(
                    "Ícone",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    final entries = icones.entries.toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        (entries.length / 3).ceil(),
                        (rowIndex) {
                          final rowItems = entries.skip(rowIndex * 3).take(3).toList();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: rowItems.map((entry) {
                                final selected = iconeSelecionado.value == entry.key;

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => iconeSelecionado.value = entry.key,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white.withValues(alpha: 0.25)
                                            : Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: selected ? Colors.white : Colors.white24,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        entry.value,
                                        size: 28,
                                        color: selected ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 36),

                  // ===========================================================
                  // 💾 Botão Salvar
                  // ===========================================================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nomeCtrl.text.trim().isEmpty) {
                          Get.snackbar("Atenção", "Informe o nome do grupo",
                              backgroundColor: Colors.orangeAccent, colorText: Colors.white);
                          return;
                        }

                        final novo = GrupoConvidadoModel(
                          idGrupo: DateTime.now().millisecondsSinceEpoch.toString(),
                          idEvento: idEvento,
                          nome: nomeCtrl.text.trim(),
                          descricao: descCtrl.text.trim(),
                          icone: iconeSelecionado.value,
                          corHex: corSelecionada.value,
                          numeroMesa: int.tryParse(numeroMesaCtrl.text.trim()) ?? 5,
                          convidados: [],
                        );

                        await controller.adicionarGrupo(novo);
                        Get.back();

                        Get.snackbar(
                          "Sucesso!",
                          "Grupo criado com sucesso 🎉",
                          backgroundColor: primary,
                          colorText: Colors.white,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Salvar Grupo",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                      label: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

extension ColorToHex on Color {
  String toHex({bool leadingHashSign = true}) {
    final buffer = StringBuffer();

    if (leadingHashSign) buffer.write('#');

    buffer.write((r.toInt()).toRadixString(16).padLeft(2, '0'));
    buffer.write((g.toInt()).toRadixString(16).padLeft(2, '0'));
    buffer.write((b.toInt()).toRadixString(16).padLeft(2, '0'));

    return buffer.toString().toUpperCase();
  }
}
