import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/evento_controller.dart';
import './../../widgets/frase_aleatoria_widget.dart';

Widget buildAnimatedHeader() {
  final eventoController = Get.find<EventoController>();
  final theme = Get.find<EventThemeController>();

  final isCelular = Get.context!.width < 650;
  final gradient = theme.gradient.value;

  return Obx(() {
    final evento = eventoController.eventoAtualEntidade;
    final tipoEvento = eventoController.tipoEventoAtualEntidade;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 📸 Imagem de fundo
          Hero(
            tag: 'event_header',
            child: Image.asset(
              'assets/images/event_generic_1.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // 🌈 Gradiente do tema
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withValues(alpha: 0.02),
                  gradient.colors.last.withValues(alpha: 0.03),
                  Colors.black.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🌫️ Blur e sobreposição
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),

          // 🔹 Nome do evento
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          tipoEvento?.nome ?? 'Faça a Festa',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isCelular ? 12 : 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evento?.nomeEvento ?? 'Seu evento especial',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isCelular ? 14 : 18,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🪩 Frase dinâmica do tipo de evento
          Positioned(
            top: 70,
            left: 1,
            right: 1,
            child: SizedBox(
              height: 80,
              child: FraseAleatoriaWidget(
                tipoEvento: tipoEvento?.nome ?? "Casamento",
              ),
            ),
          ),

          // 📅 Data e local
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      evento?.data != null
                          ? DateFormat("d 'de' MMMM yyyy", 'pt_BR')
                              .format(evento!.data)
                          : 'Data a definir',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.place_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      evento?.logradouro ?? 'Local não definido',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
