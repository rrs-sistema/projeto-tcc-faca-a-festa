import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/accessibility/tipografia_festa.dart';

/// Mantém as cinco abas e seus conteúdos na mesma largura de leitura.
class ConvidadosContent extends StatelessWidget {
  static const maxWidth = 1200.0;
  final Widget child;

  const ConvidadosContent({super.key, required this.child});

  static double sideInset(double width) =>
      width > maxWidth ? (width - maxWidth) / 2 : 0;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class ConvidadosTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final Color primary;

  const ConvidadosTabBar({
    super.key,
    required this.controller,
    required this.primary,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    // A TabBar reserva espaço para o indicador mesmo com indicador customizado.
    // Limita a altura real à altura anunciada ao Scaffold/FestaAppBar.
    return SizedBox(
      height: preferredSize.height,
      child: FestaTextoNavegacao(
        child: ConvidadosContent(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: LayoutBuilder(builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 600;
              const labels = ['Lista', 'Grupos', 'Cardápio', 'Mesas', 'Status'];
              const icons = [
                Icons.people_alt_rounded,
                Icons.groups_rounded,
                Icons.restaurant_menu_rounded,
                Icons.table_restaurant_rounded,
                Icons.query_stats_rounded,
              ];
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.55)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: TabBar(
                    controller: controller,
                    isScrollable: false,
                    tabAlignment: TabAlignment.fill,
                    padding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                    indicator: BoxDecoration(
                      color: primary.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: primary.withValues(alpha: 0.16)),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: primary,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: GoogleFonts.poppins(
                        fontSize: 11.5,
                        height: 1.1,
                        fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.poppins(
                        fontSize: 11.2,
                        height: 1.1,
                        fontWeight: FontWeight.w600),
                    onTap: (_) => HapticFeedback.selectionClick(),
                    tabs: List.generate(labels.length, (index) {
                      final label = FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(labels[index], maxLines: 1),
                      );
                      final icon =
                          Icon(icons[index], size: horizontal ? 20 : 17);
                      return Tab(
                        height: 44,
                        child: horizontal
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  icon,
                                  const SizedBox(width: 8),
                                  Flexible(child: label),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  icon,
                                  const SizedBox(height: 2),
                                  Flexible(child: label),
                                ],
                              ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
