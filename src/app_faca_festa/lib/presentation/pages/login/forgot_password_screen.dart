import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/password_reset_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../widgets/custom_input_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PasswordResetController());
    final theme = Get.find<EventThemeController>();
    final gradient = theme.gradient.value;
    final primary = theme.primaryColor.value;

    return Scaffold(
      body: Stack(
        children: [
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
                  gradient.colors.first.withValues(alpha: 0.42),
                  gradient.colors.last.withValues(alpha: 0.52),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Obx(
                    () => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: primary,
                          ),
                        ),
                        Text(
                          'Recuperar senha',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            color: primary,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _descricaoEtapa(controller.etapa.value),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (controller.etapa.value == 0)
                          _EmailStep(controller: controller, primary: primary)
                        else if (controller.etapa.value == 1)
                          _CodeStep(controller: controller, primary: primary)
                        else
                          _SuccessStep(primary: primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _descricaoEtapa(int etapa) {
    switch (etapa) {
      case 1:
        return 'Digite o código recebido no e-mail e escolha uma nova senha.';
      case 2:
        return 'Sua senha foi atualizada. Você já pode entrar novamente.';
      default:
        return 'Informe seu e-mail para receber um código de verificação.';
    }
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({required this.controller, required this.primary});

  final PasswordResetController controller;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomInputField(
          label: 'E-mail',
          hintlabel: 'Digite seu e-mail cadastrado',
          icon: Icons.email_outlined,
          color: primary,
          titleColor: primary,
          type: InputType.email,
          onChanged: (value) => controller.email.value = value,
          controller: TextEditingController(text: controller.email.value),
        ),
        const SizedBox(height: 20),
        _ActionButton(
          label: 'Enviar código',
          icon: Icons.mark_email_read_outlined,
          primary: primary,
          loading: controller.carregando.value,
          onPressed: controller.solicitarCodigo,
        ),
      ],
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({required this.controller, required this.primary});

  final PasswordResetController controller;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomInputField(
          label: 'Código',
          hintlabel: 'Digite o código de 6 dígitos',
          icon: Icons.pin_outlined,
          color: primary,
          titleColor: primary,
          onChanged: (value) => controller.codigo.value = value,
          controller: TextEditingController(text: controller.codigo.value),
        ),
        const SizedBox(height: 12),
        Obx(
          () => CustomInputField(
            label: 'Nova senha',
            hintlabel: 'Digite a nova senha',
            icon: Icons.lock_outline,
            color: primary,
            titleColor: primary,
            type: InputType.password,
            obscureText: !controller.exibirSenha.value,
            suffixIcon: IconButton(
              onPressed: () => controller.exibirSenha.toggle(),
              icon: Icon(
                controller.exibirSenha.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: primary,
              ),
            ),
            onChanged: (value) => controller.novaSenha.value = value,
            controller: TextEditingController(text: controller.novaSenha.value),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => CustomInputField(
            label: 'Confirmar senha',
            hintlabel: 'Repita a nova senha',
            icon: Icons.lock_reset_outlined,
            color: primary,
            titleColor: primary,
            type: InputType.password,
            obscureText: !controller.exibirSenha.value,
            onChanged: (value) => controller.confirmarSenha.value = value,
            controller:
                TextEditingController(text: controller.confirmarSenha.value),
          ),
        ),
        const SizedBox(height: 20),
        _ActionButton(
          label: 'Redefinir senha',
          icon: Icons.check_circle_outline_rounded,
          primary: primary,
          loading: controller.carregando.value,
          onPressed: controller.redefinirSenha,
        ),
        TextButton(
          onPressed:
              controller.carregando.value ? null : controller.voltarEtapaEmail,
          child: Text(
            'Usar outro e-mail',
            style: GoogleFonts.poppins(
                color: primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 58),
        const SizedBox(height: 18),
        _ActionButton(
          label: 'Voltar para o login',
          icon: Icons.login_rounded,
          primary: primary,
          loading: false,
          onPressed: () => Get.offNamed('/login'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color primary;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          loading ? 'Aguarde...' : label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
