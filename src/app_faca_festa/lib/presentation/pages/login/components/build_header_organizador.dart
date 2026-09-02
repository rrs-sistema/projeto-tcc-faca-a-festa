import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import './../../../widgets/confetti_background.dart';

Widget buildHeaderOrganizador(bool isFornecedor, {bool isConvidado = false}) {
  final theme = Get.find<EventThemeController>();

  return Stack(
    alignment: Alignment.center,
    children: [
      Positioned.fill(
        child: ConfettiBackground(seconds: 45),
      ),
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.value.withValues(alpha: 0.9),
                  theme.secondaryColor.value.withValues(alpha: 0.5),
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
            child: Icon(
              isConvidado
                  ? Icons.card_giftcard_rounded
                  : isFornecedor
                      ? Icons.storefront_rounded
                      : Icons.event_available_rounded,
              color: Colors.white,
              size: 44,
            ),
          )
              .animate()
              .fadeIn(duration: 700.ms)
              .scale(begin: const Offset(0.8, 0.0), curve: Curves.easeOutBack)
              .then(delay: NumDurationExtensions(1).seconds)
              .shimmer(duration: NumDurationExtensions(2).seconds),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.white,
                theme.secondaryColor.value.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.value.withValues(alpha: 0.9),
                    theme.primaryColor.value,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: theme.primaryColor.value.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.value.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isConvidado
                      ? 'Cadastro de convidado'
                      : isFornecedor
                          ? 'Crie sua conta de Fornecedor'
                          : 'Organize seu Evento dos Sonhos',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 5,
                        color: theme.primaryColor.value,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 900.ms).slideY(
                begin: 0.4,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 8),
          Text(
            isConvidado
                ? 'Crie sua conta para acessar o evento do convite.'
                : isFornecedor
                    ? 'Mostre seu talento e receba novos pedidos!'
                    : 'Transforme cada detalhe em uma lembrança inesquecível!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ).animate().fadeIn(duration: 1100.ms).slideY(
                begin: 0.3,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 25),
          Container(
            height: 4,
            width: 100,
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
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 1000.ms).scale(
                begin: const Offset(0.6, 0.0),
              ),
        ],
      ),
    ],
  );
}
