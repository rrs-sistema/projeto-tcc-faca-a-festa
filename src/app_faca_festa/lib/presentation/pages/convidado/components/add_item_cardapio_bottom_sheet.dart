// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';

class AddItemCardapioBottomSheet extends StatefulWidget {
  final String idCardapio;

  const AddItemCardapioBottomSheet({super.key, required this.idCardapio});

  @override
  State<AddItemCardapioBottomSheet> createState() => _AddItemCardapioBottomSheetState();
}

class _AddItemCardapioBottomSheetState extends State<AddItemCardapioBottomSheet> {
  final nomeCtrl = TextEditingController();
  final RxString tipo = "comida".obs;

  @override
  void dispose() {
    nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();

    return FractionallySizedBox(
      heightFactor: 0.80,
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.gradient.value,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ─────────────────────────────────────────────
            // HEADER ELEGANTE
            // ─────────────────────────────────────────────
            Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.add_circle_rounded, size: 40, color: theme.secondaryColor.value),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Novo Item do Cardápio",
                    style: GoogleFonts.poppins(
                      color: theme.secondaryColor.value,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),

                // Botão de sair
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 28, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
              ],
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────
            // SCROLL DO CONTEÚDO
            // ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INPUT NOME
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                          width: 1.4,
                        ),
                      ),
                      child: TextField(
                        controller: nomeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Nome do item",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.fastfood_rounded,
                              color: Colors.white.withValues(alpha: 0.8)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // TÍTULO TIPO
                    Text(
                      "Tipo de Item",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CHIPS DE TIPO
                    Obx(() => Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          children: [
                            _tipoChip("comida", tipo, theme),
                            _tipoChip("bebida", tipo, theme),
                            _tipoChip("sobremesa", tipo, theme),
                          ],
                        )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────────────────────
            // BOTÃO FIXO PARA SALVAR
            // ─────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Obx(() {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor.value,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () async {
                      final novoItem = CardapioItemModel(
                        idItem: "",
                        nome: nomeCtrl.text.trim(),
                        tipo: tipo.value,
                        confirmado: false,
                      );

                      await controller.addItem(widget.idCardapio, novoItem);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Adicionar Item",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CHIP ESTILIZADO PREMIUM
  // ──────────────────────────────────────────────────────────
  Widget _tipoChip(String label, RxString tipo, EventThemeController theme) {
    final bool selected = tipo.value == label;
    final primary = theme.primaryColor.value;

    return ChoiceChip(
      label: Text(
        label[0].toUpperCase() + label.substring(1), // “Comida”, “Bebida”...
        style: GoogleFonts.poppins(
          color: selected ? Colors.white : Colors.grey.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      checkmarkColor: selected ? Colors.white : Colors.grey.withValues(alpha: 0.85),
      selected: selected,
      onSelected: (_) => tipo.value = label,

      // Fundo profissional
      selectedColor: primary.withValues(alpha: 0.85),
      backgroundColor: Colors.white.withValues(alpha: 0.15),

      // Borda REALMENTE profissional
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),

      // Mais elegante
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      // remove brilho padrão
      pressElevation: 0,
      visualDensity: VisualDensity.compact,
      shadowColor: Colors.transparent,
    );
  }
}
