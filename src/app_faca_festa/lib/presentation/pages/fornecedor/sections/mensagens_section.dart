import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import '../chat/fornecedor_mensagens_page.dart';

class MensagensSection extends StatelessWidget {
  const MensagensSection({super.key});

  @override
  Widget build(BuildContext context) {
    final fornecedorController = Get.find<FornecedorController>();

    return Obx(() {
      final naoLidas = fornecedorController.mensagensNaoLidas.value;
      final possuiPendencia = naoLidas > 0;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final title = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.forum_outlined, size: 19, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensagens',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Central de conversa com organizadores e negociações em andamento.',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final button = OutlinedButton.icon(
                  onPressed: () => Get.to(() => FornecedorMensagensPage()),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    'Abrir central',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                );
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 12), button],
                      )
                    : Row(children: [Expanded(child: title), const SizedBox(width: 12), button]);
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: possuiPendencia
                      ? const [Color(0xFF1D4ED8), Color(0xFF111827)]
                      : const [Color(0xFF111827), Color(0xFF263159)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          possuiPendencia
                              ? '$naoLidas mensagem${naoLidas == 1 ? '' : 's'} não lida${naoLidas == 1 ? '' : 's'}'
                              : 'Nenhuma mensagem nova',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          possuiPendencia
                              ? 'Respostas rápidas aumentam a chance de fechamento e melhoram a experiência do organizador.'
                              : 'Sua central está em dia. Novas conversas aparecerão aqui automaticamente.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
