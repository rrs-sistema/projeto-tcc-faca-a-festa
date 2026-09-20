import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';

class ConviteNaoEncontradoScreen extends StatelessWidget {
  const ConviteNaoEncontradoScreen({
    super.key,
    required this.appController,
  });

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline_rounded,
                  size: 64, color: Colors.orange.shade700),
              const SizedBox(height: 20),
              Text(
                'Convite não encontrado',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Este link de convite não está ligado a uma festa, ou já expirou. '
                'Peça um novo link ao organizador e abra-o de novo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 28),
              Obx(() {
                final saindo = appController.encerrandoSessao.value;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: saindo ? null : appController.logout,
                    child: saindo
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sair'),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
