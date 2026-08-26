import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/totp_mfa_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../widgets/custom_input_field.dart';

class TotpVerifyScreen extends StatefulWidget {
  const TotpVerifyScreen({super.key});

  @override
  State<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends State<TotpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  late final TotpMfaController controller;
  late final TextEditingController codigoCtrl;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TotpMfaController());
    codigoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await controller.verificarLogin();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Obx(() {
                    final porEmail =
                        controller.metodoLogin.value == TotpMfaController.etapaEmail;
                    final destino = controller.emailMascarado.value;
                    return Form(
                      key: _formKey,
                      autovalidateMode: _autovalidateMode,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          porEmail
                              ? Icons.mark_email_read_outlined
                              : Icons.security_rounded,
                          size: 48,
                          color: primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Verificação em duas etapas',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            color: primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          porEmail
                              ? (destino.isEmpty
                                  ? 'Informe o código de 6 dígitos enviado para o e-mail da sua conta.'
                                  : 'Informe o código enviado para $destino.')
                              : 'Abra o app autenticador e informe o código de 6 dígitos para entrar.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 22),
                        CustomInputField(
                          label: porEmail
                              ? 'Código do e-mail'
                              : 'Código do autenticador',
                          hintlabel: '000000',
                          icon: Icons.shield_outlined,
                          controller: codigoCtrl,
                          color: primary,
                          titleColor: primary,
                          type: InputType.number,
                          isRequired: true,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          validator: FormValidators.codigoVerificacao,
                          onChanged: (value) => controller.codigo.value = value,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: controller.carregando.value
                                ? null
                                : _confirmar,
                            icon: const Icon(Icons.login_rounded,
                                color: Colors.white),
                            label: Text(
                              'Confirmar e entrar',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        if (porEmail)
                          TextButton(
                            onPressed: controller.enviandoEmail.value
                                ? null
                                : controller.solicitarCodigoEmail,
                            child: Text(
                              'Reenviar código',
                              style: GoogleFonts.poppins(
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        TextButton(
                          onPressed: controller.sair,
                          child: Text(
                            'Sair',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
