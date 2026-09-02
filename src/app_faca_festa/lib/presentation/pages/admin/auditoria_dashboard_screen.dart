import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/bootstrap/auditoria_bootstrap.dart';
import '../../modules/auditoria/controllers/auditoria_controller.dart';
import '../../modules/tema/admin_theme.dart';
import '../../modules/tema/controllers/event_theme_controller.dart';
import '../../widgets/admin/admin_kit.dart';
import '../../widgets/auditoria/auditoria_evento_card.dart';

class AuditoriaDashboardScreen extends StatelessWidget {
  AuditoriaDashboardScreen({super.key}) {
    Future.microtask(() {
      AuditoriaBootstrap.controllerAdmin().carregar();
    });
  }

  static const _theme = AuditoriaVisualTheme(
    surface: AdminPalette.surface,
    card: AdminPalette.card,
    ink: AdminPalette.ink,
    muted: AdminPalette.muted,
    border: AdminPalette.border,
    primary: AdminPalette.primary,
    danger: AdminPalette.danger,
    warning: AdminPalette.warning,
    success: AdminPalette.success,
  );

  @override
  Widget build(BuildContext context) {
    final controller = AuditoriaBootstrap.controllerAdmin();
    final themeController = Get.find<EventThemeController>();

    return Theme(
      data: themeController.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Dashboard de auditoria',
          subtitle: 'Saúde, risco e volume dos registros críticos',
          actions: [
            IconButton(
              tooltip: 'Histórico',
              icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
              onPressed: () => Get.offNamed('/admin/auditoria'),
            ),
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: controller.carregar,
            ),
          ],
        ),
        body: Obx(() {
          if (controller.carregando.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.erro.isNotEmpty) {
            return AdminEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Não foi possível carregar o dashboard',
              message: controller.erro.value,
              actionLabel: 'Tentar de novo',
              onAction: controller.carregar,
            );
          }

          return RefreshIndicator(
            color: _theme.primary,
            onRefresh: controller.carregar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _HeaderBand(controller: controller, theme: _theme),
                const SizedBox(height: 10),
                _MetricGrid(
                  items: [
                    _MetricData(
                      'Total',
                      '${controller.totalEventos}',
                      Icons.fact_check_rounded,
                      _theme.primary,
                    ),
                    _MetricData(
                      'Auditados',
                      '${controller.totalAuditados}',
                      Icons.visibility_rounded,
                      _theme.success,
                    ),
                    _MetricData(
                      'Registros',
                      '${controller.totalSnapshots}',
                      Icons.inventory_2_rounded,
                      _theme.muted,
                    ),
                    _MetricData(
                      'Hoje',
                      '${controller.totalHoje}',
                      Icons.today_rounded,
                      _theme.warning,
                    ),
                    _MetricData(
                      'Últimos 7 dias',
                      '${controller.totalUltimos7d}',
                      Icons.date_range_rounded,
                      _theme.primary,
                    ),
                    _MetricData(
                      'Últimos 15 dias',
                      '${controller.totalUltimos15d}',
                      Icons.calendar_month_rounded,
                      _theme.primary,
                    ),
                    _MetricData(
                      'Últimos 30 dias',
                      '${controller.totalUltimos30d}',
                      Icons.calendar_view_month_rounded,
                      _theme.muted,
                    ),
                    _MetricData(
                      'Sem hash',
                      '${controller.totalAuditadosSemHash}',
                      Icons.fingerprint_rounded,
                      controller.totalAuditadosSemHash == 0
                          ? _theme.success
                          : _theme.warning,
                    ),
                  ],
                  theme: _theme,
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compacto = constraints.maxWidth < 920;
                    if (compacto) {
                      return Column(
                        children: [
                          _ActivityPanel(controller: controller, theme: _theme),
                          const SizedBox(height: 10),
                          _HealthPanel(controller: controller, theme: _theme),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _ActivityPanel(
                            controller: controller,
                            theme: _theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: _HealthPanel(
                            controller: controller,
                            theme: _theme,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compacto = constraints.maxWidth < 920;
                    final children = [
                      _BarsPanel(
                        title: 'Distribuição por área',
                        items: controller.distribuicaoPorArea,
                        theme: _theme,
                      ),
                      _BarsPanel(
                        title: 'Principais ações',
                        items: controller.principaisAcoes,
                        theme: _theme,
                      ),
                      _BarsPanel(
                        title: 'Principais atores',
                        items: controller.principaisAtores,
                        theme: _theme,
                      ),
                    ];
                    if (compacto) {
                      return Column(
                        children: [
                          for (final child in children) ...[
                            child,
                            if (child != children.last)
                              const SizedBox(height: 10),
                          ],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final child in children) ...[
                          Expanded(child: child),
                          if (child != children.last) const SizedBox(width: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HeaderBand extends StatelessWidget {
  const _HeaderBand({required this.controller, required this.theme});

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final cobertura = (controller.coberturaAuditoria * 100).round();
    final saudavel =
        controller.totalCriticos == 0 && controller.totalAuditadosSemHash == 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AdminPalette.appBarGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            saudavel
                ? Icons.verified_user_rounded
                : Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saudavel ? 'Auditoria saudável' : 'Auditoria com atenção',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$cobertura% de cobertura auditada, ${controller.totalCriticos} críticos e ${controller.totalAuditadosSemHash} eventos sem hash.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Get.toNamed('/admin/auditoria'),
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            label: Text(
              'Investigar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items, required this.theme});

  final List<_MetricData> items;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 720
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 28) / 4;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _MetricCard(data: item, theme: theme),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data, required this.theme});

  final _MetricData data;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: data.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: data.color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: theme.ink,
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      GoogleFonts.poppins(fontSize: 10.5, color: theme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, required this.theme});

  final String title;
  final Widget child;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.ink,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.controller, required this.theme});

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final dias = controller.atividadeUltimos15Dias;
    final maior =
        dias.fold<int>(1, (acc, item) => item.value > acc ? item.value : acc);
    return _Panel(
      title: 'Atividade nos últimos 15 dias',
      theme: theme,
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final dia in dias) ...[
              Expanded(
                child: _VerticalBar(
                  label: dia.key,
                  value: dia.value,
                  percent: dia.value / maior,
                  theme: theme,
                ),
              ),
              if (dia != dias.last) const SizedBox(width: 5),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.theme,
  });

  final String label;
  final int value;
  final double percent;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final height = 12.0 + (88.0 * percent.clamp(0.0, 1.0));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: theme.muted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 14,
          height: height,
          decoration: BoxDecoration(
            color: value == 0
                ? theme.border.withValues(alpha: 0.72)
                : theme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 9, color: theme.muted),
        ),
      ],
    );
  }
}

class _HealthPanel extends StatelessWidget {
  const _HealthPanel({required this.controller, required this.theme});

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Saúde operacional',
      theme: theme,
      child: Column(
        children: [
          _HealthLine(
            label: 'Críticos',
            value: controller.totalCriticos,
            color: theme.danger,
            theme: theme,
          ),
          _HealthLine(
            label: 'Alertas',
            value: controller.totalAlertas,
            color: theme.warning,
            theme: theme,
          ),
          _HealthLine(
            label: 'Falhas de acesso',
            value: controller.totalFalhasAcesso,
            color: theme.warning,
            theme: theme,
          ),
          _HealthLine(
            label: 'Ações administrativas',
            value: controller.totalAlteracoesAdministrativas,
            color: theme.primary,
            theme: theme,
          ),
          _HealthLine(
            label: 'Fornecedores em atenção',
            value: controller.totalFornecedoresComAtencao,
            color: theme.danger,
            theme: theme,
          ),
          _HealthLine(
            label: 'Eventos com diff',
            value: controller.totalEventosComDiff,
            color: theme.success,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _HealthLine extends StatelessWidget {
  const _HealthLine({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  final String label;
  final int value;
  final Color color;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.ink,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.16)),
            ),
            child: Text(
              '$value',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarsPanel extends StatelessWidget {
  const _BarsPanel({
    required this.title,
    required this.items,
    required this.theme,
  });

  final String title;
  final List<MapEntry<String, int>> items;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final maior =
        items.fold<int>(1, (acc, item) => item.value > acc ? item.value : acc);
    return _Panel(
      title: title,
      theme: theme,
      child: items.isEmpty
          ? Text(
              'Sem dados disponíveis',
              style: GoogleFonts.poppins(fontSize: 12, color: theme.muted),
            )
          : Column(
              children: [
                for (final item in items.take(7)) ...[
                  _HorizontalBar(
                    label: item.key,
                    value: item.value,
                    percent: item.value / maior,
                    theme: theme,
                  ),
                  if (item != items.take(7).last) const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  const _HorizontalBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.theme,
  });

  final String label;
  final int value;
  final double percent;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = switch (constraints.maxWidth) {
          >= 560 => 190.0,
          >= 460 => 164.0,
          >= 360 => 142.0,
          _ => 118.0,
        };

        return Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Tooltip(
                message: label,
                waitDuration: const Duration(milliseconds: 450),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percent.clamp(0, 1),
                  minHeight: 7,
                  color: theme.primary,
                  backgroundColor: theme.border.withValues(alpha: 0.55),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 34,
              child: Text(
                '$value',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: theme.muted,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
