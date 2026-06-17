import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FornecedorPremiumPalette {
  static const background = Color(0xFFF6F7FB);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF64748B);
  static const softMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE5E7EB);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const primary = Color(0xFF4F46E5);
  static const indigo = Color(0xFF6366F1);
  static const sky = Color(0xFF0EA5E9);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFEF4444);
  static const purple = Color(0xFF7C3AED);
  static const dark = Color(0xFF111827);
}

class FornecedorBreakpoints {
  static bool phone(double width) => width < 520;
  static bool tablet(double width) => width >= 720;
  static bool desktop(double width) => width >= 1040;

  static int columns(
    double width, {
    int maxColumns = 4,
    int minColumns = 1,
    double minTileWidth = 210,
  }) {
    final raw = (width / minTileWidth).floor();
    return raw.clamp(minColumns, maxColumns);
  }

  static double padding(double width) {
    if (width >= 1100) return 22;
    if (width >= 720) return 18;
    return 14;
  }
}

class PremiumSectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const PremiumSectionShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FornecedorPremiumPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final header = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: FornecedorPremiumPalette.text,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.7,
                            color: FornecedorPremiumPalette.muted,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (trailing == null) return header;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    header,
                    const SizedBox(height: 10),
                    trailing!,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 12),
                  Flexible(child: Align(alignment: Alignment.centerRight, child: trailing!)),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class PremiumPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;

  const PremiumPill({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const PremiumMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: FornecedorPremiumPalette.text,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.2,
                    color: FornecedorPremiumPalette.muted,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: FornecedorPremiumPalette.softMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = FornecedorPremiumPalette.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: FornecedorPremiumPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.7,
                    color: FornecedorPremiumPalette.muted,
                    height: 1.4,
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

class ResponsiveWrapGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;
  final double minTileWidth;
  final double spacing;
  final int minColumns;

  const ResponsiveWrapGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.minColumns = 1,
    this.minTileWidth = 220,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = FornecedorBreakpoints.columns(
          constraints.maxWidth,
          maxColumns: maxColumns,
          minColumns: minColumns,
          minTileWidth: minTileWidth,
        );
        final tileWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: tileWidth.isFinite ? tileWidth : constraints.maxWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
