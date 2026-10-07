import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/legal/politica_privacidade.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/central_privacidade_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class PrivacidadeScreen extends StatelessWidget {
  const PrivacidadeScreen({super.key});

  static Route<void> rota() {
    return MaterialPageRoute<void>(
      builder: (_) => const PrivacidadeScreen(),
      settings: const RouteSettings(name: '/privacidade'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Get.isRegistered<EventThemeController>()
        ? Get.find<EventThemeController>()
        : null;
    if (tema == null) {
      final scheme = Theme.of(context).colorScheme;
      return _pagina(
        context,
        primary: scheme.primary,
        surface: const Color(0xFFF4F7F8),
        onPrimary: scheme.onPrimary,
        tema: null,
      );
    }
    return Obx(
      () => _pagina(
        context,
        primary: tema.primaryColor.value,
        surface: tema.surfaceColor.value,
        onPrimary: tema.onPrimaryColor.value,
        tema: tema,
      ),
    );
  }

  Widget _pagina(
    BuildContext context, {
    required Color primary,
    required Color surface,
    required Color onPrimary,
    required EventThemeController? tema,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoEscuro,
      child: Scaffold(
        backgroundColor: surface,
        appBar: FestaAppBar(
          titulo: 'Privacidade',
          themeController: tema,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text(
              'Política de privacidade',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Atualizada em ${PoliticaPrivacidade.atualizacao}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              PoliticaPrivacidade.introducao,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () =>
                  Navigator.of(context).push(CentralPrivacidadeScreen.rota()),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: Text(
                'Ver telas e campos protegidos',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
            for (final secao in PoliticaPrivacidade.secoes) ...[
              Text(
                secao.titulo,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                secao.corpo,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.45,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
