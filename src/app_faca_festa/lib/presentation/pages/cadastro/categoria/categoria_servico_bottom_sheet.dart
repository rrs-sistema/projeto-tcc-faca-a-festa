import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../../controllers/event_theme_controller.dart';

Future<void> showCategoriaServicoBottomSheet(
  BuildContext context, [
  CategoriaServicoModel? categoria,
]) async {
  final themeController = Get.find<EventThemeController>();
  final controller = Get.find<CategoriaServicoController>();
  final nomeCtrl = TextEditingController(text: categoria?.nome ?? '');
  final descCtrl = TextEditingController(text: categoria?.descricao ?? '');
  final primary = themeController.primaryColor.value;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
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
                categoria == null ? 'Nova Categoria' : 'Editar Categoria',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nomeCtrl,
                decoration: InputDecoration(
                  labelText: 'Nome da categoria',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: primary,
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar', style: TextStyle(fontSize: 16)),
                  onPressed: () async {
                    final model = CategoriaServicoModel(
                      id: categoria?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      nome: nomeCtrl.text,
                      descricao: descCtrl.text,
                    );
                    await controller.salvarCategoria(model);
                    Get.back();
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Sair', style: TextStyle(fontSize: 16)),
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
      },
    ),
  );
}
