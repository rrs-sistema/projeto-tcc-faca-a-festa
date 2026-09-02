import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import '../chat/fornecedor_mensagens_page.dart';
import 'fornecedor_premium_layout.dart';

class MensagensSection extends StatelessWidget {
  const MensagensSection({super.key});

  @override
  Widget build(BuildContext context) {
    final fornecedorController = Get.find<FornecedorController>();

    return Obx(() {
      final naoLidas = fornecedorController.mensagensNaoLidas.value;
      final possuiPendencia = naoLidas > 0;
      final color = possuiPendencia
          ? FornecedorPremiumPalette.sky
          : FornecedorPremiumPalette.dark;

      return PremiumSectionShell(
        title: 'Mensagens',
        subtitle: 'Central de conversa com organizadores e negociações.',
        icon: Icons.forum_outlined,
        color: color,
        trailing: OutlinedButton.icon(
          onPressed: () => Get.to(() => FornecedorMensagensPage()),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(
            'Abrir central',
            style: GoogleFonts.poppins(
                fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: FornecedorPremiumPalette.dark,
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: possuiPendencia
                  ? const [Color(0xFF2563EB), Color(0xFF111827)]
                  : const [Color(0xFF111827), Color(0xFF263159)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  possuiPendencia
                      ? Icons.mark_chat_unread_outlined
                      : Icons.mark_chat_read_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      possuiPendencia
                          ? '$naoLidas mensagem${naoLidas == 1 ? '' : 's'} não lida${naoLidas == 1 ? '' : 's'}'
                          : 'Nenhuma mensagem nova',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.3,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      possuiPendencia
                          ? 'Respostas rápidas aumentam a chance de fechamento.'
                          : 'Sua central está em dia. Novas conversas aparecerão aqui.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 11.7,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
