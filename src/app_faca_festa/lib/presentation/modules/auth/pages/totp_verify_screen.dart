import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class TotpVerifyScreen extends StatefulWidget {
  const TotpVerifyScreen({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final TotpMfaController controller;
  final EventThemeController themeController;

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
    controller = widget.controller;
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
    const accent = AuthFestaBrand.rosaIcone;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3F8),
        body: AuthFestaShell(
          scrollable: true,
          title: 'Confirme o acesso',
          titleHighlight: 'acesso',
          subtitle: 'Verificação em duas etapas para entrar na sua conta',
          footerLink: AuthFestaFooterLink(
            prefixo: 'Quer usar outra conta? ',
            acao: 'Sair aqui',
            onTap: controller.sair,
          ),
          child: AuthFestaCard(
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
                      color: accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      porEmail
                          ? (destino.isEmpty
                              ? 'Informe o código de 6 dígitos enviado para o e-mail da sua conta.'
                              : 'Informe o código enviado para $destino.')
                          : 'Abra o app autenticador e informe o código de 6 dígitos para entrar.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AuthFestaBrand.muted,
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
                      color: accent,
                      titleColor: accent,
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
                        onPressed:
                            controller.carregando.value ? null : _confirmar,
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
                          backgroundColor: accent,
                          disabledBackgroundColor:
                              accent.withValues(alpha: 0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                            color: accent,
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
    );
  }
}
