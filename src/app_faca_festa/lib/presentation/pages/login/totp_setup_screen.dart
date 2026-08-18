import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/totp_mfa_controller.dart';
import '../../widgets/custom_input_field.dart';

class TotpSetupScreen extends StatelessWidget {
  const TotpSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TotpMfaController());
    final theme = Get.find<EventThemeController>();
    final gradient = theme.gradient.value;
    final primary = theme.primaryColor.value;
    final codigoCtrl = TextEditingController();

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
                    if (controller.etapa.value == TotpMfaController.etapaTotp) {
                      return _EtapaTotp(
                        controller: controller,
                        primary: primary,
                        codigoCtrl: codigoCtrl,
                      );
                    }
                    if (controller.etapa.value == TotpMfaController.etapaEmail) {
                      return _EtapaEmail(
                        controller: controller,
                        primary: primary,
                        codigoCtrl: codigoCtrl,
                        cadastro: true,
                      );
                    }
                    return _EtapaEscolha(
                      controller: controller,
                      primary: primary,
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
          style: GoogleFonts.fredoka(
            color: primary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha como você quer confirmar o login com e-mail e senha.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade700,
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

class _EtapaTotp extends StatelessWidget {
  const _EtapaTotp({
    required this.controller,
    required this.primary,
    required this.codigoCtrl,
  });

  final TotpMfaController controller;
  final Color primary;
  final TextEditingController codigoCtrl;

  @override
  Widget build(BuildContext context) {
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
          style: GoogleFonts.fredoka(
            color: primary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
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
        if (controller.gerandoQr.value)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          )
        else if (controller.otpauthUrl.value.isNotEmpty)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: controller.otpauthUrl.value,
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
                controller.secret.value,
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
                  await Clipboard.setData(
                    ClipboardData(text: controller.secret.value),
                  );
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
          ),
        const SizedBox(height: 18),
        CustomInputField(
          label: 'Código do autenticador',
          hintlabel: '000000',
          icon: Icons.shield_outlined,
          controller: codigoCtrl,
          color: primary,
          titleColor: primary,
          type: InputType.number,
          maxLength: 6,
          keyboardType: TextInputType.number,
          onChanged: (value) => controller.codigo.value = value,
        ),
        const SizedBox(height: 16),
        _BotaoConfirmar(
          primary: primary,
          loading: controller.carregando.value,
          label: 'Confirmar autenticador',
          onPressed: controller.confirmarCadastro,
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
    );
  }
}

class _EtapaEmail extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final destino = controller.emailMascarado.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (cadastro)
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
          style: GoogleFonts.fredoka(
            color: primary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
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
          controller: codigoCtrl,
          color: primary,
          titleColor: primary,
          type: InputType.number,
          maxLength: 6,
          keyboardType: TextInputType.number,
          onChanged: (value) => controller.codigo.value = value,
        ),
        const SizedBox(height: 16),
        _BotaoConfirmar(
          primary: primary,
          loading: controller.carregando.value,
          label: cadastro ? 'Confirmar e-mail' : 'Confirmar e entrar',
          onPressed: cadastro
              ? controller.confirmarCadastro
              : controller.verificarLogin,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
