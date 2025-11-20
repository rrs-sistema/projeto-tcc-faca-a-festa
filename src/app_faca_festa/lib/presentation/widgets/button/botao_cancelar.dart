import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import '../../../controllers/tema/event_theme_controller.dart';

class BotaoCancelar extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final Color? corPrincipal;
  final Color? corBackground;

  const BotaoCancelar({
    super.key,
    required this.texto,
    required this.onPressed,
    this.corPrincipal,
    this.corBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final corPrincipalOpcao = corPrincipal ?? theme.secondaryColor.value;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton.icon(
        icon: Icon(Icons.cancel_outlined, color: Colors.white, size: 26),
        label: Text(
          texto,
          style:
              GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 20),
        ),
        style: TextButton.styleFrom(
          overlayColor: corPrincipalOpcao.withValues(alpha: 0.1),
          backgroundColor: corBackground ?? Colors.white.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
