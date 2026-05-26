// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';

class EditarItemCardapioBottomSheet extends StatelessWidget {
  final String idCardapio;
  final CardapioItemModel item;

  EditarItemCardapioBottomSheet({
    super.key,
    required this.idCardapio,
    required this.item,
  });

  late final nomeCtrl = TextEditingController(text: item.nome);
  final RxString tipo = ''.obs;
  final RxBool confirmado = false.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();

    final Rx<TipoItemCardapio> tipo = TipoItemCardapio.comida.obs;
    confirmado.value = item.confirmado;

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
                  Icon(Icons.edit, color: Colors.teal, size: 42),
                  const SizedBox(height: 6),
                  const Text(
                    "Editar Item do Cardápio",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
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
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tipoChip(
                      label: 'Comida',
                      value: TipoItemCardapio.comida,
                      tipo: tipo,
                    ),
                    _tipoChip(
                      label: 'Bebida',
                      value: TipoItemCardapio.bebida,
                      tipo: tipo,
                    ),
                    _tipoChip(
                      label: 'Sobremesa',
                      value: TipoItemCardapio.sobremesa,
                      tipo: tipo,
                    ),
                    _tipoChip(
                      label: 'Bolo',
                      value: TipoItemCardapio.bolo,
                      tipo: tipo,
                    ),
                    _tipoChip(
                      label: 'Descartável',
                      value: TipoItemCardapio.descartavel,
                      tipo: tipo,
                    ),
                    _tipoChip(
                      label: 'Outro',
                      value: TipoItemCardapio.outro,
                      tipo: tipo,
                    ),
                  ],
                )),

            const SizedBox(height: 20),

            Obx(() => SwitchListTile(
                  title: const Text("Confirmado"),
                  value: confirmado.value,
                  onChanged: (v) => confirmado.value = v,
                  activeColor: Colors.teal,
                )),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final atualizado = CardapioItemModel(
                  idItem: item.idItem,
                  nome: nomeCtrl.text.trim(),
                  tipo: tipo.value,
                  confirmado: confirmado.value,
                  idEvento: item.idEvento,
                  idCardapio: idCardapio,
                );

                await controller.addItem(idCardapio, atualizado);

                Navigator.pop(context);
              },
              child: const Text("Salvar alterações"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoChip({
    required String label,
    required TipoItemCardapio value,
    required Rx<TipoItemCardapio> tipo,
  }) {
    return Obx(
      () => ChoiceChip(
        label: Text(label.toUpperCase()),
        selected: tipo.value == value,
        onSelected: (_) => tipo.value = value,
        selectedColor: Colors.teal.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: tipo.value == value ? Colors.teal.shade900 : Colors.black54,
        ),
      ),
    );
  }
}
