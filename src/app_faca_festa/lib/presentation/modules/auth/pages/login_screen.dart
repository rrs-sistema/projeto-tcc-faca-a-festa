import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/login_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.themeController,
    required this.appController,
  });

  final LoginController controller;
  final EventThemeController themeController;
  final AppController appController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  late final LoginController controller;
  late final TextEditingController emailCtrl;
  late final TextEditingController senhaCtrl;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    emailCtrl = TextEditingController();
    senhaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await controller.login();
  }

  void _irParaCadastro() {
    final token = widget.appController.tokenConviteAtual()?.trim() ?? '';
    if (token.isNotEmpty) {
      Get.toNamed(
        '/register',
        arguments: AuthFluxoArgs(
          tipo: 'C',
          conviteToken: token,
        ),
      );
      return;
    }
    Get.toNamed('/role');
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
          title: 'Entre e faça a festa',
          titleHighlight: 'faça a festa',
          subtitle: 'Acesse para planejar o evento ou oferecer serviços',
          footerLink: AuthFestaFooterLink(
            prefixo: 'Ainda não tem uma conta? ',
            acao: 'Cadastre-se aqui',
            onTap: _irParaCadastro,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                children: [
                  CustomInputField(
                    label: 'E-mail',
                    hintlabel: 'ex: contato@email.com',
                    icon: Icons.email_outlined,
                    controller: emailCtrl,
                    color: accent,
                    titleColor: accent,
                    type: InputType.email,
                    isRequired: true,
                    validator: FormValidators.email,
                    onChanged: (v) => controller.email.value = v,
                  ),
                  CustomInputField(
                    label: 'Senha',
                    hintlabel: 'Digite sua senha',
                    icon: Icons.lock_outline,
                    controller: senhaCtrl,
                    color: accent,
                    obscureText: true,
                    titleColor: accent,
                    type: InputType.password,
                    isRequired: true,
                    validator: FormValidators.senhaLogin,
                    onChanged: (v) => controller.senha.value = v,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.toNamed('/forgotPassword'),
                      child: Text(
                        'Esqueci minha senha',
                        style: GoogleFonts.poppins(
                          color: accent,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    return SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.carregando.value ? null : _entrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          disabledBackgroundColor: accent.withValues(alpha: 0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: controller.carregando.value
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.3,
                                ),
                              )
                            : Text(
                                'Entrar',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: GoogleFonts.poppins(
                            color: AuthFestaBrand.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: controller.carregando.value
                            ? null
                            : () async => await controller.loginComGoogle(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Text(
                          'G',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4285F4),
                            fontSize: 18,
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
          ),
        ),
      ),
    );
  }
}
