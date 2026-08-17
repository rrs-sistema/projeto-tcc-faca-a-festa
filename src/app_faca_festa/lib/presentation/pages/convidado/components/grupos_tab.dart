import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/convidado/grupo_convidado_model.dart';
import './../../../../data/models/model.dart';

class GruposTab extends StatelessWidget {
  const GruposTab({super.key});

  @override
  Widget build(BuildContext context) {
    final grupoController = Get.find<GrupoConvidadoController>();
    final themeController = Get.find<EventThemeController>();

    return Obx(() {
      final primary = themeController.primaryColor.value;
      if (grupoController.carregando.value) {
        return Center(child: CircularProgressIndicator(color: primary));
      }

      final grupos = grupoController.grupos.toList();

      return Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFDF4F8), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80), // Mais compacto
          children: [
            _buildHeader(primary),
            const SizedBox(height: 10),
            _ResumoGrupos(
                totalGrupos: grupoController.totalGrupos,
                gruposComConvidados: grupoController.gruposComConvidados,
                totalConvidados: grupoController.totalConvidados,
                gruposVazios: grupoController.gruposVazios,
                primary: primary),
            const SizedBox(height: 14),
            if (grupos.isEmpty)
              _EmptyGroupsState(primary: primary)
            else ...[
              _SectionTitle(
                  icon: Icons.folder_shared_rounded,
                  title: 'Grupos',
                  subtitle: 'Convidados.',
                  color: primary),
              const SizedBox(height: 8),
              ...grupos.map((grupo) => _GrupoCard(
                  grupo: grupo,
                  color: fromHex(grupo.corHex ?? '#FF7BAC'),
                  icon: _iconFromKey(grupo.icone),
                  convidados:
                      grupoController.convidadosDoGrupo(grupo.idGrupo))),
              const SizedBox(height: 6),
              _GraficoGrupos(
                  grupos: grupos,
                  controller: grupoController,
                  primary: primary),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildHeader(Color primary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.groups_2_rounded, color: primary, size: 20)),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Grupos de convidados',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827))),
                Text('Organize por famílias ou amigos.',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: const Color(0xFF6B7280)))
              ])),
        ],
      ),
    );
  }
}

class _ResumoGrupos extends StatelessWidget {
  final int totalGrupos;
  final int gruposComConvidados;
  final int totalConvidados;
  final int gruposVazios;
  final Color primary;
  const _ResumoGrupos(
      {required this.totalGrupos,
      required this.gruposComConvidados,
      required this.totalConvidados,
      required this.gruposVazios,
      required this.primary});
  @override
  Widget build(BuildContext context) {
    final resumo = [
      _ResumoItem('Grupos', totalGrupos, Icons.folder_shared_rounded, primary),
      _ResumoItem('Com convid.', gruposComConvidados, Icons.people_alt_rounded,
          Colors.green.shade700),
      _ResumoItem('Convidados', totalConvidados, Icons.person_pin_rounded,
          Colors.pink.shade600),
      _ResumoItem('Vazios', gruposVazios, Icons.folder_off_rounded,
          Colors.orange.shade700)
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 24) / 4;
      return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resumo
              .map((item) =>
                  SizedBox(width: width, child: _ResumoCard(item: item)))
              .toList());
    });
  }
}

class _ResumoItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _ResumoItem(this.label, this.value, this.icon, this.color);
}

class _ResumoCard extends StatelessWidget {
  final _ResumoItem item;
  const _ResumoCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withValues(alpha: 0.10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(item.icon, color: item.color, size: 14)),
          const SizedBox(height: 6),
          Text(item.value.toString(),
              style: GoogleFonts.poppins(
                  color: const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          Text(item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280),
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _SectionTitle(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827))),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: const Color(0xFF6B7280)))
        ]))
      ],
    );
  }
}

class _GraficoGrupos extends StatelessWidget {
  final List<GrupoConvidado> grupos;
  final GrupoConvidadoController controller;
  final Color primary;
  const _GraficoGrupos(
      {required this.grupos, required this.controller, required this.primary});

  @override
  Widget build(BuildContext context) {
    final gruposComQuantidade = grupos
        .map((g) => _GrupoQuantidade(
            grupo: g,
            quantidade: controller.convidadosDoGrupo(g.idGrupo).length))
        .where((i) => i.quantidade > 0)
        .toList();
    final total = gruposComQuantidade.fold<int>(
        0, (soma, item) => soma + item.quantidade);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 40),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
              icon: Icons.donut_large_rounded,
              title: 'Distribuição',
              subtitle: 'Concentração.',
              color: primary),
          const SizedBox(height: 12),
          SizedBox(
              height: 180,
              child: PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: gruposComQuantidade.map((item) {
                    final color = Colors.primaries[
                        gruposComQuantidade.indexOf(item) %
                            Colors.primaries.length];
                    return PieChartSectionData(
                        color: color,
                        value: item.quantidade.toDouble(),
                        title:
                            '${((item.quantidade / total) * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800));
                  }).toList()))),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 6,
              children: gruposComQuantidade.map((item) {
                final color = Colors.primaries[
                    gruposComQuantidade.indexOf(item) %
                        Colors.primaries.length];
                return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, color: color, size: 8),
                      const SizedBox(width: 4),
                      Text('${item.grupo.nome} (${item.quantidade})',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151)))
                    ]));
              }).toList()),
        ],
      ),
    );
  }
}

class _GrupoQuantidade {
  final GrupoConvidado grupo;
  final int quantidade;
  const _GrupoQuantidade({required this.grupo, required this.quantidade});
}

class _GrupoCard extends StatelessWidget {
  final GrupoConvidado grupo;
  final IconData icon;
  final Color color;
  final List<Convidado> convidados;
  const _GrupoCard(
      {required this.grupo,
      required this.icon,
      required this.color,
      required this.convidados});
  @override
  Widget build(BuildContext context) {
    final total = convidados.length;
    final confirmados =
        convidados.where((c) => c.status == StatusConvidado.confirmado).length;
    final pendentes =
        convidados.where((c) => c.status == StatusConvidado.pendente).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.10))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 18)),
          title: Text(grupo.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: const Color(0xFF111827))),
          subtitle: Wrap(spacing: 4, runSpacing: 4, children: [
            _SmallStatusChip(
                label: '$total', icon: Icons.people_alt_rounded, color: color),
            if (confirmados > 0)
              _SmallStatusChip(
                  label: '$confirmados conf.',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700),
            if (pendentes > 0)
              _SmallStatusChip(
                  label: '$pendentes pend.',
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange.shade700)
          ]),
          children: convidados.isNotEmpty
              ? convidados.map((c) => _ConvidadoItem(convidado: c)).toList()
              : [_EmptyGroupMessage(color: color)],
        ),
      ),
    );
  }
}

class _ConvidadoItem extends StatelessWidget {
  final Convidado convidado;
  const _ConvidadoItem({required this.convidado});
  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(convidado.status);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04))),
      child: Row(
        children: [
          CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                  convidado.nome.trim().isEmpty
                      ? '?'
                      : convidado.nome.trim()[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11))),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(convidado.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                Text(
                    convidado.email?.trim().isNotEmpty == true
                        ? convidado.email!.trim()
                        : '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: const Color(0xFF6B7280)))
              ])),
          _SmallStatusChip(
              label: _getStatusLabel(convidado.status),
              icon: _getStatusIcon(convidado.status),
              color: color),
        ],
      ),
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SmallStatusChip(
      {required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 9, fontWeight: FontWeight.w700))
        ]));
  }
}

class _EmptyGroupMessage extends StatelessWidget {
  final Color color;
  const _EmptyGroupMessage({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
              child: Text('Vazio.',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: const Color(0xFF4B5563))))
        ]));
  }
}

class _EmptyGroupsState extends StatelessWidget {
  final Color primary;
  const _EmptyGroupsState({required this.primary});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
        child: Column(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle),
              child: Icon(Icons.group_add_rounded, color: primary, size: 26)),
          const SizedBox(height: 10),
          Text('Nenhum grupo',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827)))
        ]));
  }
}

Color fromHex(String hex) {
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  return value.length != 8
      ? const Color(0xFFFF7BAC)
      : Color(int.parse(value, radix: 16));
}

IconData _iconFromKey(String? key) => mapaIcones[key] ?? Icons.group_rounded;
Color _getStatusColor(StatusConvidado status) {
  if (status == StatusConvidado.confirmado) return Colors.green.shade700;
  if (status == StatusConvidado.pendente) return Colors.orange.shade700;
  return Colors.red.shade600;
}

String _getStatusLabel(StatusConvidado status) {
  if (status == StatusConvidado.confirmado) return 'Conf.';
  if (status == StatusConvidado.pendente) return 'Pend.';
  return 'Rec.';
}

IconData _getStatusIcon(StatusConvidado status) {
  if (status == StatusConvidado.confirmado) return Icons.check_circle_rounded;
  if (status == StatusConvidado.pendente) return Icons.pending_actions_rounded;
  return Icons.cancel_rounded;
}

final mapaIcones = {
  'group': Icons.group_rounded,
  'family': Icons.family_restroom_rounded,
  'star': Icons.star_rounded,
  'favorite': Icons.favorite_rounded,
  'chair': Icons.chair_rounded,
  'cake': Icons.cake_rounded,
  'music': Icons.music_note_rounded,
  'work': Icons.work_rounded,
  'pets': Icons.pets_rounded,
  'sports': Icons.sports_soccer_rounded,
  'emoji': Icons.emoji_people_rounded,
  'school': Icons.school_rounded,
  'travel': Icons.flight_takeoff_rounded
};
