import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/password_reset_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../core/utils/form_validators.dart';
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

class _EmailStep extends StatefulWidget {
  const _EmailStep({required this.controller, required this.primary});

  final PasswordResetController controller;
  final Color primary;

  @override
  State<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<_EmailStep> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  late final TextEditingController emailCtrl;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController(text: widget.controller.email.value);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.controller.solicitarCodigo();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        children: [
          CustomInputField(
            label: 'E-mail',
            hintlabel: 'Digite seu e-mail cadastrado',
            icon: Icons.email_outlined,
            color: widget.primary,
            titleColor: widget.primary,
            type: InputType.email,
            isRequired: true,
            validator: FormValidators.email,
            onChanged: (value) => widget.controller.email.value = value,
            controller: emailCtrl,
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Enviar código',
            icon: Icons.mark_email_read_outlined,
            primary: widget.primary,
            loading: widget.controller.carregando.value,
            onPressed: _enviar,
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep({required this.controller, required this.primary});

  final PasswordResetController controller;
  final Color primary;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  late final TextEditingController codigoCtrl;
  late final TextEditingController senhaCtrl;
  late final TextEditingController confirmarCtrl;

  @override
  void initState() {
    super.initState();
    codigoCtrl = TextEditingController(text: widget.controller.codigo.value);
    senhaCtrl = TextEditingController(text: widget.controller.novaSenha.value);
    confirmarCtrl =
        TextEditingController(text: widget.controller.confirmarSenha.value);
  }

  @override
  void dispose() {
    codigoCtrl.dispose();
    senhaCtrl.dispose();
    confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.controller.redefinirSenha();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        children: [
          CustomInputField(
            label: 'Código',
            hintlabel: 'Digite o código de 6 dígitos',
            icon: Icons.pin_outlined,
            color: widget.primary,
            titleColor: widget.primary,
            type: InputType.number,
            isRequired: true,
            maxLength: 6,
            validator: FormValidators.codigoVerificacao,
            onChanged: (value) => widget.controller.codigo.value = value,
            controller: codigoCtrl,
          ),
          const SizedBox(height: 12),
          Obx(
            () => CustomInputField(
              label: 'Nova senha',
              hintlabel: 'Mínimo 6 caracteres, com letra e número',
              icon: Icons.lock_outline,
              color: widget.primary,
              titleColor: widget.primary,
              type: InputType.password,
              isRequired: true,
              validator: FormValidators.senha,
              obscureText: !widget.controller.exibirSenha.value,
              suffixIcon: IconButton(
                onPressed: () => widget.controller.exibirSenha.toggle(),
                icon: Icon(
                  widget.controller.exibirSenha.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: widget.primary,
                ),
              ),
              onChanged: (value) => widget.controller.novaSenha.value = value,
              controller: senhaCtrl,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => CustomInputField(
              label: 'Confirmar senha',
              hintlabel: 'Repita a nova senha',
              icon: Icons.lock_reset_outlined,
              color: widget.primary,
              titleColor: widget.primary,
              type: InputType.password,
              isRequired: true,
              validator: (v) => FormValidators.confirmarSenha(
                v,
                senha: senhaCtrl.text,
              ),
              obscureText: !widget.controller.exibirSenha.value,
              onChanged: (value) =>
                  widget.controller.confirmarSenha.value = value,
              controller: confirmarCtrl,
            ),
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Redefinir senha',
            icon: Icons.check_circle_outline_rounded,
            primary: widget.primary,
            loading: widget.controller.carregando.value,
            onPressed: _redefinir,
          ),
          TextButton(
            onPressed: widget.controller.carregando.value
                ? null
                : widget.controller.voltarEtapaEmail,
            child: Text(
              'Usar outro e-mail',
              style: GoogleFonts.poppins(
                  color: widget.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
