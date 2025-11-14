// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../data/models/cardapio/cardapio_model.dart';

class EditarCardapioBottomSheet extends StatelessWidget {
  final CardapioModel cardapio;

  EditarCardapioBottomSheet({super.key, required this.cardapio});

  late final tituloCtrl = TextEditingController(text: cardapio.titulo);
  final Rx<IconData> iconeSelecionado = Icons.restaurant_menu.obs;
  final Rx<Color> corSelecionada = Colors.teal.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();

    iconeSelecionado.value = cardapio.icone ?? Icons.restaurant_menu;
    corSelecionada.value = cardapio.cor ?? Colors.teal;

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Obx(() => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // TÍTULO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(iconeSelecionado.value, size: 38, color: corSelecionada.value),
                    const SizedBox(width: 12),
                    const Text(
                      "Editar Cardápio",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // CAMPO TÍTULO
                TextField(
                  controller: tituloCtrl,
                  decoration: InputDecoration(
                    label: const Text("Título do Cardápio"),
                    prefixIcon: const Icon(Icons.text_fields),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 22),

                // SELETOR DE ÍCONES
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Ícone", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _iconOption(Icons.restaurant_menu, iconeSelecionado),
                      _iconOption(Icons.fastfood, iconeSelecionado),
                      _iconOption(Icons.cake, iconeSelecionado),
                      _iconOption(Icons.local_drink, iconeSelecionado),
                      _iconOption(Icons.child_care, iconeSelecionado),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SELETOR DE COR
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Cor", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _colorOption(Colors.teal, corSelecionada),
                      _colorOption(Colors.orange, corSelecionada),
                      _colorOption(Colors.pinkAccent, corSelecionada),
                      _colorOption(Colors.blueAccent, corSelecionada),
                      _colorOption(Colors.green, corSelecionada),
                    ],
                  ),
                ),

                const Spacer(),

                // BOTÃO SALVAR
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corSelecionada.value,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    var model = CardapioModel(
                      idCardapio: DateTime.now().millisecondsSinceEpoch.toString(),
                      idEvento: cardapio.idEvento,
                      titulo: tituloCtrl.text.trim(),
                      icone: iconeSelecionado.value,
                      cor: corSelecionada.value,
                    );
                    model = model.copyWith(
                      titulo: tituloCtrl.text.trim(),
                      icone: iconeSelecionado.value,
                      cor: corSelecionada.value,
                    );
                    await controller.adicionarCardapio(model);

                    Navigator.pop(context);
                  },
                  child: const Text("Salvar Alterações"),
                ),
              ],
            ),
          )),
    );
  }

  Widget _iconOption(IconData icon, Rx<IconData> target) {
    return Obx(() {
      final selected = target.value == icon;
      return GestureDetector(
        onTap: () => target.value = icon,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Colors.black12 : Colors.white,
          ),
          child: Icon(icon, size: 26),
        ),
      );
    });
  }

  Widget _colorOption(Color color, Rx<Color> target) {
    return GestureDetector(
      onTap: () => target.value = color,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(width: 2, color: Colors.white),
        ),
      ),
    );
  }
}
