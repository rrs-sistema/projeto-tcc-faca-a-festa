import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({
    super.key,
    required this.eventoCadastroController,
  });

  final EventoCadastroController eventoCadastroController;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3F8),
        body: AuthFestaShell(
          title: 'Como você quer participar?',
          titleHighlight: 'participar?',
          subtitle: 'Escolha como deseja participar',
          footerLink: AuthFestaFooterLink(
            prefixo: 'Já tem uma conta? ',
            acao: 'Entrar aqui',
            onTap: () => Get.toNamed('/login'),
          ),
          child: Column(
            children: [
              _RoleChoiceCard(
                eyebrow: 'PLANEJAR EVENTO',
                title: 'Sou Organizador',
                description: 'Crie, planeje e gerencie eventos com facilidade',
                highlight: 'Listas, orçamentos, fornecedores e mais →',
                icon: Icons.event_available_rounded,
                accent: AuthFestaBrand.rosaIcone,
                onTap: () {
                  eventoCadastroController.limpar(manterEndereco: false);
                  Get.toNamed(
                    '/register',
                    arguments: const AuthFluxoArgs(tipo: 'O'),
                  );
                },
              ),
              const SizedBox(height: 10),
              _RoleChoiceCard(
                eyebrow: 'OFERECER SERVIÇO',
                title: 'Sou Fornecedor',
                description: 'Mostre seus serviços para quem está planejando',
                highlight: 'Buffet, decoração, foto, música e mais →',
                icon: Icons.storefront_rounded,
                accent: AuthFestaBrand.roxoIcone,
                onTap: () {
                  eventoCadastroController.limpar(manterEndereco: false);
                  Get.toNamed(
                    '/register',
                    arguments: const AuthFluxoArgs(tipo: 'F'),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Recebeu um convite? Abra o link enviado pelo organizador.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: AuthFestaBrand.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.highlight,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String highlight;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accent.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0E6EC), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Container(
                  height: 2,
                  width: double.infinity,
                  color: accent.withValues(alpha: 0.55),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eyebrow,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.7,
                                color: AuthFestaBrand.muted,
                              ),
                            ),
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: AuthFestaBrand.titulo,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                height: 1.28,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              highlight,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                height: 1.28,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFD1D5DB),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
