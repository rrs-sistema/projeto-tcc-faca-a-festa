import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estado vazio das telas de festa: o que falta e o que fazer agora.
class FestaEmptyState extends StatelessWidget {
  const FestaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add_rounded,
    this.color,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cor = color ?? Theme.of(context).colorScheme.primary;
    final temAcao = actionLabel != null && onAction != null;

    return Semantics(
      container: true,
      label: '$title. $message',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final alturaFinita = constraints.maxHeight.isFinite;
          final altura = alturaFinita ? constraints.maxHeight : 0.0;
          final apertado = compact || !alturaFinita || altura < 280;
          final extraApertado = alturaFinita && altura < 240;
          final padExterno = extraApertado ? 6.0 : (apertado ? 10.0 : 24.0);
          final padInterno = extraApertado ? 10.0 : (apertado ? 12.0 : 20.0);
          final iconeCaixa = extraApertado ? 32.0 : (apertado ? 44.0 : 56.0);
          final icone = extraApertado ? 16.0 : (apertado ? 20.0 : 26.0);

          final cartao = Padding(
            padding: EdgeInsets.all(padExterno),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  padInterno,
                  padInterno,
                  padInterno,
                  extraApertado ? 10 : (apertado ? 12 : 18),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(extraApertado ? 14 : 20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: extraApertado ? 8 : 14,
                      offset: Offset(0, extraApertado ? 3 : 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: iconeCaixa,
                        height: iconeCaixa,
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: cor, size: icone),
                      ),
                    ),
                    SizedBox(height: extraApertado ? 4 : (apertado ? 8 : 14)),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: extraApertado ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: extraApertado ? 13 : (apertado ? 14 : 16),
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: extraApertado ? 4 : 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      maxLines: extraApertado ? 2 : 5,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: extraApertado ? 11.5 : (apertado ? 12 : 13),
                        height: 1.3,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    if (temAcao) ...[
                      SizedBox(
                          height: extraApertado ? 6 : (apertado ? 10 : 16)),
                      SizedBox(
                        height: extraApertado ? 34 : (apertado ? 38 : 44),
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(actionIcon, size: 18),
                          label: Text(
                            actionLabel!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: extraApertado
                                  ? 12
                                  : (apertado ? 13 : 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );

          if (!alturaFinita) {
            return cartao;
          }

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: altura),
              child: Center(child: cartao),
            ),
          );
        },
      ),
    );
  }
}
