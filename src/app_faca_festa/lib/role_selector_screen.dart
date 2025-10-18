import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'presentation/pages/login/login_screen.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFF8BBD0), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🎉 Logo / título
                  Text(
                    "🎊 Faça a Festa",
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.pink.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Escolha como deseja participar do evento",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 50),

                  _buildRoleCard(
                    icon: Icons.event_available,
                    label: "Sou Organizador",
                    color: Colors.pinkAccent,
                    onTap: () => Get.toNamed('/register', arguments: {'tipo': 'O'}),
                  ),
                  const SizedBox(height: 20),

                  _buildRoleCard(
                    icon: Icons.store_mall_directory,
                    label: "Sou Fornecedor",
                    color: Colors.green.shade600,
                    onTap: () => Get.toNamed('/register', arguments: {'tipo': 'F'}),
                  ),
                  const SizedBox(height: 20),

                  _buildRoleCard(
                    icon: Icons.card_giftcard,
                    label: "Sou Convidado",
                    color: Colors.orange.shade700,
                    onTap: () => Get.toNamed('/registerGuest', arguments: {'tipo': 'C'}),
                  ),
                  const SizedBox(height: 50),
                  // ✨ Rodapé
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                              () => const LoginScreen(),
                              transition: Transition.fadeIn,
                              duration: const Duration(milliseconds: 500),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: "Já tem uma conta? ",
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Entrar aqui",
                                  style: GoogleFonts.poppins(
                                    color: Colors.pink.shade800,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text(
                    'Desenvolvido por Faça a Festa',
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade800.withValues(alpha: 0.8),
                      fontSize: 13.5,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: color.withValues(alpha: 0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
