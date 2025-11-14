// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/cardapio/cardapio_model.dart';

class CadastroCardapioBottomSheet extends StatelessWidget {
  final String idEvento;
  CadastroCardapioBottomSheet({super.key, required this.idEvento});

  final tituloCtrl = TextEditingController();
  final Rx<IconData> iconeSelecionado = Icons.restaurant_menu.obs;

  final Rx<Color> corSelecionada = Rx<Color>(Colors.teal);

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final controller = Get.find<CardapioController>();

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.gradient.value, // 🔥 GRADIENT DO TEMA
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => Icon(
                      iconeSelecionado.value,
                      size: 38,
                      color: corSelecionada.value, // 🔥 COR DO CARDÁPIO ESCOLHIDO
                    )),
                const SizedBox(width: 12),
                Text(
                  "Novo Cardápio",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryColor.value, // 🔥 TÍTULO NO TEMA
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // CAMPO TÍTULO
            TextField(
              controller: tituloCtrl,
              decoration: InputDecoration(
                label: Text(
                  "Título do Cardápio",
                  style: TextStyle(color: theme.secondaryColor.value),
                ),
                prefixIcon: Icon(Icons.text_fields, color: theme.secondaryColor.value),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.secondaryColor.value),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 18),

            // SELETOR DE ÍCONES
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ícone",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryColor.value,
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _iconOption(Icons.restaurant_menu, iconeSelecionado, theme),
                  _iconOption(Icons.child_care, iconeSelecionado, theme),
                  _iconOption(Icons.cake, iconeSelecionado, theme),
                  _iconOption(Icons.local_drink, iconeSelecionado, theme),
                  _iconOption(Icons.fastfood, iconeSelecionado, theme),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // SELETOR DE COR
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Cor do cardápio",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryColor.value,
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _colorOption(Colors.teal, corSelecionada),
                  _colorOption(Colors.pinkAccent, corSelecionada),
                  _colorOption(Colors.orange, corSelecionada),
                  _colorOption(Colors.blueAccent, corSelecionada),
                  _colorOption(Colors.green, corSelecionada),
                ],
              ),
            ),

            const Spacer(),

            // BOTÕES
            Row(
              children: [
                // CANCELAR
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                ),

                const SizedBox(width: 12),

                // SALVAR
                Expanded(
                  child: Obx(() {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.value, // 🔥 DO TEMA
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final novo = CardapioModel(
                          idCardapio: DateTime.now().millisecondsSinceEpoch.toString(),
                          idEvento: idEvento,
                          titulo: tituloCtrl.text.trim(),
                          icone: iconeSelecionado.value,
                          cor: corSelecionada.value,
                        );

                        await controller.adicionarCardapio(novo);
                        Navigator.pop(context);
                      },
                      child: const Text('Salvar', style: TextStyle(color: Colors.white)),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 45),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGET AUXILIAR — ÍCONES COM SELEÇÃO E TEMA
  // -------------------------------------------------------------
  Widget _iconOption(IconData icon, Rx<IconData> target, EventThemeController theme) {
    return Obx(() {
      final selected = target.value == icon;
      return GestureDetector(
        onTap: () => target.value = icon,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? theme.primaryColor.value.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: selected ? theme.secondaryColor.value : Colors.white.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            size: 26,
            color: selected ? theme.secondaryColor.value : Colors.black54,
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // WIDGET AUXILIAR — CORES DO CARDÁPIO
  // -------------------------------------------------------------
  Widget _colorOption(Color color, Rx<Color> target) {
    return Obx(() {
      final selected = target.value == color;

      return GestureDetector(
        onTap: () => target.value = color,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              width: selected ? 4 : 2,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      );
    });
  }
}
