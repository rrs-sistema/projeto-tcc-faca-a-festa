import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/eventos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

class EventosAdminListScreen extends StatelessWidget {
  final EventosAdminController controller;
  final EventThemeController themeController;

  EventosAdminListScreen({
    super.key,
    required this.controller,
    required this.themeController,
  }) {
    Future.microtask(() {
      controller.carregarEventosComTipo();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                children: [
                  AdminSearchField(
                    hint: 'Buscar por nome, tipo, cidade ou organizador',
                    onChanged: (v) => controller.busca.value = v,
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AdminSummaryChip(
                            label: 'Total',
                            value: '${controller.eventos.length}',
                            color: AdminPalette.primary,
                            icon: Icons.event_rounded,
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Em curso',
                            value: '${controller.totalAtivos}',
                            color: AdminPalette.success,
                            icon: Icons.play_circle_outline_rounded,
                          ),
                        ],
                      ),
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
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
  final EventoAdmin evento;
  final EventosAdminController controller;

  const _EventoAdminCard({required this.evento, required this.controller});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = evento.data != null
        ? DateFormat('dd/MM/yyyy').format(evento.data!)
        : 'Indefinida';

    return AdminCard(
      child: Row(
        children: [
          AdminLeadingMark(
            icon: evento.emCurso
                ? Icons.event_available_rounded
                : Icons.event_note_rounded,
            color: evento.emCurso ? AdminPalette.success : AdminPalette.warning,
          ),
          const SizedBox(width: 10),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          height: 1.2,
                          color: AdminPalette.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AdminStatusChip(
                      label: evento.statusLabel,
                      color: evento.emCurso
                          ? AdminPalette.success
                          : AdminPalette.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                AdminMetaLine(
                  parts: [
                    evento.tipoNome,
                    evento.cidade ?? 'Cidade não cadastrada',
                    evento.organizador,
                    dataFormatada,
                    if (evento.totalConvidados > 0)
                      '${evento.totalConvidados} convidados',
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert_rounded,
                color: Colors.grey.shade400, size: 18),
            onSelected: (v) => controller.acaoEvento(v, evento),
            itemBuilder: (_) => [
              if (!evento.aprovado)
                const PopupMenuItem(value: 'aprovar', child: Text('Aprovar')),
              const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
