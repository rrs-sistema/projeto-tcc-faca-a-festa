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
        return Center(
          child: CircularProgressIndicator(color: primary),
        );
      }

      final grupos = grupoController.grupos.toList();

      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF4F8), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          children: [
            _buildHeader(primary),
            const SizedBox(height: 14),
            _ResumoGrupos(
              totalGrupos: grupoController.totalGrupos,
              gruposComConvidados: grupoController.gruposComConvidados,
              totalConvidados: grupoController.totalConvidados,
              gruposVazios: grupoController.gruposVazios,
              primary: primary,
            ),
            const SizedBox(height: 18),
            if (grupos.isEmpty)
              _EmptyGroupsState(primary: primary)
            else ...[
              _SectionTitle(
                icon: Icons.folder_shared_rounded,
                title: 'Grupos organizados',
                subtitle: 'Toque em um grupo para visualizar os convidados.',
                color: primary,
              ),
              const SizedBox(height: 12),
              ...grupos.map((grupo) {
                final convidados = grupoController.convidadosDoGrupo(grupo.idGrupo);

                return _GrupoCard(
                  grupo: grupo,
                  color: fromHex(grupo.corHex ?? '#FF7BAC'),
                  icon: _iconFromKey(grupo.icone),
                  convidados: convidados,
                );
              }),
              const SizedBox(height: 8),
              _GraficoGrupos(
                grupos: grupos,
                controller: grupoController,
                primary: primary,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildHeader(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.groups_2_rounded, color: primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grupos de convidados',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Organize famílias, amigos e convidados especiais para facilitar convites e confirmações.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.35,
                    color: const Color(0xFF6B7280),
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

class _ResumoGrupos extends StatelessWidget {
  final int totalGrupos;
  final int gruposComConvidados;
  final int totalConvidados;
  final int gruposVazios;
  final Color primary;

  const _ResumoGrupos({
    required this.totalGrupos,
    required this.gruposComConvidados,
    required this.totalConvidados,
    required this.gruposVazios,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final resumo = [
      _ResumoItem('Grupos', totalGrupos, Icons.folder_shared_rounded, primary),
      _ResumoItem(
          'Com convidados', gruposComConvidados, Icons.people_alt_rounded, Colors.green.shade700),
      _ResumoItem('Convidados', totalConvidados, Icons.person_pin_rounded, Colors.pink.shade600),
      _ResumoItem('Vazios', gruposVazios, Icons.folder_off_rounded, Colors.orange.shade700),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;
        final spacing = isCompact ? 10.0 : 12.0;
        final columns = isCompact ? 2 : 4;
        final width = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: resumo.map((item) {
            return SizedBox(
              width: width,
              child: _ResumoCard(item: item),
            );
          }).toList(),
        );
      },
    );
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.color.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            item.value.toString(),
            style: GoogleFonts.poppins(
              color: const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 11.6,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.8,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GraficoGrupos extends StatelessWidget {
  final List<GrupoConvidadoModel> grupos;
  final GrupoConvidadoController controller;
  final Color primary;

  const _GraficoGrupos({
    required this.grupos,
    required this.controller,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final gruposComQuantidade = grupos
        .map((g) {
          final quantidade = controller.convidadosDoGrupo(g.idGrupo).length;
          return _GrupoQuantidade(grupo: g, quantidade: quantidade);
        })
        .where((item) => item.quantidade > 0)
        .toList();

    final total = gruposComQuantidade.fold<int>(0, (soma, item) => soma + item.quantidade);

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.donut_large_rounded,
            title: 'Distribuição por grupo',
            subtitle: 'Veja onde seus convidados estão concentrados.',
            color: primary,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: gruposComQuantidade.map((item) {
                  final index = gruposComQuantidade.indexOf(item);
                  final color = Colors.primaries[index % Colors.primaries.length];
                  final percent = item.quantidade / total;

                  return PieChartSectionData(
                    color: color,
                    value: item.quantidade.toDouble(),
                    title: '${(percent * 100).toStringAsFixed(0)}%',
                    radius: 66,
                    titleStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: gruposComQuantidade.map((item) {
              final index = gruposComQuantidade.indexOf(item);
              final color = Colors.primaries[index % Colors.primaries.length];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: color, size: 10),
                    const SizedBox(width: 6),
                    Text(
                      '${item.grupo.nome} (${item.quantidade})',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GrupoQuantidade {
  final GrupoConvidadoModel grupo;
  final int quantidade;

  const _GrupoQuantidade({
    required this.grupo,
    required this.quantidade,
  });
}

class _GrupoCard extends StatelessWidget {
  final GrupoConvidadoModel grupo;
  final IconData icon;
  final Color color;
  final List<ConvidadoModel> convidados;

  const _GrupoCard({
    required this.grupo,
    required this.icon,
    required this.color,
    required this.convidados,
  });

  @override
  Widget build(BuildContext context) {
    final total = convidados.length;
    final confirmados = convidados.where((c) => c.status == StatusConvidado.confirmado).length;
    final pendentes = convidados.where((c) => c.status == StatusConvidado.pendente).length;
    final temConvidados = convidados.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            grupo.nome,
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
              spacing: 7,
              runSpacing: 7,
              children: [
                _SmallStatusChip(
                    label: '$total convidados', icon: Icons.people_alt_rounded, color: color),
                if (confirmados > 0)
                  _SmallStatusChip(
                      label: '$confirmados confirmados',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green.shade700),
                if (pendentes > 0)
                  _SmallStatusChip(
                      label: '$pendentes pendentes',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.orange.shade700),
              ],
            ),
          ),
          children: temConvidados
              ? convidados.map((c) => _ConvidadoItem(convidado: c)).toList()
              : [
                  _EmptyGroupMessage(color: color),
                ],
        ),
      ),
    );
  }
}

class _ConvidadoItem extends StatelessWidget {
  final ConvidadoModel convidado;

  const _ConvidadoItem({required this.convidado});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(convidado.status);
    final statusLabel = _getStatusLabel(convidado.status);
    final initial = convidado.nome.trim().isEmpty ? '?' : convidado.nome.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convidado.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  convidado.email?.trim().isNotEmpty == true
                      ? convidado.email!.trim()
                      : 'Sem e-mail informado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.8,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SmallStatusChip(
            label: statusLabel,
            icon: _getStatusIcon(convidado.status),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SmallStatusChip({
    required this.label,
    required this.icon,
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
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupMessage extends StatelessWidget {
  final Color color;

  const _EmptyGroupMessage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Este grupo ainda não possui convidados. Adicione pessoas para organizar melhor o envio dos convites.',
              style: GoogleFonts.poppins(
                fontSize: 12.2,
                height: 1.35,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupsState extends StatelessWidget {
  final Color primary;

  const _EmptyGroupsState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add_rounded, color: primary, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum grupo criado ainda',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie grupos como “Família”, “Amigos” ou “Trabalho” para organizar melhor a lista de convidados.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.8,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

Color fromHex(String hex) {
  var value = hex.replaceAll('#', '').trim();

  if (value.length == 6) {
    value = 'FF$value';
  }

  if (value.length != 8) {
    return const Color(0xFFFF7BAC);
  }

  return Color(int.parse(value, radix: 16));
}

IconData _iconFromKey(String? key) {
  return mapaIcones[key] ?? Icons.group_rounded;
}

Color _getStatusColor(StatusConvidado status) {
  switch (status) {
    case StatusConvidado.confirmado:
      return Colors.green.shade700;
    case StatusConvidado.pendente:
      return Colors.orange.shade700;
    case StatusConvidado.recusado:
      return Colors.red.shade600;
  }
}

String _getStatusLabel(StatusConvidado status) {
  switch (status) {
    case StatusConvidado.confirmado:
      return 'Confirmado';
    case StatusConvidado.pendente:
      return 'Pendente';
    case StatusConvidado.recusado:
      return 'Recusou';
  }
}

IconData _getStatusIcon(StatusConvidado status) {
  switch (status) {
    case StatusConvidado.confirmado:
      return Icons.check_circle_rounded;
    case StatusConvidado.pendente:
      return Icons.pending_actions_rounded;
    case StatusConvidado.recusado:
      return Icons.cancel_rounded;
  }
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
  'travel': Icons.flight_takeoff_rounded,
};
