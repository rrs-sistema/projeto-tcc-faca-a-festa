import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/event_theme_controller.dart';

class AdminPalette {
  static const Color dark = Color(0xFF134E4A);
  static const Color primary = Color(0xFF0F766E);
  static const Color accent = Color(0xFF14B8A6);
  static const Color surface = Color(0xFFF4F7F8);
  static const Color card = Colors.white;
  static const Color muted = Color(0xFF64748B);
  static const Color ink = Color(0xFF0F172A);
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFC2410C);
  static const Color danger = Color(0xFFBE123C);
  static const Color border = Color(0xFFE2E8F0);

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF0F3D3A), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

extension AdminTheme on EventThemeController {
  LinearGradient get adminGradient => AdminPalette.appBarGradient;

  Color get adminAccent => AdminPalette.primary;

  ThemeData get adminThemeData => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminPalette.primary,
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: AdminPalette.surface,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AdminPalette.primary;
            }
            return const Color(0xFFCBD5E1);
          }),
        ),
      );
}
