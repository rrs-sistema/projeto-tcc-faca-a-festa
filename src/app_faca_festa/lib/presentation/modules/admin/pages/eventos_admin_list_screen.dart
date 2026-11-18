import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/eventos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/evento_oportunidade_sheet.dart';
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
          subtitle: 'Pipeline comercial da operação',
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
                            onTap: () => controller
                                .definirFiltro(FiltroComercialEvento.todos),
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Sem cotação',
                            value: '${controller.totalSemCotacao}',
                            color: AdminPalette.warning,
                            icon: Icons.mark_email_unread_outlined,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.semCotacao),
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Conv. geral',
                            value: controller.taxaConversaoLabel,
                            color: AdminPalette.primary,
                            icon: Icons.insights_rounded,
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Conv. 30d',
                            value: controller.labelConversaoJanela(30),
                            color: AdminPalette.danger,
                            icon: Icons.timelapse_rounded,
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Conv. 60d',
                            value: controller.labelConversaoJanela(60),
                            color: AdminPalette.warning,
                            icon: Icons.timelapse_rounded,
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Conv. 90d',
                            value: controller.labelConversaoJanela(90),
                            color: AdminPalette.accent,
                            icon: Icons.timelapse_rounded,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.proximos90Dias),
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Follow-up',
                            value: '${controller.totalFollowUp}',
                            color: AdminPalette.primary,
                            icon: Icons.flag_outlined,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.followUp),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Obx(() {
                    final filtro = controller.filtroComercial.value;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FiltroChip(
                            label: 'Todos',
                            selected: filtro == FiltroComercialEvento.todos,
                            onTap: () => controller
                                .definirFiltro(FiltroComercialEvento.todos),
                          ),
                          const SizedBox(width: 6),
                          _FiltroChip(
                            label: 'Sem cotação',
                            selected:
                                filtro == FiltroComercialEvento.semCotacao,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.semCotacao),
                          ),
                          const SizedBox(width: 6),
                          _FiltroChip(
                            label: 'Próximos 90 dias',
                            selected:
                                filtro == FiltroComercialEvento.proximos90Dias,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.proximos90Dias),
                          ),
                          const SizedBox(width: 6),
                          _FiltroChip(
                            label: 'Prioridade alta',
                            selected:
                                filtro == FiltroComercialEvento.prioridadeAlta,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.prioridadeAlta),
                          ),
                          const SizedBox(width: 6),
                          _FiltroChip(
                            label: 'Organizador recorrente',
                            selected: filtro ==
                                FiltroComercialEvento.organizadorRecorrente,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.organizadorRecorrente),
                          ),
                          const SizedBox(width: 6),
                          _FiltroChip(
                            label: 'Follow-up',
                            selected: filtro == FiltroComercialEvento.followUp,
                            onTap: () => controller.definirFiltro(
                                FiltroComercialEvento.followUp),
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
                final heatmap = controller.heatmapCidadeTipo;
                if (lista.isEmpty && controller.eventos.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'Nenhum evento cadastrado',
                    message:
                        'Os eventos criados pelos organizadores aparecem aqui como leads potenciais.',
                  );
                }

                return RefreshIndicator(
                  color: AdminPalette.primary,
                  onRefresh: controller.carregarEventosComTipo,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: lista.isEmpty ? 2 : lista.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _HeatmapDemanda(
                          celulas: heatmap,
                          expandido: controller.mostrarHeatmap.value,
                          onToggle: () => controller.mostrarHeatmap.toggle(),
                        );
                      }
                      if (lista.isEmpty) {
                        return AdminEmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'Nenhum evento neste filtro',
                          message: 'Ajuste a busca ou o filtro comercial.',
                        );
                      }
                      return _EventoAdminCard(
                        evento: lista[i - 1],
                        controller: controller,
                      );
                    },
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

class _HeatmapDemanda extends StatelessWidget {
  const _HeatmapDemanda({
    required this.celulas,
    required this.expandido,
    required this.onToggle,
  });

  final List<HeatmapDemandaCelula> celulas;
  final bool expandido;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 16, color: AdminPalette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demanda por cidade × tipo',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AdminPalette.ink,
                  ),
                ),
              ),
              Icon(
                expandido
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: AdminPalette.muted,
              ),
            ],
          ),
          if (expandido) ...[
            const SizedBox(height: 8),
            if (celulas.isEmpty)
              Text(
                'Sem eventos em curso para mapear.',
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: AdminPalette.muted),
              )
            else
              ...celulas.take(8).map((c) {
                final intensidade = c.semCotacao == 0
                    ? 0.08
                    : (0.12 + (c.semCotacao / (c.quantidade + 1)) * 0.35)
                        .clamp(0.12, 0.45);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AdminPalette.warning.withValues(alpha: intensidade),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminPalette.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${c.cidade} · ${c.tipoNome}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AdminPalette.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${c.quantidade} evt · ${c.semCotacao} sem cotação',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AdminPalette.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AdminPalette.ink,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AdminPalette.primary,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected ? AdminPalette.primary : AdminPalette.border,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
    final score = controller.scoreDe(evento);
    final prioridade = controller.prioridadeDe(evento);
    final dias = evento.diasAteEvento;

    return AdminCard(
      onTap: () => mostrarOportunidadeEvento(
        context: context,
        controller: controller,
        evento: evento,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminLeadingMark(
            icon: evento.semCotacao
                ? Icons.lightbulb_outline_rounded
                : Icons.event_available_rounded,
            color: evento.semCotacao
                ? AdminPalette.warning
                : (evento.emCurso
                    ? AdminPalette.success
                    : AdminPalette.muted),
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    AdminMetricChip(
                      icon: Icons.trending_up_rounded,
                      label: 'Lead $score · $prioridade',
                    ),
                    AdminMetricChip(
                      icon: Icons.payments_outlined,
                      label: evento.faixaTicketEstimada,
                    ),
                    if (dias != null && dias >= 0)
                      AdminMetricChip(
                        icon: Icons.timelapse_rounded,
                        label: dias == 0 ? 'Hoje' : 'Em $dias d',
                      ),
                    AdminStatusChip(
                      label: evento.semCotacao
                          ? 'Sem cotação'
                          : '${evento.totalCotacoes} cotação(ões)',
                      color: evento.semCotacao
                          ? AdminPalette.warning
                          : AdminPalette.success,
                      icon: evento.semCotacao
                          ? Icons.mark_email_unread_outlined
                          : Icons.request_quote_outlined,
                    ),
                    if (evento.organizadorRecorrente)
                      AdminStatusChip(
                        label: 'Recorrente',
                        color: AdminPalette.primary,
                        icon: Icons.repeat_rounded,
                      ),
                    if (evento.temFollowUp)
                      AdminStatusChip(
                        label: 'Follow-up',
                        color: AdminPalette.primary,
                        icon: Icons.flag_outlined,
                      ),
                    if (evento.temNudge)
                      AdminStatusChip(
                        label: 'Nudged',
                        color: AdminPalette.accent,
                        icon: Icons.campaign_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert_rounded,
                color: Colors.grey.shade400, size: 18),
            onSelected: (v) async {
              if (v == 'oportunidade') {
                await mostrarOportunidadeEvento(
                  context: context,
                  controller: controller,
                  evento: evento,
                );
                return;
              }
              await controller.acaoEvento(v, evento);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'oportunidade',
                child: Text('Ver oportunidade'),
              ),
              const PopupMenuItem(
                value: 'follow_up',
                child: Text('Marcar follow-up'),
              ),
              const PopupMenuItem(
                value: 'nudge',
                child: Text('Nudge organizador'),
              ),
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
