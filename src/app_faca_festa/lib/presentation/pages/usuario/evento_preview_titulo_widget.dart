import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class EventoPreviewTituloWidget extends StatelessWidget {
  final String tipoEvento;
  final String nomeEvento;
  final Color corPrincipal;

  const EventoPreviewTituloWidget({
    super.key,
    required this.tipoEvento,
    required this.nomeEvento,
    required this.corPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = tipoEvento.toLowerCase().trim();
    final nome = nomeEvento.trim();

    String titulo;
    TextStyle estilo;

    switch (tipo) {
      case 'casamento':
        titulo = nome.isEmpty ? '💍 Um dia para celebrar o amor...' : '💍 $nome';
        estilo = GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: Colors.black,
          shadows: [
            Shadow(
              offset: const Offset(0, 2),
              blurRadius: 5,
              color: corPrincipal,
            ),
          ],
        );
        break;
      case 'evento corporativo':
        titulo = nome.isEmpty ? '💼 Um dia para celebrar o amor...' : '💼 $nome';
        estilo = GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: Colors.black,
          shadows: [
            Shadow(
              offset: const Offset(0, 2),
              blurRadius: 5,
              color: corPrincipal,
            ),
          ],
        );
        break;

      case 'festa infantil':
        titulo = nome.isEmpty ? '🎈 Diversão garantida para os pequenos!' : '🎈 $nome';
        estilo = GoogleFonts.fredoka(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          shadows: [
            Shadow(
              offset: const Offset(1, 2),
              blurRadius: 4,
              color: corPrincipal.withValues(alpha: 0.3),
            ),
          ],
        );
        break;

      case 'chá de bebê':
        titulo = nome.isEmpty ? '🍼 Esperando com amor...' : '🍼 $nome';
        estilo = GoogleFonts.dancingScript(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          shadows: [
            Shadow(
              offset: const Offset(1, 2),
              blurRadius: 3,
              color: corPrincipal.withValues(alpha: 0.3),
            ),
          ],
        );
        break;

      case 'aniversário':
        titulo = nome.isEmpty ? '🎂 Que venham mais momentos incríveis!' : '🎂 $nome';
        estilo = GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 0.6,
          shadows: [
            Shadow(
              color: corPrincipal.withValues(alpha: 0.25),
              blurRadius: 6,
            ),
          ],
        );
        break;

      default:
        titulo = nome.isEmpty ? '🎉 Sua celebração começa aqui!' : '🎉 $nome';
        estilo = GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [corPrincipal.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: corPrincipal.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: corPrincipal.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          titulo,
          textAlign: TextAlign.center,
          style: estilo,
        ),
      )
          // ✨ Animação suave
          .animate()
          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
          .slideY(begin: 0.4, end: 0, duration: 700.ms, curve: Curves.easeOutBack)
          .scaleXY(begin: 0.95, end: 1.0, duration: 500.ms),
    );
  }
}
