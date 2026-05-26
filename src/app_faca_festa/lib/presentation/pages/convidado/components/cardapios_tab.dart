import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';
import './../../../../data/models/cardapio/cardapio_model.dart';
import './add_item_cardapio_bottom_sheet.dart';
import './cadastro_cardapio_bottom_sheet.dart';
import './editar_item_cardapio_bottom_sheet.dart';
import './editar_cardapio_bottomsheet.dart';

class CardapiosTab extends StatelessWidget {
  const CardapiosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        final primary = theme.primaryColor.value;

        if (controller.carregando.value) {
          return Center(
            child: CircularProgressIndicator(color: primary),
          );
        }

        if (controller.cardapios.isEmpty) {
          return _CardapioEmptyState(primary: primary);
        }

        return RefreshIndicator(
          color: primary,
          onRefresh: () async {
            // Mantém compatibilidade com controllers que atualizam via GetX/stream.
            await Future<void>.delayed(const Duration(milliseconds: 350));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 140),
            children: [
              _CardapioHeader(controller: controller, primary: primary),
              const SizedBox(height: 16),
              _CardapioQuickStats(controller: controller, primary: primary),
              const SizedBox(height: 22),
              _SectionHeader(
                icon: Icons.restaurant_menu_rounded,
                title: 'Cardápios cadastrados',
                subtitle:
                    'Organize o que será servido por categoria e acompanhe o que já está definido.',
                color: primary,
              ),
              const SizedBox(height: 12),
              ...controller.cardapios.map(
                (cardapio) => _CardapioCategoriaCard(cardapio: cardapio),
              ),
              const SizedBox(height: 14),
              _ResumoCardapioResumo(controller: controller),
              const SizedBox(height: 20),
              _GraficoCardapio(controller: controller),
            ],
          ),
        );
      }),
    );
  }
}

class _CardapioEmptyState extends StatelessWidget {
  final Color primary;

  const _CardapioEmptyState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: primary.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Nenhum cardápio cadastrado',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Monte categorias como comidas, bebidas, sobremesas e descartáveis para ter uma visão clara do que será servido no evento.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 13.5,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tips_and_updates_rounded, color: primary, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Use o botão “Novo cardápio” para começar.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardapioHeader extends StatelessWidget {
  final CardapioController controller;
  final Color primary;

  const _CardapioHeader({
    required this.controller,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final totalItens = _toInt(controller.totalItens);
    final confirmados = _totalItensConfirmados(controller);
    final progresso = totalItens == 0 ? 0.0 : confirmados / totalItens;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.96),
            primary.withValues(alpha: 0.76),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Icon(
                  Icons.room_service_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cardápio do evento',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Controle comidas, bebidas, sobremesas e itens confirmados para servir seus convidados com organização.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresso.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalItens == 0
                ? 'Comece cadastrando os primeiros itens do cardápio.'
                : '$confirmados de $totalItens itens marcados como definidos.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardapioQuickStats extends StatelessWidget {
  final CardapioController controller;
  final Color primary;

  const _CardapioQuickStats({
    required this.controller,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
        label: 'Categorias',
        value: _toInt(controller.totalCardapios).toString(),
        icon: Icons.dashboard_customize_rounded,
        color: primary,
      ),
      _StatData(
        label: 'Itens',
        value: _toInt(controller.totalItens).toString(),
        icon: Icons.checklist_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _StatData(
        label: 'Bebidas',
        value: _toInt(controller.totalBebidas).toString(),
        icon: Icons.local_drink_rounded,
        color: const Color(0xFF2563EB),
      ),
      _StatData(
        label: 'Sobremesas',
        value: _toInt(controller.totalSobremesas).toString(),
        icon: Icons.cake_rounded,
        color: const Color(0xFFDB2777),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 680
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _StatMiniCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final _StatData data;

  const _StatMiniCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardapioCategoriaCard extends StatelessWidget {
  final CardapioModel cardapio;

  const _CardapioCategoriaCard({required this.cardapio});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();

    return Obx(() {
      final itens = controller.itensDoCardapio(cardapio.idCardapio);
      final totalItens = controller.totalItensDoCardapio(cardapio.idCardapio);
      final itensConfirmados = itens.where((i) => i.confirmado).length;
      final color = _colorFromHex(cardapio.corHex, fallback: theme.primaryColor.value);
      final icon = _iconFromString(cardapio.icone);

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            leading: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(
              cardapio.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                color: const Color(0xFF111827),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.format_list_bulleted_rounded,
                    label: _itensIncluidosLabel(totalItens),
                    color: color,
                  ),
                  _InfoChip(
                    icon: Icons.verified_rounded,
                    label: '$itensConfirmados definidos',
                    color: const Color(0xFF059669),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleAction(
                  icon: Icons.add_rounded,
                  color: color,
                  tooltip: 'Adicionar item',
                  onTap: () => abrirAdicionarItemCardapio(
                    context,
                    cardapio.idEvento,
                    cardapio.idCardapio,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Mais opções',
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      abrirEditarCardapio(context, cardapio);
                      return;
                    }

                    if (value == 'delete') {
                      final confirmar = await _confirmDelete(
                        context: context,
                        title: 'Excluir cardápio?',
                        message: 'Essa ação removerá a categoria e os itens vinculados a ela.',
                        confirmLabel: 'Excluir',
                      );

                      if (confirmar) {
                        controller.excluirCardapio(cardapio.idCardapio);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: _MenuActionRow(
                        icon: Icons.edit_rounded,
                        label: 'Editar cardápio',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuActionRow(
                        icon: Icons.delete_forever_rounded,
                        label: 'Excluir cardápio',
                        danger: true,
                      ),
                    ),
                  ],
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 20),
                  ),
                ),
              ],
            ),
            children: itens.isNotEmpty
                ? itens
                    .map(
                      (item) => _CardapioItemTile(
                        item: item,
                        idCardapio: cardapio.idCardapio,
                      ),
                    )
                    .toList()
                : [
                    _EmptyItemsCard(color: color),
                  ],
          ),
        ),
      );
    });
  }

  Widget _circleAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

class _MenuActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _MenuActionRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF334155);

    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyItemsCard extends StatelessWidget {
  final Color color;

  const _EmptyItemsCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhum item cadastrado nesta categoria. Toque no botão + para adicionar.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardapioItemTile extends StatelessWidget {
  final CardapioItemModel item;
  final String idCardapio;

  const _CardapioItemTile({
    required this.item,
    required this.idCardapio,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();

    return buildItemCardapio(
      context: context,
      item: item,
      idCardapio: idCardapio,
      controller: controller,
      theme: theme,
    );
  }
}

Widget buildItemCardapio({
  required BuildContext context,
  required CardapioItemModel item,
  required String idCardapio,
  required CardapioController controller,
  required EventThemeController theme,
}) {
  final primary = theme.primaryColor.value;
  final typeColor = _colorByTipo(item.tipo, primary);

  return AnimatedContainer(
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: item.confirmado ? primary.withValues(alpha: 0.055) : const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        width: 1,
        color: item.confirmado ? primary.withValues(alpha: 0.20) : const Color(0xFFE2E8F0),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Tooltip(
          message: item.confirmado ? 'Marcar como pendente' : 'Marcar como definido',
          child: InkWell(
            onTap: () => controller.toggleConfirmado(idCardapio, item),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.confirmado ? primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                item.confirmado ? Icons.check_rounded : Icons.circle_outlined,
                color: item.confirmado ? Colors.white : const Color(0xFF94A3B8),
                size: 23,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: _iconByTipo(item.tipo),
                    label: _tipoItemLabel(item.tipo),
                    color: typeColor,
                  ),
                  _InfoChip(
                    icon: item.confirmado ? Icons.verified_rounded : Icons.schedule_rounded,
                    label: item.confirmado ? 'Definido' : 'Pendente',
                    color: item.confirmado ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          tooltip: 'Opções do item',
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          onSelected: (value) async {
            if (value == 'edit') {
              abrirEditarItemCardapio(context, idCardapio, item);
              return;
            }

            if (value == 'delete') {
              final confirmar = await _confirmDelete(
                context: context,
                title: 'Excluir item?',
                message: 'O item “${item.nome}” será removido deste cardápio.',
                confirmLabel: 'Excluir',
              );

              if (confirmar) {
                controller.excluirItem(idCardapio, item.idItem);
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: _MenuActionRow(
                icon: Icons.edit_rounded,
                label: 'Editar item',
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: _MenuActionRow(
                icon: Icons.delete_forever_rounded,
                label: 'Excluir item',
                danger: true,
              ),
            ),
          ],
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.more_horiz_rounded, color: Color(0xFF475569), size: 22),
          ),
        ),
      ],
    ),
  );
}

class _ResumoCardapioResumo extends StatelessWidget {
  final CardapioController controller;

  const _ResumoCardapioResumo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;
    final totalItens = _toInt(controller.totalItens);
    final definidos = _totalItensConfirmados(controller);
    final pendentes = totalItens - definidos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.analytics_rounded,
            title: 'Resumo operacional',
            subtitle: 'Uma visão rápida do andamento do cardápio.',
            color: primary,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 640
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryLineCard(
                      icon: Icons.task_alt_rounded,
                      label: 'Itens definidos',
                      value: definidos.toString(),
                      color: const Color(0xFF059669),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryLineCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pendentes',
                      value: pendentes < 0 ? '0' : pendentes.toString(),
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryLineCard(
                      icon: Icons.restaurant_rounded,
                      label: 'Comidas',
                      value: _toInt(controller.totalComidas).toString(),
                      color: primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryLineCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryLineCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoCardapio extends StatelessWidget {
  final CardapioController controller;

  const _GraficoCardapio({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    final comidas = _toInt(controller.totalComidas).toDouble();
    final bebidas = _toInt(controller.totalBebidas).toDouble();
    final sobremesas = _toInt(controller.totalSobremesas).toDouble();
    final outros = (_toInt(controller.totalItens).toDouble() - comidas - bebidas - sobremesas)
        .clamp(0, double.infinity);
    final total = comidas + bebidas + sobremesas + outros;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.pie_chart_rounded,
            title: 'Composição do cardápio',
            subtitle: 'Distribuição dos itens cadastrados por tipo.',
            color: primary,
          ),
          const SizedBox(height: 18),
          if (total == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Ainda não há dados suficientes para gerar o gráfico.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            SizedBox(
              height: 230,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 58,
                  startDegreeOffset: -90,
                  sections: [
                    if (comidas > 0) _pieSection('Comidas', comidas, total, primary),
                    if (bebidas > 0)
                      _pieSection('Bebidas', bebidas, total, const Color(0xFF2563EB)),
                    if (sobremesas > 0)
                      _pieSection('Sobremesas', sobremesas, total, const Color(0xFFDB2777)),
                    if (outros > 0)
                      _pieSection('Outros', outros.toDouble(), total, const Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (comidas > 0) _graficoLegenda('Comidas', comidas.toInt(), primary),
                if (bebidas > 0)
                  _graficoLegenda('Bebidas', bebidas.toInt(), const Color(0xFF2563EB)),
                if (sobremesas > 0)
                  _graficoLegenda('Sobremesas', sobremesas.toInt(), const Color(0xFFDB2777)),
                if (outros > 0) _graficoLegenda('Outros', outros.toInt(), const Color(0xFF64748B)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(String label, double value, double total, Color color) {
    final percent = total == 0 ? 0 : (value / total) * 100;

    return PieChartSectionData(
      color: color,
      value: value,
      title: '${percent.toStringAsFixed(0)}%',
      radius: 68,
      titleStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      badgeWidget: percent >= 12 ? null : _SmallChartBadge(label: label, color: color),
      badgePositionPercentageOffset: 1.18,
    );
  }

  Widget _graficoLegenda(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 6),
          Text(
            '$label · $value',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChartBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallChartBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

Color _colorFromHex(String? hex, {required Color fallback}) {
  if (hex == null || hex.trim().isEmpty) {
    return fallback;
  }

  try {
    var value = hex.replaceAll('#', '').trim();

    if (value.length == 6) {
      value = 'FF$value';
    }

    if (value.length != 8) {
      return fallback;
    }

    return Color(int.parse(value, radix: 16));
  } catch (_) {
    return fallback;
  }
}

IconData _iconFromString(String? value) {
  final codePoint = int.tryParse(value ?? '');

  if (codePoint == null || codePoint == 0) {
    return Icons.restaurant_menu_rounded;
  }

  return IconData(
    codePoint,
    fontFamily: 'MaterialIcons',
  );
}

String _itensIncluidosLabel(int quantidade) {
  if (quantidade == 1) {
    return '1 item incluído';
  }

  return '$quantidade itens incluídos';
}

String _tipoItemLabel(dynamic tipo) {
  final raw = _enumValueToText(tipo);
  final normalized = _normalizeText(raw);

  switch (normalized) {
    case 'comida':
      return 'Comida';
    case 'bebida':
      return 'Bebida';
    case 'sobremesa':
      return 'Sobremesa';
    case 'bolo':
      return 'Bolo';
    case 'descartavel':
      return 'Descartável';
    case 'outro':
      return 'Outro';
    default:
      if (raw.trim().isEmpty) return '-';
      return raw;
  }
}

IconData _iconByTipo(dynamic tipo) {
  final normalized = _normalizeText(_enumValueToText(tipo));

  switch (normalized) {
    case 'comida':
      return Icons.restaurant_rounded;
    case 'bebida':
      return Icons.local_drink_rounded;
    case 'sobremesa':
      return Icons.cake_rounded;
    case 'bolo':
      return Icons.cake_outlined;
    case 'descartavel':
      return Icons.inventory_2_rounded;
    default:
      return Icons.room_service_rounded;
  }
}

Color _colorByTipo(dynamic tipo, Color fallback) {
  final normalized = _normalizeText(_enumValueToText(tipo));

  switch (normalized) {
    case 'comida':
      return fallback;
    case 'bebida':
      return const Color(0xFF2563EB);
    case 'sobremesa':
    case 'bolo':
      return const Color(0xFFDB2777);
    case 'descartavel':
      return const Color(0xFF64748B);
    default:
      return const Color(0xFF7C3AED);
  }
}

String _enumValueToText(dynamic value) {
  if (value == null) return '';

  try {
    final dynamic dynamicValue = value;
    final firestoreValue = dynamicValue.firestoreValue;

    if (firestoreValue != null) {
      return firestoreValue.toString();
    }
  } catch (_) {
    // Compatibilidade com String ou enum sem firestoreValue.
  }

  try {
    final dynamic dynamicValue = value;
    final enumName = dynamicValue.name;

    if (enumName != null) {
      return enumName.toString();
    }
  } catch (_) {
    // Compatibilidade com String.
  }

  final text = value.toString();
  return text.contains('.') ? text.split('.').last : text;
}

String _normalizeText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  try {
    final dynamic dynamicValue = value;
    final dynamic innerValue = dynamicValue.value;

    if (innerValue is int) return innerValue;
    if (innerValue is num) return innerValue.toInt();
  } catch (_) {
    // Compatibilidade com getters simples.
  }

  return int.tryParse(value.toString()) ?? 0;
}

int _totalItensConfirmados(CardapioController controller) {
  var total = 0;

  for (final cardapio in controller.cardapios) {
    total +=
        controller.itensDoCardapio(cardapio.idCardapio).where((item) => item.confirmado).length;
  }

  return total;
}

Future<bool> _confirmDelete({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.poppins(
          color: const Color(0xFF64748B),
          fontSize: 13.5,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Cancelar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(
            confirmLabel,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}

void abrirEditarItemCardapio(
  BuildContext context,
  String idCardapio,
  CardapioItemModel item,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => EditarItemCardapioBottomSheet(
      idCardapio: idCardapio,
      item: item,
    ),
  );
}

void abrirCadastroCardapio(BuildContext context, String idEvento) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => CadastroCardapioBottomSheet(idEvento: idEvento),
  );
}

void abrirAdicionarItemCardapio(
  BuildContext context,
  String idEvento,
  String idCardapio,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => AddItemCardapioBottomSheet(
      idEvento: idEvento,
      idCardapio: idCardapio,
    ),
  );
}

void abrirEditarCardapio(BuildContext context, CardapioModel cardapio) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => EditarCardapioBottomSheet(cardapio: cardapio),
  );
}
