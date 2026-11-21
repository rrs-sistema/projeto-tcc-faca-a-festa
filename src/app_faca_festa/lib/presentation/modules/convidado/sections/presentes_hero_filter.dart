part of '../pages/area/presentes_section.dart';

class _GiftHeroCard extends StatelessWidget {
  final Color primary;
  final int total;
  final int disponiveis;

  const _GiftHeroCard({
    required this.primary,
    required this.total,
    required this.disponiveis,
  });

  @override
  Widget build(BuildContext context) {
    final resumo = total == 0
        ? 'Nenhum item ainda'
        : '$total ${total == 1 ? 'opção' : 'opções'} · '
            '$disponiveis ${disponiveis == 1 ? 'disponível' : 'disponíveis'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.redeem_rounded, color: primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lista de presentes',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resumo,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
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

class _FilterBar extends StatelessWidget {
  final Color primary;
  final _GiftFilter selected;
  final ValueChanged<_GiftFilter> onChanged;
  final List<_FilterOption> options;

  const _FilterBar({
    required this.primary,
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    if (options.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final active = selected == option.filter;
          return InkWell(
            onTap: () => onChanged(option.filter),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? primary
                      : primary.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                option.label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterOption {
  final _GiftFilter filter;
  final String label;

  const _FilterOption(this.filter, this.label);
}

enum _GiftFilter { todos, disponiveis, loja, pix, coletivo }
