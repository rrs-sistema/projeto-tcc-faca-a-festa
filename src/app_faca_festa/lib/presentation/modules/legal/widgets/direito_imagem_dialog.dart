import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pede a declaração de direito de imagem antes de abrir a galeria.
Future<bool> confirmarDireitoImagem() async {
  final aceitou = await Get.dialog<bool>(
    const _DireitoImagemDialog(),
    barrierDismissible: false,
  );
  return aceitou == true;
}

class _DireitoImagemDialog extends StatefulWidget {
  const _DireitoImagemDialog();

  @override
  State<_DireitoImagemDialog> createState() => _DireitoImagemDialogState();
}

class _DireitoImagemDialogState extends State<_DireitoImagemDialog> {
  var _aceito = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Direito de imagem',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fotos de evento, portfólio ou referência podem mostrar outras pessoas. O envio só segue com a sua declaração.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _aceito,
            activeColor: const Color(0xFFFF2D7B),
            onChanged: (value) => setState(() => _aceito = value ?? false),
            title: Text(
              'Declaro ter autorização das pessoas que aparecem nesta imagem.',
              style: GoogleFonts.poppins(fontSize: 13.5, height: 1.35),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('Cancelar', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: _aceito ? () => Get.back(result: true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF2D7B),
          ),
          child: Text(
            'Continuar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
