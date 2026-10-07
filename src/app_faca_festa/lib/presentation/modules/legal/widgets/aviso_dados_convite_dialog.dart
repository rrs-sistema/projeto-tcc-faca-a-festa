import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/legal/pages/privacidade_screen.dart';

Future<void> mostrarAvisoDadosConvite(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Como usamos seus dados',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Seu nome, contato e confirmação de presença são usados somente neste evento, para a lista de convidados e o RSVP. O organizador da festa informou esses dados para enviar o convite.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.45,
            color: const Color(0xFF374151),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).push(PrivacidadeScreen.rota());
            },
            child: Text(
              'Política de privacidade',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D7B),
            ),
            child: Text(
              'Entendi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    },
  );
}
