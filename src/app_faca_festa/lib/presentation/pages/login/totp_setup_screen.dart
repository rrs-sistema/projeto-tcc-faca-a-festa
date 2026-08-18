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
    final controller = Get.put(TotpMfaController(gerarQrNoInicio: true));
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
                  child: Obx(
                    () => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                    ClipboardData(
                                        text: controller.secret.value),
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
                                icon: Icon(Icons.copy_rounded,
                                    size: 18, color: primary),
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
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: controller.carregando.value
                                ? null
                                : controller.confirmarCadastro,
                            icon: const Icon(Icons.verified_outlined,
                                color: Colors.white),
                            label: Text(
                              'Confirmar autenticador',
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
