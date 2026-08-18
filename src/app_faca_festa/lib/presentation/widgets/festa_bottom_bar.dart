import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/tema/event_theme_controller.dart';

class FestaNavItem {
  const FestaNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.isAction = false,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;

  /// Item de ação (ex.: Menu): dispara o tap, mas nunca fica selecionado.
  final bool isAction;
}

/// Bottom bar de canto a canto, padronizada com o tema do evento
/// (`primaryColor`, `secondaryColor` e `gradient`).
class FestaBottomBar extends StatelessWidget {
  const FestaBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FestaNavItem> items;

  static const _topRadius = BorderRadius.vertical(top: Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();

    return Obx(() {
      final primary = theme.primaryColor.value;
      final secondary = theme.secondaryColor.value;
      final gradient = theme.gradient.value;

      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _topRadius,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _topRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: primary.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.97),
                    Color.lerp(Colors.white, secondary, 0.55)!,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                maintainBottomViewPadding: true,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.15,
                  child: SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Expanded(
                              child: _FestaNavButton(
                                item: items[i],
                                selected: !items[i].isAction && currentIndex == i,
                                primary: primary,
                                gradient: gradient,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _FestaNavButton extends StatelessWidget {
  const _FestaNavButton({
    required this.item,
    required this.selected,
    required this.primary,
    required this.gradient,
    required this.onTap,
  });

  final FestaNavItem item;
  final bool selected;
  final Color primary;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? (item.activeIcon ?? item.icon) : item.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: primary.withValues(alpha: 0.12),
          highlightColor: primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: selected ? gradient : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.34),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: selected ? 22 : 21,
                  color: selected ? Colors.white : primary.withValues(alpha: 0.78),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    height: 1.05,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF64748B),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
