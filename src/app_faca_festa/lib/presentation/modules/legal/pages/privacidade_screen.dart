import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/legal/politica_privacidade.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoEscuro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFF2D7B),
          foregroundColor: Colors.white,
          systemOverlayStyle: FestaSystemUi.fundoEscuro,
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Privacidade',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text(
              'Política de privacidade',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AuthFestaBrand.titulo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Atualizada em ${PoliticaPrivacidade.atualizacao}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AuthFestaBrand.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              PoliticaPrivacidade.introducao,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 20),
            for (final secao in PoliticaPrivacidade.secoes) ...[
              Text(
                secao.titulo,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AuthFestaBrand.titulo,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                secao.corpo,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.45,
                  color: const Color(0xFF374151),
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
