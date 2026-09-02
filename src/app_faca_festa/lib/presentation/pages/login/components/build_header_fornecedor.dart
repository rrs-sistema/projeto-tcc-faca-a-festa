import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

Widget buildHeaderFornecedor() {
  final theme = Get.find<EventThemeController>();

  return SizedBox(
    height: 260,
    width: double.infinity,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          top: -95,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000000),
                  Color(0xFF111111),
                  Color(0xFF1A1A1A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Lottie.asset(
              'assets/animations/particulas_profissionais.json',
              repeat: true,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.value.withValues(alpha: 0.95),
                    theme.secondaryColor.value.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 48,
              ),
            )
                .animate()
                .fadeIn(duration: 700.ms)
                .scale(begin: Offset(0.8, 0.0), curve: Curves.easeOutBack)
                .then(delay: NumDurationExtensions(1).seconds)
                .shimmer(duration: NumDurationExtensions(2).seconds),
            const SizedBox(height: 60),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white,
                  theme.secondaryColor.value.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Cresça com o Faça a Festa',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                  color: Colors.white,
                ),
              ),
            ).animate().fadeIn(duration: 900.ms).slideY(begin: 0.4),
            const SizedBox(height: 6),
            Text(
              'Conecte-se a novos clientes, destaque seus serviços e amplie seus negócios!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                height: 1.2,
              ),
            ).animate().fadeIn(duration: 1100.ms).slideY(begin: 0.3),
            const SizedBox(height: 15),
            Container(
              height: 4,
              width: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  colors: [
                    theme.secondaryColor.value.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.9),
                    theme.secondaryColor.value.withValues(alpha: 0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 1000.ms)
                .scale(begin: Offset(0.6, 0.0)),
          ],
        ),
      ],
    ),
  );
}
