import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/admin/eventos_admin_controller.dart';
import './../../../data/models/admin/evento_com_tipo_model.dart';
import './../../../controllers/event_theme_controller.dart';

class EventosAdminListScreen extends StatelessWidget {
  const EventosAdminListScreen({super.key});

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
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Obx(() {
        if (controller.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erro.isNotEmpty) {
          return Center(
            child: Text(
              controller.erro.value,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (controller.eventos.isEmpty) {
          return Center(
            child: Text(
              'Nenhum evento cadastrado ainda.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.carregarEventosComTipo,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: controller.eventos.length,
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
    EventoComTipoModel e, // ⬅️ Troque o tipo aqui
    EventosAdminController controller,
  ) {
    final aprovado = e.aprovado;
    final dataFormatada =
        e.data != null ? '${e.data!.day}/${e.data!.month}/${e.data!.year}' : 'Data indefinida';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: aprovado ? Colors.blue.shade100 : Colors.grey.shade300,
          child: Icon(
            aprovado ? Icons.verified_rounded : Icons.pending_outlined,
            color: aprovado ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
        ),
        title: Text(
          e.nome,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${e.tipoNome} — ${e.cidade}', style: GoogleFonts.poppins(fontSize: 13)),
            Text('Organizador: ${e.organizador}', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Data: $dataFormatada', style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => controller.acaoEvento(v, e),
          itemBuilder: (_) => [
            if (!aprovado) const PopupMenuItem(value: 'aprovar', child: Text('Aprovar')),
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
            const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}
