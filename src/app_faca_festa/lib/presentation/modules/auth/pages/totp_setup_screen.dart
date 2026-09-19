import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final TotpMfaController controller;
  final EventThemeController themeController;

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
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

  @override
  Widget build(BuildContext context) {
    const accent = AuthFestaBrand.rosaIcone;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3F8),
        body: AuthFestaShell(
          scrollable: true,
          title: 'Proteja sua conta',
          titleHighlight: 'conta',
          subtitle: 'Escolha como confirmar o login com e-mail e senha',
          footerLink: AuthFestaFooterLink(
            prefixo: 'Quer usar outra conta? ',
            acao: 'Sair aqui',
            onTap: controller.sair,
          ),
          child: AuthFestaCard(
            child: Obx(() {
              if (controller.etapa.value == TotpMfaController.etapaTotp) {
                return _EtapaTotp(
                  controller: controller,
                  primary: accent,
                  codigoCtrl: codigoCtrl,
                );
              }
              if (controller.etapa.value == TotpMfaController.etapaEmail) {
                return _EtapaEmail(
                  controller: controller,
                  primary: accent,
                  codigoCtrl: codigoCtrl,
                  cadastro: true,
                );
              }
              return _EtapaEscolha(
                controller: controller,
                primary: accent,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _EtapaEscolha extends StatelessWidget {
  const _EtapaEscolha({required this.controller, required this.primary});

  final TotpMfaController controller;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.security_rounded, size: 48, color: primary),
        const SizedBox(height: 12),
        Text(
          'Verificação em duas etapas',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AuthFestaBrand.titulo,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha como você quer confirmar o login com e-mail e senha.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AuthFestaBrand.muted,
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
        _OpcaoMetodo(
          primary: primary,
          icone: Icons.qr_code_2_rounded,
          titulo: 'App autenticador',
          descricao: 'QR Code no Google Authenticator, Authy ou similar.',
          onTap: controller.escolherAutenticador,
        ),
        const SizedBox(height: 12),
        _OpcaoMetodo(
          primary: primary,
          icone: Icons.mark_email_read_outlined,
          titulo: 'Código por e-mail',
          descricao: 'Enviamos um código de 6 dígitos para o e-mail da conta.',
          onTap: controller.escolherEmail,
        ),
      ],
    );
  }
}

class _OpcaoMetodo extends StatelessWidget {
  const _OpcaoMetodo({
    required this.primary,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  final Color primary;
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icone, color: primary, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtapaTotp extends StatefulWidget {
  const _EtapaTotp({
    required this.controller,
    required this.primary,
    required this.codigoCtrl,
  });

  final TotpMfaController controller;
  final Color primary;
  final TextEditingController codigoCtrl;

  @override
  State<_EtapaTotp> createState() => _EtapaTotpState();
}

class _EtapaTotpState extends State<_EtapaTotp> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  Future<void> _confirmar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.controller.codigo.value = widget.codigoCtrl.text;
    await widget.controller.confirmarCadastro();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final primary = widget.primary;
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Obx(() {
        final gerandoQr = controller.gerandoQr.value;
        final otpauthUrl = controller.otpauthUrl.value;
        final secret = controller.secret.value;
        final falhouQr = controller.falhouQr.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.voltarEscolha,
                icon: Icon(Icons.arrow_back_rounded, color: primary),
                label: Text(
                  'Trocar método',
                  style: GoogleFonts.poppins(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Text(
              'Autenticador',
              style: GoogleFonts.poppins(
                color: AuthFestaBrand.titulo,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escaneie o QR Code no Google Authenticator, Authy ou app similar e confirme o código de 6 dígitos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            if (gerandoQr)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              )
            else if (otpauthUrl.isNotEmpty)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: otpauthUrl,
                      size: 196,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ou informe esta chave no app:',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    secret,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: secret));
                      Get.rawSnackbar(
                        message: 'Chave copiada. Cole no autenticador.',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green.shade700,
                        margin: const EdgeInsets.all(14),
                        borderRadius: 12,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    icon: Icon(Icons.copy_rounded, size: 18, color: primary),
                    label: Text(
                      'Copiar chave',
                      style: GoogleFonts.poppins(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else if (falhouQr)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      'Não foi possível gerar o QR Code.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontSize: 13.5,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: controller.iniciarCadastro,
                      icon: Icon(Icons.refresh_rounded, color: primary),
                      label: Text(
                        'Tentar novamente',
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            CustomInputField(
              label: 'Código do autenticador',
              hintlabel: '000000',
              icon: Icons.shield_outlined,
              controller: widget.codigoCtrl,
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
            _BotaoConfirmar(
              primary: primary,
              loading: controller.carregando.value,
              label: 'Confirmar autenticador',
              onPressed: _confirmar,
            ),
          ],
        );
      }),
    );
  }
}

class _EtapaEmail extends StatefulWidget {
  const _EtapaEmail({
    required this.controller,
    required this.primary,
    required this.codigoCtrl,
    required this.cadastro,
  });

  final TotpMfaController controller;
  final Color primary;
  final TextEditingController codigoCtrl;
  final bool cadastro;

  @override
  State<_EtapaEmail> createState() => _EtapaEmailState();
}

class _EtapaEmailState extends State<_EtapaEmail> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  Future<void> _confirmar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.controller.codigo.value = widget.codigoCtrl.text;
    if (widget.cadastro) {
      await widget.controller.confirmarCadastro();
    } else {
      await widget.controller.verificarLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final primary = widget.primary;
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Obx(() {
        final destino = controller.emailMascarado.value;
        return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.cadastro)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.voltarEscolha,
                icon: Icon(Icons.arrow_back_rounded, color: primary),
                label: Text(
                  'Trocar método',
                  style: GoogleFonts.poppins(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Icon(Icons.mark_email_read_outlined, size: 48, color: primary),
          const SizedBox(height: 12),
          Text(
            'Código por e-mail',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AuthFestaBrand.titulo,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            destino.isEmpty
                ? 'Enviamos um código de 6 dígitos para o e-mail da sua conta.'
                : 'Enviamos um código de 6 dígitos para $destino.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          CustomInputField(
            label: 'Código do e-mail',
            hintlabel: '000000',
            icon: Icons.shield_outlined,
            controller: widget.codigoCtrl,
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
          _BotaoConfirmar(
            primary: primary,
            loading: controller.carregando.value,
            label: widget.cadastro ? 'Confirmar e-mail' : 'Confirmar e entrar',
            onPressed: _confirmar,
          ),
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
        ],
      );
      }),
    );
  }
}

class _BotaoConfirmar extends StatelessWidget {
  const _BotaoConfirmar({
    required this.primary,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final Color primary;
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: const Icon(Icons.verified_outlined, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          disabledBackgroundColor: primary.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
