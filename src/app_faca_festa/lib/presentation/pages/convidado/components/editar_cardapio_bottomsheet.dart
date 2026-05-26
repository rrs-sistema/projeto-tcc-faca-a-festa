// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/cardapio/cardapio_model.dart';

class EditarCardapioBottomSheet extends StatefulWidget {
  final CardapioModel cardapio;

  const EditarCardapioBottomSheet({super.key, required this.cardapio});

  @override
  State<EditarCardapioBottomSheet> createState() => _EditarCardapioBottomSheetState();
}

class _EditarCardapioBottomSheetState extends State<EditarCardapioBottomSheet> {
  late TextEditingController tituloCtrl;

  final Rx<IconData> iconeSelecionado = Icons.restaurant_menu.obs;
  final Rx<Color> corSelecionada = Rx<Color>(Colors.teal);

  @override
  void initState() {
    super.initState();

    tituloCtrl = TextEditingController(text: widget.cardapio.titulo);

    // Agora o ícone vem como String no model.
    iconeSelecionado.value = _iconFromString(widget.cardapio.icone);

    // Agora a cor vem como corHex no model.
    corSelecionada.value = _colorFromHex(
      widget.cardapio.corHex,
      fallback: Colors.teal,
    );
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    super.dispose();
  }

  IconData _iconFromString(String? value) {
    final codePoint = int.tryParse(value ?? '');

    if (codePoint == null) {
      return Icons.restaurant_menu;
    }

    return IconData(
      codePoint,
      fontFamily: 'MaterialIcons',
    );
  }

  String _iconToString(IconData icon) {
    return icon.codePoint.toString();
  }

  Color _colorFromHex(String? hex, {Color fallback = Colors.teal}) {
    try {
      if (hex == null || hex.trim().isEmpty) {
        return fallback;
      }

      var value = hex.replaceAll('#', '').trim();

      if (value.length == 6) {
        value = 'FF$value';
      }

      if (value.length != 8) {
        return fallback;
      }

      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _colorToHex(Color color) {
    String channelToHex(double value) {
      final intValue = (value * 255).round().clamp(0, 255);
      return intValue.toRadixString(16).padLeft(2, '0');
    }

    final alpha = channelToHex(color.a);
    final red = channelToHex(color.r);
    final green = channelToHex(color.g);
    final blue = channelToHex(color.b);

    return '#$alpha$red$green$blue'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final controller = Get.find<CardapioController>();

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.gradient.value,
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
                      color: corSelecionada.value,
                    )),
                const SizedBox(width: 12),
                Text(
                  "Editar Cardápio",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryColor.value,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // CAMPO: TÍTULO
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

            // SELETOR ÍCONES
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ícone",
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.secondaryColor.value),
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

            // SELETOR CORES
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Cor do cardápio",
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.secondaryColor.value),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        backgroundColor: theme.primaryColor.value,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final titulo = tituloCtrl.text.trim();

                        if (titulo.isEmpty) {
                          Get.snackbar(
                            "Atenção",
                            "Informe o título do cardápio",
                            backgroundColor: Colors.orangeAccent,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        final atualizado = CardapioModel(
                          idCardapio: widget.cardapio.idCardapio,
                          idEvento: widget.cardapio.idEvento,
                          titulo: titulo,
                          publicoAlvo: widget.cardapio.publicoAlvo,
                          icone: _iconToString(iconeSelecionado.value),
                          corHex: _colorToHex(corSelecionada.value),
                          totalItens: widget.cardapio.totalItens,
                          totalComidas: widget.cardapio.totalComidas,
                          totalBebidas: widget.cardapio.totalBebidas,
                          totalSobremesas: widget.cardapio.totalSobremesas,
                          ativo: widget.cardapio.ativo,
                        );

                        await controller.atualizarCardapio(atualizado);

                        Navigator.pop(context);
                      },
                      child: const Text("Alterar", style: TextStyle(color: Colors.white)),
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

  // ---------------------------------------------------------
  // ÍCONE DO CARDÁPIO
  // ---------------------------------------------------------
  Widget _iconOption(IconData icon, Rx<IconData> target, EventThemeController theme) {
    return Obx(() {
      final selected = target.value == icon;

      return GestureDetector(
        onTap: () => target.value = icon,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? theme.primaryColor.value.withValues(alpha: 0.2) : Colors.white,
            border: Border.all(
              color: selected ? theme.secondaryColor.value : Colors.white.withValues(alpha: 0.3),
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

  // ---------------------------------------------------------
  // COR DO CARDÁPIO
  // ---------------------------------------------------------
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
