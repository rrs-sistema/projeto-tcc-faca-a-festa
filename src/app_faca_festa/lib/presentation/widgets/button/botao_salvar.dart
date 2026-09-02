import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class BotaoSalvar extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final Color? cor;
  final Icon? icon;

  const BotaoSalvar({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icon,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final corPrincipal = cor ?? theme.primaryColor.value;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              corPrincipal.withValues(alpha: 0.9),
              corPrincipal.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          icon: icon ??
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
          label: Text(
            texto,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
