import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/admin/eventos_admin_controller.dart';
import './../../../data/models/admin/evento_com_tipo_model.dart';
import '../../../controllers/tema/event_theme_controller.dart';

class EventosAdminListScreen extends StatelessWidget {
  EventosAdminListScreen({super.key}) {
    Future.microtask(() {
      if (Get.isRegistered<EventosAdminController>()) {
        Get.find<EventosAdminController>().carregarEventosComTipo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EventosAdminController>();
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Gestão de Eventos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: Colors.grey.shade50,
      body: Obx(() {
        if (controller.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erro.isNotEmpty) {
          return Center(
            child: Text(
              controller.erro.value,
              style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 14),
            ),
          );
        }

        if (controller.eventos.isEmpty) {
          return Center(
            child: Text(
              'Nenhum evento cadastrado ainda.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.carregarEventosComTipo,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: controller.eventos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final e = controller.eventos[i];
              return _buildEventoCard(context, e, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEventoCard(
    BuildContext context,
    EventoComTipoModel e,
    EventosAdminController controller,
  ) {
    final aprovado = e.aprovado;
    final dataFormatada =
        e.data != null ? '${e.data!.day}/${e.data!.month}/${e.data!.year}' : 'Indefinida';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: aprovado ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                aprovado ? Icons.verified_rounded : Icons.pending_actions_rounded,
                color: aprovado ? Colors.green.shade600 : Colors.orange.shade600,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          e.nome,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.grey.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500, size: 20),
                        padding: EdgeInsets.zero,
                        onSelected: (v) => controller.acaoEvento(v, e),
                        itemBuilder: (_) => [
                          if (!aprovado)
                            PopupMenuItem(
                                value: 'aprovar',
                                child: Text('Aprovar', style: GoogleFonts.poppins(fontSize: 13))),
                          PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar', style: GoogleFonts.poppins(fontSize: 13))),
                          PopupMenuItem(
                              value: 'excluir',
                              child: Text('Excluir',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Uso do WRAP protege o layout contra o RenderFlex Overflow
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildInfoChip(Icons.category_outlined, e.tipoNome),
                      _buildInfoChip(
                          Icons.location_on_outlined, e.cidade ?? 'Cidade não cadastrada'),
                      _buildInfoChip(Icons.person_outline, e.organizador),
                      _buildInfoChip(Icons.calendar_month_outlined, dataFormatada),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
