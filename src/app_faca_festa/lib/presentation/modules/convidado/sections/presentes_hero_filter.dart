part of '../pages/area/presentes_section.dart';

class _GiftHeroCard extends StatelessWidget {
  final Color primary;
  final int total;
  final int disponiveis;
  final int escolhidos;
  final int pixCount;
  final int coletivoCount;

  const _GiftHeroCard({
    required this.primary,
    required this.total,
    required this.disponiveis,
    required this.escolhidos,
    required this.pixCount,
    required this.coletivoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, Colors.purple, 0.38) ?? primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -34,
            child: _GlowCircle(
                size: 120, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Positioned(
            left: -26,
            bottom: -36,
            child: _GlowCircle(
                size: 112, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28)),
                      ),
                      child: const Icon(Icons.redeem_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lista de presentes',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Escolha um carinho especial',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Sua participação ajuda a tornar esse momento ainda mais inesquecível. Escolha um presente, compre na loja ou contribua por PIX.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Disponíveis',
                        value: '$disponiveis',
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Escolhidos',
                        value: '$escolhidos',
                        icon: Icons.favorite_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroMetric(
                        label: 'PIX/Cotas',
                        value: '${pixCount + coletivoCount}',
                        icon: Icons.pix_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final Color primary;
  final _GiftFilter selected;
  final ValueChanged<_GiftFilter> onChanged;

  const _FilterBar({
    required this.primary,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterOption(_GiftFilter.todos, 'Todos', Icons.auto_awesome_rounded),
      _FilterOption(
          _GiftFilter.disponiveis, 'Disponíveis', Icons.check_circle_rounded),
      _FilterOption(_GiftFilter.loja, 'Loja', Icons.storefront_rounded),
      _FilterOption(_GiftFilter.pix, 'PIX', Icons.pix_rounded),
      _FilterOption(_GiftFilter.coletivo, 'Cotas', Icons.groups_rounded),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = filters[index];
          final active = selected == option.filter;
          return InkWell(
            onTap: () => onChanged(option.filter),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? primary : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      active ? primary : Colors.white.withValues(alpha: 0.95),
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(option.icon,
                      size: 15, color: active ? Colors.white : primary),
                  const SizedBox(width: 6),
                  Text(
                    option.label,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 9.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FilterOption {
  final _GiftFilter filter;
  final String label;
  final IconData icon;

  const _FilterOption(this.filter, this.label, this.icon);
}

enum _GiftFilter { todos, disponiveis, loja, pix, coletivo }
