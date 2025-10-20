import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../../controllers/servico_produto_controller.dart';
import './../../../../controllers/event_theme_controller.dart';
import './show_servico_produto_bottom_sheet.dart';

class ServicoProdutoListScreen extends StatelessWidget {
  const ServicoProdutoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServicoProdutoController());
    final theme = Get.find<EventThemeController>();

    // 🔹 Mapa de conversão de unidade
    final Map<String, String> medidas = {
      'U': 'Unidade',
      'H': 'Hora',
      'D': 'Diária',
      'P': 'Pacote',
    };

    return Obx(() {
      final gradient = theme.gradient.value;
      final primary = theme.primaryColor.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Serviços / Produtos',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),
        backgroundColor: Colors.grey.shade100,
        body: controller.carregando.value
            ? const Center(child: CircularProgressIndicator())
            : controller.servicos.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum serviço cadastrado ainda',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.servicos.length,
                    itemBuilder: (_, i) {
                      final s = controller.servicos[i];
                      final tipo = medidas[s.tipoMedida] ?? s.tipoMedida ?? '-';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: Icon(Icons.design_services, color: primary),
                          ),
                          title: Text(
                            s.nome,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.descricao != null && s.descricao!.isNotEmpty)
                                Text(
                                  s.descricao!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primary.withValues(alpha: 0.4), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.straighten_outlined, size: 16, color: primary),
                                const SizedBox(width: 4),
                                Text(
                                  tipo,
                                  style: GoogleFonts.poppins(
                                    color: primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => showServicoProdutoBottomSheet(context, s),
                          onLongPress: () => controller.excluirServico(s.id),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary,
          icon: const Icon(Icons.add),
          label: const Text('Novo Serviço'),
          onPressed: () => showServicoProdutoBottomSheet(context),
        ),
      );
    });
  }
}
