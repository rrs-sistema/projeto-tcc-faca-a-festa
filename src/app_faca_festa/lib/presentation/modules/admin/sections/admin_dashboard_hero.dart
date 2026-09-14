part of '../pages/admin_dashboard_screen.dart';

class _ExecutiveHero extends StatelessWidget {
  final AdminDashboardStats stats;
  final bool loading;
  final DateTime? updatedAt;
  final Future<void> Function() onRefresh;

  const _ExecutiveHero({
    required this.stats,
    required this.loading,
    required this.updatedAt,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final fornecedoresOk = stats.fornecedoresPendentes == 0;
    final updatedText = updatedAt == null
        ? 'Aguardando primeira sincronização'
        : 'Atualizado às ${DateFormat('HH:mm').format(updatedAt!)}';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D3A), Color(0xFF0F766E), Color(0xFF12A594)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AdminPalette.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HeroPatternPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: Icons.verified_rounded,
                          label: 'Operação administrativa',
                        ),
                        _HeroChip(
                          icon: fornecedoresOk
                              ? Icons.check_circle_rounded
                              : Icons.pending_actions_rounded,
                          label: fornecedoresOk
                              ? 'Fornecedores em dia'
                              : '${stats.fornecedoresPendentes} aprovações pendentes',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Central de comando da plataforma',
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 24 : 32,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Text(
                        'Administre catálogo, fornecedores, eventos, orçamento, usuários e auditoria com uma visão única da saúde do aplicativo.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: loading ? null : onRefresh,
                          icon: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 18),
                          label: const Text('Sincronizar agora'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AdminPalette.dark,
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.38),
                            disabledForegroundColor:
                                Colors.white.withValues(alpha: 0.82),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        _UpdatedPill(label: updatedText),
                      ],
                    ),
                  ],
                );
                final pulse = _HeroPulse(stats: stats);

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      intro,
                      const SizedBox(height: 22),
                      pulse,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 6, child: intro),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: pulse),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPulse extends StatelessWidget {
  final AdminDashboardStats stats;

  const _HeroPulse({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalCore = stats.eventosAtivos +
        stats.fornecedoresAptos +
        stats.usuariosAtivos +
        stats.orcamentosAbertos;
    final supplierRatio = _ratio(stats.fornecedoresAptos, stats.fornecedores);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.monitor_heart_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pulso operacional',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$totalCore sinais ativos no painel',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _HeroMeter(
            label: 'Fornecedores aptos',
            value: supplierRatio,
            detail: '${stats.fornecedoresAptos}/${stats.fornecedores}',
          ),
          const SizedBox(height: 12),
          _HeroMeter(
            label: 'Eventos em execução',
            value: _ratio(stats.eventosAtivos, stats.eventos),
            detail: '${stats.eventosAtivos}/${stats.eventos}',
          ),
          const SizedBox(height: 12),
          _HeroMeter(
            label: 'Orçamentos em aberto',
            value: _ratio(stats.orcamentosAbertos, stats.orcamentos),
            detail: '${stats.orcamentosAbertos}/${stats.orcamentos}',
          ),
        ],
      ),
    );
  }
}

class _HeroMeter extends StatelessWidget {
  final String label;
  final double value;
  final String detail;

  const _HeroMeter({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              detail,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: value,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatedPill extends StatelessWidget {
  final String label;

  const _UpdatedPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);

    for (var i = 0; i < 8; i++) {
      final radius = 68.0 + (i * 42);
      canvas.drawCircle(
          Offset(size.width * 0.88, size.height * 0.12), radius, paint);
    }

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (var x = 26.0; x < size.width; x += 46) {
      for (var y = 24.0; y < size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
