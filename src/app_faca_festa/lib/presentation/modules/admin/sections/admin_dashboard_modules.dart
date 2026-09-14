part of '../pages/admin_dashboard_screen.dart';

class _ModulesPanel extends StatelessWidget {
  final List<_AdminItem> items;

  const _ModulesPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: 'Módulos administrativos',
      subtitle: 'Acesse rapidamente as áreas de gestão da plataforma.',
      action: AdminStatusChip.success('Online', icon: Icons.circle),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width < 560
              ? 1
              : width < 900
                  ? 2
                  : 3;
          final aspectRatio = width < 560
              ? 2.8
              : width < 900
                  ? 2.25
                  : 2.05;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, i) => _AdminCard(item: items[i])
                .animate(delay: (i * 35).ms)
                .fadeIn(duration: 340.ms)
                .slideY(begin: 0.06),
          );
        },
      ),
    );
  }
}

class _AdminCard extends StatefulWidget {
  final _AdminItem item;

  const _AdminCard({required this.item});

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: 180.ms,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: hovered
                  ? widget.item.color.withValues(alpha: 0.045)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hovered
                    ? widget.item.color.withValues(alpha: 0.28)
                    : AdminPalette.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.item.icon,
                        size: 21,
                        color: widget.item.color,
                      ),
                    ),
                    const Spacer(),
                    if (widget.item.badge != null && widget.item.badge! > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AdminPalette.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AdminPalette.warning.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          '${widget.item.badge}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AdminPalette.warning,
                          ),
                        ),
                      ),
                    if (widget.item.showCount)
                      Text(
                        '${widget.item.count}',
                        style: GoogleFonts.poppins(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: AdminPalette.ink,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.item.signal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: widget.item.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AdminPalette.muted,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: widget.item.progress,
                    backgroundColor: widget.item.color.withValues(alpha: 0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.item.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
