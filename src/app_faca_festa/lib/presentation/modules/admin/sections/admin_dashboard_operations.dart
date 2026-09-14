part of '../pages/admin_dashboard_screen.dart';

class _OperationsPanel extends StatelessWidget {
  final AdminDashboardStats stats;
  final bool loading;
  final VoidCallback openAudit;
  final VoidCallback openBudgets;
  final VoidCallback openSuppliers;

  const _OperationsPanel({
    required this.stats,
    required this.loading,
    required this.openAudit,
    required this.openBudgets,
    required this.openSuppliers,
  });

  @override
  Widget build(BuildContext context) {
    final health = _platformHealth(stats);

    return Column(
      children: [
        _PanelShell(
          title: 'Prioridades',
          subtitle: 'Fila de atenção para hoje.',
          child: Column(
            children: [
              _PriorityTile(
                icon: Icons.storefront_rounded,
                title: 'Aprovar fornecedores',
                value: '${stats.fornecedoresPendentes}',
                detail: stats.fornecedoresPendentes > 0
                    ? 'pendentes de revisão'
                    : 'sem pendências',
                color: stats.fornecedoresPendentes > 0
                    ? AdminPalette.warning
                    : AdminPalette.success,
                onTap: openSuppliers,
              ),
              const SizedBox(height: 10),
              _PriorityTile(
                icon: Icons.request_quote_rounded,
                title: 'Acompanhar orçamentos',
                value: '${stats.orcamentosAbertos}',
                detail: 'solicitações em andamento',
                color: const Color(0xFF6D28D9),
                onTap: openBudgets,
              ),
              const SizedBox(height: 10),
              _PriorityTile(
                icon: Icons.policy_rounded,
                title: 'Trilha de auditoria',
                value: 'log',
                detail: 'rastreabilidade da operação',
                color: const Color(0xFF1E3A5F),
                onTap: openAudit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelShell(
          title: 'Saúde da plataforma',
          subtitle: loading ? 'Sincronizando indicadores...' : health.label,
          action: AdminStatusChip(
            label: health.badge,
            color: health.color,
            icon: health.icon,
          ),
          child: Column(
            children: [
              _HealthDial(value: health.value, color: health.color),
              const SizedBox(height: 18),
              _CompactMetricLine(
                label: 'Cobertura',
                value: '${stats.territorios} territórios',
                icon: Icons.map_rounded,
              ),
              const Divider(height: 18),
              _CompactMetricLine(
                label: 'Catálogo',
                value: '${stats.servicos} serviços',
                icon: Icons.inventory_2_rounded,
              ),
              const Divider(height: 18),
              _CompactMetricLine(
                label: 'Temas',
                value: '${stats.temas} experiências',
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  const _PriorityTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AdminPalette.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AdminPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: value.length > 3 ? 13 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthDial extends StatelessWidget {
  final double value;
  final Color color;

  const _HealthDial({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();

    return Center(
      child: SizedBox(
        width: 156,
        height: 156,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(156),
              painter: _DialPainter(value: value, color: color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: GoogleFonts.poppins(
                    color: AdminPalette.ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'estabilidade',
                  style: GoogleFonts.poppins(
                    color: AdminPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetricLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CompactMetricLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AdminPalette.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AdminPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AdminPalette.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

_HealthSignal _platformHealth(AdminDashboardStats stats) {
  var score = 0.64;
  if (stats.fornecedores > 0) score += 0.12;
  if (stats.servicos > 0) score += 0.08;
  if (stats.eventosAtivos > 0) score += 0.06;
  if (stats.territorios > 0) score += 0.05;
  if (stats.fornecedoresPendentes > 0) score -= 0.12;
  if (stats.orcamentosAbertos > 0) score += 0.03;
  score = score.clamp(0.16, 0.98).toDouble();

  if (score >= 0.82) {
    return _HealthSignal(
      value: score,
      label: 'Tudo pronto para escalar a operação.',
      badge: 'Saudável',
      color: AdminPalette.success,
      icon: Icons.check_circle_rounded,
    );
  }
  if (score >= 0.62) {
    return _HealthSignal(
      value: score,
      label: 'Operação estável com pontos de atenção.',
      badge: 'Estável',
      color: AdminPalette.primary,
      icon: Icons.trending_up_rounded,
    );
  }
  return _HealthSignal(
    value: score,
    label: 'Revise cadastros e filas pendentes.',
    badge: 'Atenção',
    color: AdminPalette.warning,
    icon: Icons.warning_amber_rounded,
  );
}

class _HealthSignal {
  final double value;
  final String label;
  final String badge;
  final Color color;
  final IconData icon;

  const _HealthSignal({
    required this.value,
    required this.label,
    required this.badge,
    required this.color,
    required this.icon,
  });
}

class _DialPainter extends CustomPainter {
  final double value;
  final Color color;

  const _DialPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = AdminPalette.border;
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.38),
          color,
        ],
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
