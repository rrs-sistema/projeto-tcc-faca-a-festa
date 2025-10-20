import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../../../controllers/event_theme_controller.dart';
import './subcategoria_servico_list_screen.dart';
import './categoria_servico_bottom_sheet.dart';

class CategoriaServicoListScreen extends StatelessWidget {
  const CategoriaServicoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoriaServicoController());
    final theme = Get.find<EventThemeController>();

    return Obx(() {
      final gradient = theme.gradient.value;
      final primary = theme.primaryColor.value;

      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Categorias de Serviços',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),
        body: controller.carregando.value
            ? const Center(child: CircularProgressIndicator())
            : controller.categorias.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma categoria cadastrada',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.categorias.length,
                    itemBuilder: (_, i) {
                      final c = controller.categorias[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: Icon(Icons.category_outlined, color: primary),
                          ),
                          title: Text(
                            c.nome,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            c.descricao?.isNotEmpty == true ? c.descricao! : 'Sem descrição',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),

                          // 🔹 Novo comportamento: Editar ao tocar
                          onTap: () => showCategoriaServicoBottomSheet(context, c),

                          trailing: IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: primary,
                            tooltip: 'Ver subcategorias',
                            onPressed: () {
                              Get.to(() => SubcategoriaServicoListScreen(categoria: c));
                            },
                          ),

                          // 🔹 Excluir ao segurar
                          onLongPress: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Excluir categoria'),
                                content: Text(
                                  'Deseja realmente excluir "${c.nome}"?',
                                  style: GoogleFonts.poppins(fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmar == true) {
                              await controller.excluirCategoria(c.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          tooltip: 'Nova categoria',
          onPressed: () => showCategoriaServicoBottomSheet(context),
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}
