// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../data/models/servico_produto/subcategoria_servico_model.dart';
import './../../../../controllers/categoria/subcategoria_servico_controller.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../../controllers/event_theme_controller.dart';

Future<void> showSubcategoriaServicoBottomSheet(
  BuildContext context, [
  SubcategoriaServicoModel? subcategoria,
  CategoriaServicoModel? categoriaSelecionada,
]) async {
  final themeController = Get.find<EventThemeController>();
  final categoriaController = Get.find<CategoriaServicoController>();
  final subcategoriaController = Get.find<SubcategoriaServicoController>();
  final primary = themeController.primaryColor.value;

  final nomeCtrl = TextEditingController(text: subcategoria?.nome ?? '');
  final descCtrl = TextEditingController(text: subcategoria?.descricao ?? '');
  final ativo = (subcategoria?.ativo ?? true).obs;

  /// 🔹 Define a categoria inicial (vinda da tela ou do item em edição)
  final idCategoria = (subcategoria?.idCategoria ?? categoriaSelecionada?.id ?? '').obs;

  await categoriaController.carregarCategorias();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Obx(() {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subcategoria == null ? 'Nova Subcategoria' : 'Editar Subcategoria',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Categoria (pré-selecionada se vinda da tela)
                DropdownButtonFormField<String>(
                  value: idCategoria.value.isEmpty ? null : idCategoria.value,
                  decoration: InputDecoration(
                    labelText: 'Categoria vinculada',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: categoriaController.categorias
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                      .toList(),
                  onChanged: (v) => idCategoria.value = v ?? '',
                ),
                const SizedBox(height: 16),

                // 🔹 Nome
                TextField(
                  controller: nomeCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nome da subcategoria',
                    prefixIcon: const Icon(Icons.list_alt_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Descrição
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Status Ativo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subcategoria ativa', style: GoogleFonts.poppins(fontSize: 15)),
                    Switch(
                      value: ativo.value,
                      activeColor: primary,
                      onChanged: (v) => ativo.value = v,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🔹 Botão SALVAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Salvar', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      if (idCategoria.value.isEmpty || nomeCtrl.text.trim().isEmpty) {
                        Get.snackbar(
                          'Campos obrigatórios',
                          'Informe a categoria e o nome da subcategoria.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                        );
                        return;
                      }

                      final model = SubcategoriaServicoModel(
                        id: subcategoria?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        idCategoria: idCategoria.value,
                        nome: nomeCtrl.text.trim(),
                        descricao: descCtrl.text.trim(),
                        ativo: ativo.value,
                      );

                      await subcategoriaController.salvarSubcategoria(model);
                      await subcategoriaController
                          .carregarSubcategoriasPorCategoria(idCategoria.value);
                      Get.back();

                      Get.snackbar(
                        'Sucesso',
                        'Subcategoria salva com sucesso!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.shade100,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Botão SAIR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    ),
  );
}
