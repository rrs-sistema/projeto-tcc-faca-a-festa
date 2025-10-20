import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../controllers/categoria/subcategoria_servico_controller.dart';
import './../../../../../controllers/event_theme_controller.dart';
import './show_subcategoria_servico_bottom_sheet.dart';

class SubcategoriaServicoListScreen extends StatelessWidget {
  final CategoriaServicoModel categoria;

  const SubcategoriaServicoListScreen({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubcategoriaServicoController());
    final theme = Get.find<EventThemeController>();

    // 🔹 Carrega as subcategorias filtradas pela categoria recebida
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.carregarSubcategoriasPorCategoria(categoria.id);
    });

    return Obx(() {
      final gradient = theme.gradient.value;
      final primary = theme.primaryColor.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Subcategorias de ${categoria.nome}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),
        body: controller.carregando.value
            ? const Center(child: CircularProgressIndicator())
            : controller.subcategoriasFiltradas.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma subcategoria cadastrada para esta categoria.',
                      style: GoogleFonts.poppins(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.subcategoriasFiltradas.length,
                    itemBuilder: (_, i) {
                      final s = controller.subcategoriasFiltradas[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: Icon(Icons.list_alt_outlined, color: primary),
                          ),
                          title: Text(
                            s.nome,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            s.descricao?.isNotEmpty == true ? s.descricao! : 'Sem descrição',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                          ),
                          trailing: Switch(
                            value: s.ativo,
                            activeColor: primary,
                            onChanged: (v) => controller.atualizarStatus(s, v),
                          ),
                          onTap: () => showSubcategoriaServicoBottomSheet(context, s),
                          onLongPress: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Excluir subcategoria'),
                                content: Text(
                                  'Deseja realmente excluir "${s.nome}"?',
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
                              await controller.excluirSubcategoria(s.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary,
          icon: const Icon(Icons.add),
          label: const Text('Nova Subcategoria'),
          onPressed: () => showSubcategoriaServicoBottomSheet(context),
        ),
      );
    });
  }
}
