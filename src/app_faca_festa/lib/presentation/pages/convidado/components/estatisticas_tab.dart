import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../../controllers/convidado/convidado_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/model.dart';

class EstatisticasTab extends StatefulWidget {
  const EstatisticasTab({super.key});

  @override
  State<EstatisticasTab> createState() => _EstatisticasTabState();
}

class _EstatisticasTabState extends State<EstatisticasTab> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  final ConvidadoController convidadoController = Get.find<ConvidadoController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final EventThemeController? eventTheme =
        Get.isRegistered<EventThemeController>() ? Get.find<EventThemeController>() : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        final primary = eventTheme?.primaryColor.value ?? const Color(0xFF0F766E);

        final total = convidadoController.totalConvidados;
        final confirmados = convidadoController.totalConfirmados;
        final pendentes = convidadoController.totalPendentes;
        final recusados = convidadoController.totalRecusados;

        final totalAdultos = convidadoController.totalAdultos;
        final totalCriancas = convidadoController.totalCriancas;
        final totalBebes = _totalBebesEstimado();

        final percentConfirmados = total > 0 ? confirmados / total : 0.0;
        final percentPendentes = total > 0 ? pendentes / total : 0.0;
        final percentRecusados = total > 0 ? recusados / total : 0.0;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 140),
              children: [
                _StatsHeroCard(
                  primary: primary,
                  total: total,
                  confirmados: confirmados,
                  pendentes: pendentes,
                  recusados: recusados,
                  percentConfirmados: percentConfirmados,
                ),
                const SizedBox(height: 16),
                _StatsOverviewGrid(
                  primary: primary,
                  total: total,
                  confirmados: confirmados,
                  pendentes: pendentes,
                  recusados: recusados,
                ),
                const SizedBox(height: 22),
                if (total == 0) ...[
                  _EmptyStatsCard(primary: primary),
                  const SizedBox(height: 20),
                ] else ...[
                  _ProgressSection(
                    primary: primary,
                    percentConfirmados: percentConfirmados,
                    percentPendentes: percentPendentes,
                    percentRecusados: percentRecusados,
                    confirmados: confirmados,
                    pendentes: pendentes,
                    recusados: recusados,
                    total: total,
                  ),
                  const SizedBox(height: 20),
                  _ChartsSection(
                    primary: primary,
                    totalAdultos: totalAdultos,
                    totalCriancas: totalCriancas,
                    totalBebes: totalBebes,
                    confirmados: confirmados,
                    pendentes: pendentes,
                    recusados: recusados,
                  ),
                  const SizedBox(height: 20),
                  _InsightsCard(
                    primary: primary,
                    total: total,
                    confirmados: confirmados,
                    pendentes: pendentes,
                    recusados: recusados,
                  ),
                ],
                _FooterInfo(primary: primary),
              ],
            ),
          ),
        );
      }),
    );
  }

  int _totalBebesEstimado() {
    return convidadoController.convidados
            .where(
              (convidado) =>
                  convidado.adulto == false && convidado.status == StatusConvidado.confirmado,
            )
            .length ~/
        3;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _StatsHeroCard extends StatelessWidget {
  final Color primary;
  final int total;
  final int confirmados;
  final int pendentes;
  final int recusados;
  final double percentConfirmados;

  const _StatsHeroCard({
    required this.primary,
    required this.total,
    required this.confirmados,
    required this.pendentes,
    required this.recusados,
    required this.percentConfirmados,
  });

  @override
  Widget build(BuildContext context) {
    final progress = percentConfirmados.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.98),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Painel de confirmações',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Cadastre convidados para acompanhar respostas, pendências e recusas.'
                          : '$confirmados de $total convidados confirmaram presença.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              _PercentRing(
                percent: progress,
                label: '${(progress * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.verified_rounded,
                label: '$confirmados confirmados',
              ),
              _HeroChip(
                icon: Icons.schedule_rounded,
                label: '$pendentes pendentes',
              ),
              _HeroChip(
                icon: Icons.cancel_rounded,
                label: '$recusados recusados',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PercentRing extends StatelessWidget {
  final double percent;
  final String label;

  const _PercentRing({
    required this.percent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 6,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsOverviewGrid extends StatelessWidget {
  final Color primary;
  final int total;
  final int confirmados;
  final int pendentes;
  final int recusados;

  const _StatsOverviewGrid({
    required this.primary,
    required this.total,
    required this.confirmados,
    required this.pendentes,
    required this.recusados,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatMetricData(
        icon: Icons.groups_rounded,
        label: 'Convidados',
        value: total.toString(),
        color: primary,
      ),
      _StatMetricData(
        icon: Icons.verified_rounded,
        label: 'Confirmados',
        value: confirmados.toString(),
        color: const Color(0xFF059669),
      ),
      _StatMetricData(
        icon: Icons.schedule_rounded,
        label: 'Pendentes',
        value: pendentes.toString(),
        color: const Color(0xFFF59E0B),
      ),
      _StatMetricData(
        icon: Icons.cancel_rounded,
        label: 'Recusados',
        value: recusados.toString(),
        color: const Color(0xFFDC2626),
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
                  child: _MetricCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _StatMetricData data;

  const _MetricCard({required this.data});

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
                    color: const Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 11.5,
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

class _EmptyStatsCard extends StatelessWidget {
  final Color primary;

  const _EmptyStatsCard({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.insights_rounded, color: primary, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            'Sem dados para analisar ainda',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cadastre convidados e acompanhe automaticamente confirmações, pendências, recusas e perfil do público.',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Color primary;
  final double percentConfirmados;
  final double percentPendentes;
  final double percentRecusados;
  final int confirmados;
  final int pendentes;
  final int recusados;
  final int total;

  const _ProgressSection({
    required this.primary,
    required this.percentConfirmados,
    required this.percentPendentes,
    required this.percentRecusados,
    required this.confirmados,
    required this.pendentes,
    required this.recusados,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.timeline_rounded,
            title: 'Andamento das respostas',
            subtitle: 'Acompanhe o retorno dos convidados em tempo real.',
            color: primary,
          ),
          const SizedBox(height: 16),
          _ProgressLine(
            icon: Icons.verified_rounded,
            title: 'Confirmados',
            value: percentConfirmados,
            color: const Color(0xFF059669),
            subtitle: '$confirmados de $total convidados confirmaram presença',
          ),
          const SizedBox(height: 12),
          _ProgressLine(
            icon: Icons.schedule_rounded,
            title: 'Pendentes',
            value: percentPendentes,
            color: const Color(0xFFF59E0B),
            subtitle: '$pendentes convidados ainda não responderam',
          ),
          const SizedBox(height: 12),
          _ProgressLine(
            icon: Icons.cancel_rounded,
            title: 'Recusados',
            value: percentRecusados,
            color: const Color(0xFFDC2626),
            subtitle: '$recusados convidados recusaram o convite',
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final String subtitle;
  final Color color;

  const _ProgressLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(safeValue * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safeValue,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartsSection extends StatelessWidget {
  final Color primary;
  final int totalAdultos;
  final int totalCriancas;
  final int totalBebes;
  final int confirmados;
  final int pendentes;
  final int recusados;

  const _ChartsSection({
    required this.primary,
    required this.totalAdultos,
    required this.totalCriancas,
    required this.totalBebes,
    required this.confirmados,
    required this.pendentes,
    required this.recusados,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final children = [
          _ChartCard(
            primary: primary,
            icon: Icons.diversity_3_rounded,
            title: 'Perfil dos convidados',
            subtitle: 'Distribuição por faixa etária cadastrada.',
            chart: _AgePieChart(
              primary: primary,
              adultos: totalAdultos,
              criancas: totalCriancas,
              bebes: totalBebes,
            ),
            legend: [
              _LegendItem(label: 'Adultos', value: totalAdultos, color: primary),
              _LegendItem(label: 'Crianças', value: totalCriancas, color: const Color(0xFFF59E0B)),
              _LegendItem(
                  label: 'Bebês estimados', value: totalBebes, color: const Color(0xFF7C3AED)),
            ],
          ),
          _ChartCard(
            primary: primary,
            icon: Icons.mark_email_read_rounded,
            title: 'Status dos convites',
            subtitle: 'Distribuição das respostas recebidas.',
            chart: _StatusPieChart(
              confirmados: confirmados,
              pendentes: pendentes,
              recusados: recusados,
            ),
            legend: [
              const _LegendItem(label: 'Confirmados', value: null, color: Color(0xFF059669)),
              const _LegendItem(label: 'Pendentes', value: null, color: Color(0xFFF59E0B)),
              const _LegendItem(label: 'Recusados', value: null, color: Color(0xFFDC2626)),
            ],
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 14),
              Expanded(child: children[1]),
            ],
          );
        }

        return Column(
          children: [
            children[0],
            const SizedBox(height: 18),
            children[1],
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Color primary;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget chart;
  final List<_LegendItem> legend;

  const _ChartCard({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chart,
    required this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: icon,
            title: title,
            subtitle: subtitle,
            color: primary,
          ),
          const SizedBox(height: 16),
          SizedBox(height: 230, child: chart),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: legend,
          ),
        ],
      ),
    );
  }
}

class _AgePieChart extends StatelessWidget {
  final Color primary;
  final int adultos;
  final int criancas;
  final int bebes;

  const _AgePieChart({
    required this.primary,
    required this.adultos,
    required this.criancas,
    required this.bebes,
  });

  @override
  Widget build(BuildContext context) {
    final total = adultos + criancas + bebes;

    if (total == 0) {
      return _EmptyChart(primary: primary);
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 58,
        startDegreeOffset: -90,
        sections: [
          if (adultos > 0)
            _section(value: adultos.toDouble(), total: total.toDouble(), color: primary),
          if (criancas > 0)
            _section(
                value: criancas.toDouble(),
                total: total.toDouble(),
                color: const Color(0xFFF59E0B)),
          if (bebes > 0)
            _section(
                value: bebes.toDouble(), total: total.toDouble(), color: const Color(0xFF7C3AED)),
        ],
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final int confirmados;
  final int pendentes;
  final int recusados;

  const _StatusPieChart({
    required this.confirmados,
    required this.pendentes,
    required this.recusados,
  });

  @override
  Widget build(BuildContext context) {
    final total = confirmados + pendentes + recusados;

    if (total == 0) {
      return const _EmptyChart(primary: Color(0xFF0F766E));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 58,
        startDegreeOffset: -90,
        sections: [
          if (confirmados > 0)
            _section(
              value: confirmados.toDouble(),
              total: total.toDouble(),
              color: const Color(0xFF059669),
            ),
          if (pendentes > 0)
            _section(
              value: pendentes.toDouble(),
              total: total.toDouble(),
              color: const Color(0xFFF59E0B),
            ),
          if (recusados > 0)
            _section(
              value: recusados.toDouble(),
              total: total.toDouble(),
              color: const Color(0xFFDC2626),
            ),
        ],
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final Color primary;

  const _EmptyChart({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child:
            Icon(Icons.pie_chart_outline_rounded, color: primary.withValues(alpha: 0.55), size: 54),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int? value;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            value == null ? label : '$label · $value',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final Color primary;
  final int total;
  final int confirmados;
  final int pendentes;
  final int recusados;

  const _InsightsCard({
    required this.primary,
    required this.total,
    required this.confirmados,
    required this.pendentes,
    required this.recusados,
  });

  @override
  Widget build(BuildContext context) {
    final confirmacao = total == 0 ? 0.0 : confirmados / total;
    final message = _buildMessage(confirmacao, pendentes, recusados);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(primary),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.tips_and_updates_rounded, color: primary, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leitura rápida',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMessage(double confirmacao, int pendentes, int recusados) {
    if (total == 0) {
      return 'Cadastre convidados para liberar uma análise automática do evento.';
    }

    if (pendentes > confirmados) {
      return 'Ainda existem muitos convites pendentes. Uma boa ação agora é reenviar lembretes para aumentar a taxa de resposta.';
    }

    if (confirmacao >= 0.75) {
      return 'Ótimo andamento! A maior parte dos convidados já confirmou presença. Você já pode usar esses números para ajustar cardápio e orçamento.';
    }

    if (recusados > 0 && pendentes == 0) {
      return 'Todos responderam ao convite. Use o total confirmado para fechar fornecedores, mesas e quantidade de itens.';
    }

    return 'As confirmações estão avançando. Continue acompanhando os pendentes para evitar surpresas perto da data do evento.';
  }
}

class _FooterInfo extends StatelessWidget {
  final Color primary;

  const _FooterInfo({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_rounded, color: primary, size: 15),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Estatísticas atualizadas automaticamente conforme as confirmações.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  fontSize: 15.5,
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

class _StatMetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

PieChartSectionData _section({
  required double value,
  required double total,
  required Color color,
}) {
  final percent = total == 0 ? 0 : (value / total) * 100;

  return PieChartSectionData(
    color: color,
    value: value,
    radius: 68,
    title: '${percent.toStringAsFixed(0)}%',
    titleStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    ),
  );
}

BoxDecoration _cardDecoration(Color color) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: color.withValues(alpha: 0.10)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.045),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
