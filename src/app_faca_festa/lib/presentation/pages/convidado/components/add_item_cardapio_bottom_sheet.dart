// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';

class AddItemCardapioBottomSheet extends StatelessWidget {
  final String idCardapio;
  AddItemCardapioBottomSheet({super.key, required this.idCardapio});

  final nomeCtrl = TextEditingController();
  final RxString tipo = "comida".obs;
  final RxBool confirmado = false.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();

    return FractionallySizedBox(
      heightFactor: 0.65,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.add_circle, color: Colors.teal, size: 42),
                  const SizedBox(height: 6),
                  const Text("Novo Item do Cardápio",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Campo nome
            TextField(
              controller: nomeCtrl,
              decoration: InputDecoration(
                label: const Text("Nome do item"),
                prefixIcon: const Icon(Icons.text_fields),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 20),

            Text("Tipo (classificação)", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            Obx(() => Wrap(
                  spacing: 12,
                  children: [
                    _tipoChip("comida", tipo),
                    _tipoChip("bebida", tipo),
                    _tipoChip("sobremesa", tipo),
                  ],
                )),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                CardapioItemModel cardapioItemModel = CardapioItemModel(
                  idItem: '',
                  nome: nomeCtrl.text.trim(),
                  tipo: tipo.value,
                  confirmado: false,
                );
                await controller.addItem(idCardapio, cardapioItemModel);
                Navigator.pop(context);
              },
              child: const Text("Adicionar Item"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoChip(String label, RxString tipo) {
    return ChoiceChip(
      label: Text(label.toUpperCase()),
      selected: tipo.value == label,
      onSelected: (_) => tipo.value = label,
      selectedColor: Colors.teal.withValues(alpha: 0.25),
    );
  }
}
