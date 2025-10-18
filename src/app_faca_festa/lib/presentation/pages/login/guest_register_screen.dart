import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/register_controller.dart';
import '../../../role_selector_screen.dart';
import './../login/login_screen.dart';

class GuestRegisterScreen extends StatelessWidget {
  const GuestRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());

    return Scaffold(
      body: Stack(
        children: [
          // Fundo com imagem temática suave
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_event_001.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF3E0), // fundo leve alaranjado
                  Color(0xFFFFCC80),
                  Color(0xFFFFB74D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.25)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '🎉 Cadastro de Convidado',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Nome
                    TextField(
                      onChanged: (v) => controller.nome.value = v,
                      decoration: InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.orange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextField(
                      onChanged: (v) => controller.email.value = v,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.orange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Senha
                    Obx(() {
                      return TextField(
                        obscureText: !controller.exibirSenha.value,
                        onChanged: (v) => controller.senha.value = v,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.exibirSenha.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.orange.shade700,
                            ),
                            onPressed: () =>
                                controller.exibirSenha.value = !controller.exibirSenha.value,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 30),

                    // Botão de cadastro
                    Obx(() {
                      return ElevatedButton.icon(
                        onPressed: controller.carregando.value
                            ? null
                            : () => controller.registrarUsuario(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: controller.carregando.value
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Finalizar Cadastro',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    }),
                    const SizedBox(height: 25),

                    // Link para login
                    GestureDetector(
                      onTap: () => Get.off(() => const LoginScreen()),
                      child: RichText(
                        text: TextSpan(
                          text: "Já é convidado? ",
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: "Entrar aqui",
                              style: GoogleFonts.poppins(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Voltar à tela inicial
                    GestureDetector(
                      onTap: () => Get.off(() => const RoleSelectorScreen()),
                      child: RichText(
                        text: TextSpan(
                          text: "Deseja voltar à tela inicial? ",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: "Toque aqui",
                              style: GoogleFonts.poppins(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'por Faça a Festa',
                      style: GoogleFonts.poppins(
                        color: Colors.orange.shade800.withValues(alpha: 0.7),
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
