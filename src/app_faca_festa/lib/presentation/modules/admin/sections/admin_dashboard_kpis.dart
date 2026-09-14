part of '../pages/admin_dashboard_screen.dart';

class _KpiStrip extends StatelessWidget {
  final AdminDashboardStats stats;
  final bool loading;

  const _KpiStrip({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCardData('Eventos ativos', Icons.event_note_rounded,
          stats.eventosAtivos, const Color(0xFF7C3AED), '+ operação'),
      _StatCardData('Fornecedores', Icons.store_mall_directory_rounded,
          stats.fornecedores, const Color(0xFF15803D), 'rede'),
      _StatCardData('Usuários', Icons.people_alt_rounded, stats.usuarios,
          const Color(0xFFC2410C), 'contas'),
      _StatCardData('Orçamentos abertos', Icons.request_quote_rounded,
          stats.orcamentosAbertos, const Color(0xFF6D28D9), 'fila'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _StatCard(stat: items[i], loading: loading),
            ),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _StatCard(stat: items[i], loading: loading)),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatCardData stat;
  final bool loading;

  const _StatCard({required this.stat, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104, minWidth: 178),
      decoration: adminCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: stat.value),
                    duration: 700.ms,
                    builder: (context, val, _) => Text(
                      '$val',
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.ink,
                      ),
                    ),
                  ),
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  stat.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: stat.color,
                    fontWeight: FontWeight.w700,
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

class _StatCardData {
  final String title;
  final IconData icon;
  final int value;
  final Color color;
  final String caption;

  _StatCardData(this.title, this.icon, this.value, this.color, this.caption);
}
