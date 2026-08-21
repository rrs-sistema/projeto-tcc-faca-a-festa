import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/app_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/login_controller.dart';
import './../../widgets/custom_input_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final theme = Get.find<EventThemeController>();
    final gradient = theme.gradient.value;

    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Fundo com imagem e overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_event_002.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withValues(alpha: 0.35),
                  gradient.colors.last.withValues(alpha: 0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🩵 Efeito de blur translúcido
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),

          // ✨ Conteúdo
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🌟 Logo e Título
                    Text(
                      '🎉 Faça a Festa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 36,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(1, 2),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Organize, inspire e celebre com estilo',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // 🪩 Card principal
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // Campo Email
                          CustomInputField(
                            label: 'Email',
                            hintlabel: 'Digite seu email',
                            icon: Icons.email_outlined,
                            controller: emailCtrl,
                            color: theme.primaryColor.value,
                            titleColor: theme.primaryColor.value,
                            type: InputType.email,
                            onChanged: (v) => controller.email.value = v,
                          ),

                          // Campo Senha
                          CustomInputField(
                            label: 'Senha',
                            hintlabel: 'Digite sua senha',
                            icon: Icons.lock_outline,
                            controller: senhaCtrl,
                            color: theme.primaryColor.value,
                            obscureText: true,
                            titleColor: theme.primaryColor.value,
                            type: InputType.password,
                            onChanged: (v) => controller.senha.value = v,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Get.toNamed('/forgotPassword'),
                              child: Text(
                                'Esqueci minha senha',
                                style: GoogleFonts.poppins(
                                  color: theme.primaryColor.value,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Botão Entrar
                          Obx(() {
                            return SizedBox(
                              height: 55,
                              child: ElevatedButton(
                                onPressed: controller.carregando.value
                                    ? null
                                    : () async => await controller.login(),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ).copyWith(
                                  elevation: WidgetStateProperty.all(0),
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return gradient.colors.first
                                          .withValues(alpha: 0.6);
                                    }
                                    return null;
                                  }),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: gradient,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: controller.carregando.value
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.3,
                                            ),
                                          )
                                        : Text(
                                            'Entrar',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ou',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: controller.carregando.value
                                    ? null
                                    : () async =>
                                        await controller.loginComGoogle(),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.grey.shade800,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: Text(
                                  'G',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF4285F4),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                label: Text(
                                  'Entrar com Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔗 Cadastro
                    GestureDetector(
                      onTap: () {
                        final app = Get.find<AppController>();
                        final token = app.tokenConviteAtual()?.trim() ?? '';
                        if (token.isNotEmpty) {
                          Get.toNamed('/register', arguments: {
                            'tipo': 'C',
                            'convidado': true,
                            'conviteToken': token,
                          });
                          return;
                        }
                        Get.toNamed('/role');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Ainda não tem uma conta? ",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: "Cadastre-se aqui",
                              style: GoogleFonts.poppins(
                                color: Colors.yellow.shade100,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Rodapé

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF81D4FA),
                              Color(0xFFCE93D8),
                              Color(0xFFFF80AB),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            "by Jullia A. Nicolas B. Rivaldo R.",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
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
