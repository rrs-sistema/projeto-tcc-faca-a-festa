import 'package:app_faca_festa/role_selector_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      body: Stack(
        children: [
          // Fundo com imagem e gradiente translúcido
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_event_002.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF9C4),
                  Color(0xFFFFC1E3),
                  Color(0xFFB3E5FC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.35)),

          // Conteúdo
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '🎉 Faça a Festa',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade800,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Campo Email
                    TextField(
                      onChanged: (v) => controller.email.value = v,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.pink),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Senha
                    TextField(
                      obscureText: true,
                      onChanged: (v) => controller.senha.value = v,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.pinkAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Botão de Login
                    Obx(() {
                      return ElevatedButton(
                        onPressed: controller.carregando.value ? null : () => controller.login(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade700,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.carregando.value
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Entrar',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Link para cadastro
                    GestureDetector(
                      onTap: () => Get.to(() => const RoleSelectorScreen()),
                      child: RichText(
                        text: TextSpan(
                          text: "Ainda não tem uma conta? ",
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: "Cadastre-se aqui",
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
                    const SizedBox(height: 40),

                    Text(
                      'Desenvolvido por Faça a Festa',
                      style: GoogleFonts.poppins(
                        color: Colors.pink.shade800.withValues(alpha: 0.8),
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
        ],
      ),
    );
  }
}
