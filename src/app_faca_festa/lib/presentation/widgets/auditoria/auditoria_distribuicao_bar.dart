import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auditoria_evento_card.dart';

/// Mantém o nome completo acima da barra, inclusive em painéis estreitos.
class AuditoriaDistribuicaoBar extends StatelessWidget {
  const AuditoriaDistribuicaoBar({
    super.key,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: theme.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$value',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: theme.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 6,
            color: theme.primary,
            backgroundColor: theme.border.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
