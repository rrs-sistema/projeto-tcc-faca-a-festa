import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';

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
    final controller = Get.find<EventoCadastroController>();
    final tipo = tipoEvento.toLowerCase().trim();
    final nome = nomeEvento.trim();

    String titulo;
    TextStyle estilo;

    switch (tipo) {
      case 'casamento':
        titulo = nome.isEmpty
            ? '💍 Casamento Um dia para celebrar o amor...'
            : controller.nomeEventoPreview.value;
        estilo = GoogleFonts.playfairDisplay(
          fontSize: 16,
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
      case 'corporativo':
        titulo = nome.isEmpty
            ? '💼 Evento corporativo - Conectando ideias e pessoas'
            : controller.nomeEventoPreview.value;
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
      case 'formatura':
      case 'evento formatura':
        titulo = nome.isEmpty
            ? '🎓 Formatura - Celebre sua conquista!'
            : controller.nomeEventoPreview.value;
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

      case 'festa infantil':
        titulo = nome.isEmpty
            ? '🎈Festa infantil - Diversão garantida para os pequenos!'
            : controller.nomeEventoPreview.value;
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
        titulo = nome.isEmpty
            ? '🍼 Chá de bebê - Esperando com amor...'
            : controller.nomeEventoPreview.value;
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
        titulo = nome.isEmpty
            ? '🎂 Aniversário - Que venham mais momentos incríveis!'
            : controller.nomeEventoPreview.value;
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
        titulo = nome.isEmpty
            ? '🎉 Sua celebração começa aqui!'
            : controller.nomeEventoPreview.value;
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
          .slideY(
              begin: 0.4, end: 0, duration: 700.ms, curve: Curves.easeOutBack)
          .scaleXY(begin: 0.95, end: 1.0, duration: 500.ms),
    );
  }
}
