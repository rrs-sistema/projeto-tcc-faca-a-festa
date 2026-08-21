import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import './../../../app/bootstrap/eventos_admin_bootstrap.dart';
import './../../../controllers/admin/eventos_admin_controller.dart';
import './../../../data/models/admin/evento_com_tipo_model.dart';
import '../../../controllers/tema/admin_theme.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../widgets/admin/admin_kit.dart';

class EventosAdminListScreen extends StatelessWidget {
  EventosAdminListScreen({super.key}) {
    Future.microtask(() {
      EventosAdminBootstrap.findController().carregarEventosComTipo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = EventosAdminBootstrap.findController();
    final themeController = Get.find<EventThemeController>();

    return Theme(
      data: themeController.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Gestão de Eventos',
          subtitle: 'Acompanhamento da operação',
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: controller.carregarEventosComTipo,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  AdminSearchField(
                    hint: 'Buscar por nome, tipo, cidade ou organizador',
                    onChanged: (v) => controller.busca.value = v,
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    return Row(
                      children: [
                        AdminSummaryChip(
                          label: 'Total',
                          value: '${controller.eventos.length}',
                          color: AdminPalette.primary,
                          icon: Icons.event_rounded,
                        ),
                        const SizedBox(width: 8),
                        AdminSummaryChip(
                          label: 'Em curso',
                          value: '${controller.totalAtivos}',
                          color: AdminPalette.success,
                          icon: Icons.play_circle_outline_rounded,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.carregando.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.erro.isNotEmpty) {
                  return AdminEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Não foi possível carregar os eventos',
                    message: controller.erro.value,
                    actionLabel: 'Tentar de novo',
                    onAction: controller.carregarEventosComTipo,
                  );
                }
                final lista = controller.eventosFiltrados;
                if (lista.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: controller.eventos.isEmpty
                        ? 'Nenhum evento cadastrado'
                        : 'Nenhum evento nesta busca',
                    message:
                        'Os eventos criados pelos organizadores aparecem aqui.',
                  );
                }

                return RefreshIndicator(
                  color: AdminPalette.primary,
                  onRefresh: controller.carregarEventosComTipo,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _EventoAdminCard(
                      evento: lista[i],
                      controller: controller,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventoAdminCard extends StatelessWidget {
  final EventoComTipoModel evento;
  final EventosAdminController controller;

  const _EventoAdminCard({required this.evento, required this.controller});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = evento.data != null
        ? DateFormat('dd/MM/yyyy').format(evento.data!)
        : 'Indefinida';

    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: evento.emCurso
                  ? AdminPalette.success.withValues(alpha: 0.1)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              evento.emCurso
                  ? Icons.event_available_rounded
                  : Icons.event_note_rounded,
              color: evento.emCurso
                  ? AdminPalette.success
                  : Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        evento.nome,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AdminPalette.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: Colors.grey.shade500, size: 20),
                      onSelected: (v) => controller.acaoEvento(v, evento),
                      itemBuilder: (_) => [
                        if (!evento.aprovado)
                          const PopupMenuItem(
                              value: 'aprovar', child: Text('Aprovar')),
                        const PopupMenuItem(
                            value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AdminStatusChip(
                      label: evento.statusLabel,
                      color: evento.emCurso
                          ? AdminPalette.success
                          : AdminPalette.warning,
                    ),
                    AdminMetricChip(
                        icon: Icons.category_outlined, label: evento.tipoNome),
                    AdminMetricChip(
                      icon: Icons.location_on_outlined,
                      label: evento.cidade ?? 'Cidade não cadastrada',
                    ),
                    AdminMetricChip(
                        icon: Icons.person_outline, label: evento.organizador),
                    AdminMetricChip(
                        icon: Icons.calendar_month_outlined,
                        label: dataFormatada),
                    if (evento.totalConvidados > 0)
                      AdminMetricChip(
                        icon: Icons.groups_outlined,
                        label: '${evento.totalConvidados} convidados',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
