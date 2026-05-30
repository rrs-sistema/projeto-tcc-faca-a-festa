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
          return Center(child: CircularProgressIndicator(color: primary));
        }
        if (controller.cardapios.isEmpty) return _CardapioEmptyState(primary: primary);

        return RefreshIndicator(
          color: primary,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 350));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            children: [
              _CardapioHeader(controller: controller, primary: primary),
              const SizedBox(height: 12),
              _CardapioQuickStats(controller: controller, primary: primary),
              const SizedBox(height: 16),
              _SectionHeader(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Cardápios',
                  subtitle: 'Organize por categoria.',
                  color: primary),
              const SizedBox(height: 10),
              ...controller.cardapios.map((cardapio) => _CardapioCategoriaCard(cardapio: cardapio)),
              const SizedBox(height: 10),
              _ResumoCardapioResumo(controller: controller),
              const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withValues(alpha: 0.10)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.restaurant_menu_rounded, color: primary, size: 26)),
              const SizedBox(height: 12),
              Text('Nenhum cardápio',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
              Text('Monte categorias para organizar o evento.',
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12),
                  textAlign: TextAlign.center),
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
  const _CardapioHeader({required this.controller, required this.primary});

  @override
  Widget build(BuildContext context) {
    final totalItens = _toInt(controller.totalItens);
    final confirmados = _totalItensConfirmados(controller);
    final progresso = totalItens == 0 ? 0.0 : confirmados / totalItens;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [primary.withValues(alpha: 0.96), primary.withValues(alpha: 0.76)]),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.room_service_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cardápio do evento',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    Text('Controle os itens servidos.',
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.88), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: progresso.clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(
              totalItens == 0
                  ? 'Cadastre os itens.'
                  : '$confirmados de $totalItens itens definidos.',
              style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CardapioQuickStats extends StatelessWidget {
  final CardapioController controller;
  final Color primary;
  const _CardapioQuickStats({required this.controller, required this.primary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
          label: 'Cat.',
          value: _toInt(controller.totalCardapios).toString(),
          icon: Icons.dashboard_customize_rounded,
          color: primary),
      _StatData(
          label: 'Itens',
          value: _toInt(controller.totalItens).toString(),
          icon: Icons.checklist_rounded,
          color: const Color(0xFFF59E0B)),
      _StatData(
          label: 'Bebidas',
          value: _toInt(controller.totalBebidas).toString(),
          icon: Icons.local_drink_rounded,
          color: const Color(0xFF2563EB)),
      _StatData(
          label: 'Sobremesas',
          value: _toInt(controller.totalSobremesas).toString(),
          icon: Icons.cake_rounded,
          color: const Color(0xFFDB2777)),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 8) / 2;
      return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: _StatMiniCard(data: card)))
              .toList());
    });
  }
}

class _StatMiniCard extends StatelessWidget {
  final _StatData data;
  const _StatMiniCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: data.color.withValues(alpha: 0.12))),
      child: Row(
        children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(data.icon, color: data.color, size: 18)),
          const SizedBox(width: 8),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.value,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
            Text(data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B)))
          ])),
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
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 8),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w800)),
          Text(subtitle, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10))
        ])),
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.16))),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            leading: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 18)),
            title: Text(cardapio.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF111827))),
            subtitle: Wrap(spacing: 6, runSpacing: 4, children: [
              _InfoChip(
                  icon: Icons.format_list_bulleted_rounded,
                  label: _itensIncluidosLabel(totalItens),
                  color: color),
              _InfoChip(
                  icon: Icons.verified_rounded,
                  label: '$itensConfirmados def.',
                  color: const Color(0xFF059669))
            ]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleAction(
                    icon: Icons.add_rounded,
                    color: color,
                    onTap: () => abrirAdicionarItemCardapio(
                        context, cardapio.idEvento, cardapio.idCardapio)),
                PopupMenuButton<String>(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'edit') abrirEditarCardapio(context, cardapio);
                    if (v == 'delete') controller.excluirCardapio(cardapio.idCardapio);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Editar', style: TextStyle(fontSize: 12))),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir', style: TextStyle(fontSize: 12, color: Colors.red)))
                  ],
                  child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                      child:
                          const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 16)),
                ),
              ],
            ),
            children: itens.isNotEmpty
                ? itens
                    .map((item) => _CardapioItemTile(item: item, idCardapio: cardapio.idCardapio))
                    .toList()
                : [_EmptyItemsCard(color: color)],
          ),
        ),
      );
    });
  }

  Widget _circleAction(
      {required IconData icon, required Color color, required VoidCallback onTap}) {
    return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InkWell(
            onTap: onTap,
            child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 16))));
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(color: color, fontSize: 9, fontWeight: FontWeight.w700))
        ]));
  }
}

class _EmptyItemsCard extends StatelessWidget {
  final Color color;
  const _EmptyItemsCard({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.12))),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Vazio. Adicione itens.',
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11)))
        ]));
  }
}

class _CardapioItemTile extends StatelessWidget {
  final CardapioItemModel item;
  final String idCardapio;
  const _CardapioItemTile({required this.item, required this.idCardapio});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final primary = Get.find<EventThemeController>().primaryColor.value;
    final typeColor = _colorByTipo(item.tipo, primary);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: item.confirmado ? primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              width: 1,
              color: item.confirmado ? primary.withValues(alpha: 0.2) : const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          InkWell(
              onTap: () => controller.toggleConfirmado(idCardapio, item),
              child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: item.confirmado ? primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(item.confirmado ? Icons.check_rounded : Icons.circle_outlined,
                      color: item.confirmado ? Colors.white : const Color(0xFF94A3B8), size: 18))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
            Wrap(spacing: 4, runSpacing: 4, children: [
              _InfoChip(
                  icon: _iconByTipo(item.tipo), label: _tipoItemLabel(item.tipo), color: typeColor),
              _InfoChip(
                  icon: item.confirmado ? Icons.verified_rounded : Icons.schedule_rounded,
                  label: item.confirmado ? 'Def.' : 'Pend.',
                  color: item.confirmado ? const Color(0xFF059669) : const Color(0xFFF59E0B))
            ])
          ])),
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'edit') abrirEditarItemCardapio(context, idCardapio, item);
              if (v == 'delete') controller.excluirItem(idCardapio, item.idItem);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit', child: Text('Editar', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir', style: TextStyle(fontSize: 12, color: Colors.red)))
            ],
            child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.more_horiz_rounded, color: Color(0xFF475569), size: 16)),
          ),
        ],
      ),
    );
  }
}

class _ResumoCardapioResumo extends StatelessWidget {
  final CardapioController controller;
  const _ResumoCardapioResumo({required this.controller});
  @override
  Widget build(BuildContext context) {
    final primary = Get.find<EventThemeController>().primaryColor.value;
    final totalItens = _toInt(controller.totalItens);
    final definidos = _totalItensConfirmados(controller);
    final pendentes = totalItens - definidos;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary.withValues(alpha: 0.10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              icon: Icons.analytics_rounded,
              title: 'Resumo',
              subtitle: 'Andamento rápido.',
              color: primary),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _SummaryLineCard(
                      icon: Icons.task_alt_rounded,
                      label: 'Definidos',
                      value: definidos.toString(),
                      color: const Color(0xFF059669))),
              const SizedBox(width: 8),
              Expanded(
                  child: _SummaryLineCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pendentes',
                      value: pendentes < 0 ? '0' : pendentes.toString(),
                      color: const Color(0xFFF59E0B))),
            ],
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
  const _SummaryLineCard(
      {required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.10))),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
          Text(label, style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF64748B)))
        ]))
      ]),
    );
  }
}

class _GraficoCardapio extends StatelessWidget {
  final CardapioController controller;
  const _GraficoCardapio({required this.controller});
  @override
  Widget build(BuildContext context) {
    final primary = Get.find<EventThemeController>().primaryColor.value;
    final comidas = _toInt(controller.totalComidas).toDouble();
    final bebidas = _toInt(controller.totalBebidas).toDouble();
    final sobremesas = _toInt(controller.totalSobremesas).toDouble();
    final outros = (_toInt(controller.totalItens).toDouble() - comidas - bebidas - sobremesas)
        .clamp(0, double.infinity);
    final total = comidas + bebidas + sobremesas + outros;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12, bottom: 40),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary.withValues(alpha: 0.10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              icon: Icons.pie_chart_rounded,
              title: 'Composição',
              subtitle: 'Distribuição dos itens.',
              color: primary),
          const SizedBox(height: 12),
          if (total == 0)
            Text('Sem dados.', style: GoogleFonts.poppins(fontSize: 11))
          else ...[
            SizedBox(
                height: 180,
                child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    sections: [
                      if (comidas > 0) _pieSection('Com', comidas, total, primary),
                      if (bebidas > 0) _pieSection('Beb', bebidas, total, const Color(0xFF2563EB)),
                      if (sobremesas > 0)
                        _pieSection('Sob', sobremesas, total, const Color(0xFFDB2777)),
                      if (outros > 0)
                        _pieSection('Out', outros.toDouble(), total, const Color(0xFF64748B))
                    ]))),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (comidas > 0) _graficoLegenda('Comidas', comidas.toInt(), primary),
              if (bebidas > 0) _graficoLegenda('Bebidas', bebidas.toInt(), const Color(0xFF2563EB)),
              if (sobremesas > 0)
                _graficoLegenda('Sobremesas', sobremesas.toInt(), const Color(0xFFDB2777))
            ]),
          ],
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(String label, double value, double total, Color color) {
    return PieChartSectionData(
        color: color,
        value: value,
        title: '${((value / total) * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle:
            GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800));
  }

  Widget _graficoLegenda(String label, int value, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 4),
          Text('$label · $value',
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: color))
        ]));
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatData(
      {required this.label, required this.value, required this.icon, required this.color});
}

Color _colorFromHex(String? hex, {required Color fallback}) {
  if (hex == null || hex.trim().isEmpty) return fallback;
  try {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  } catch (_) {
    return fallback;
  }
}

IconData _iconFromString(String? value) {
  final codePoint = int.tryParse(value ?? '');
  return codePoint == null || codePoint == 0
      ? Icons.restaurant_menu_rounded
      : IconData(codePoint, fontFamily: 'MaterialIcons');
}

String _itensIncluidosLabel(int q) => q == 1 ? '1 item' : '$q itens';
String _tipoItemLabel(dynamic tipo) {
  final t = _normalizeText(_enumValueToText(tipo));
  return t == 'descartavel' ? 'Descartável' : (t.isEmpty ? '-' : t.capitalizeFirst ?? t);
}

IconData _iconByTipo(dynamic tipo) {
  final t = _normalizeText(_enumValueToText(tipo));
  if (t == 'comida') return Icons.restaurant_rounded;
  if (t == 'bebida') return Icons.local_drink_rounded;
  if (t == 'sobremesa') return Icons.cake_rounded;
  if (t == 'bolo') return Icons.cake_outlined;
  if (t == 'descartavel') return Icons.inventory_2_rounded;
  return Icons.room_service_rounded;
}

Color _colorByTipo(dynamic tipo, Color fallback) {
  final t = _normalizeText(_enumValueToText(tipo));
  if (t == 'comida') return fallback;
  if (t == 'bebida') return const Color(0xFF2563EB);
  if (t == 'sobremesa' || t == 'bolo') return const Color(0xFFDB2777);
  if (t == 'descartavel') return const Color(0xFF64748B);
  return const Color(0xFF7C3AED);
}

String _enumValueToText(dynamic value) {
  if (value == null) return '';
  try {
    if (value.firestoreValue != null) return value.firestoreValue.toString();
  } catch (_) {}
  try {
    if (value.name != null) return value.name.toString();
  } catch (_) {}
  return value.toString().split('.').last;
}

String _normalizeText(String v) => v
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[áàãâ]'), 'a')
    .replaceAll(RegExp(r'[éê]'), 'e')
    .replaceAll('í', 'i')
    .replaceAll(RegExp(r'[óôõ]'), 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ç', 'c');
int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  try {
    if (value.value is num) return value.value.toInt();
  } catch (_) {}
  return int.tryParse(value.toString()) ?? 0;
}

int _totalItensConfirmados(CardapioController c) {
  var t = 0;
  for (final m in c.cardapios) {
    t += c.itensDoCardapio(m.idCardapio).where((i) => i.confirmado).length;
  }
  return t;
}

void abrirEditarItemCardapio(BuildContext context, String idCardapio, CardapioItemModel item) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditarItemCardapioBottomSheet(idCardapio: idCardapio, item: item));
}

void abrirCadastroCardapio(BuildContext context, String idEvento) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CadastroCardapioBottomSheet(idEvento: idEvento));
}

void abrirAdicionarItemCardapio(BuildContext context, String idEvento, String idCardapio) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemCardapioBottomSheet(idEvento: idEvento, idCardapio: idCardapio));
}

void abrirEditarCardapio(BuildContext context, CardapioModel cardapio) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditarCardapioBottomSheet(cardapio: cardapio));
}
