import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './orcamentos_section.dart';

class MensagensSection extends StatelessWidget {
  const MensagensSection({super.key});

  @override
  Widget build(BuildContext context) {
    final conversas = [
      _ConversaModel(
        id: '1',
        cliente: 'Ana Souza',
        evento: 'Casamento Ana & Pedro',
        ultimaMensagem: 'Perfeito! Podemos fechar para sábado?',
        dataHora: DateTime.now().subtract(const Duration(minutes: 10)),
        naoLida: true,
      ),
      _ConversaModel(
        id: '2',
        cliente: 'Lucas Ferreira',
        evento: 'Aniversário 30 anos',
        ultimaMensagem: 'Pagamento confirmado, obrigado!',
        dataHora: DateTime.now().subtract(const Duration(hours: 2)),
        naoLida: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.forum_outlined, size: 20, color: Colors.grey.shade800),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Central de Comunicações",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🔹 CONVERSAS RECENTES
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  "Interações Recentes no Chat",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              ListView.separated(
                itemCount: conversas.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) =>
                    Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  return _ConversaTile(conversa: conversas[index]);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.snackbar(
                      "Chat",
                      "Abrindo central de mensagens...",
                      backgroundColor: Colors.grey.shade900,
                      colorText: Colors.white,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      "Ver Histórico Completo",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 🔹 ORÇAMENTOS (Subseção embutida de forma elegante)
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrcamentosSection(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed('/orcamentos'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    "Painel Completo de Orçamentos",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversaTile extends StatelessWidget {
  final _ConversaModel conversa;
  const _ConversaTile({required this.conversa});

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays == 1) return 'Ontem';
    return '${diff.inDays} dias atrás';
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle messageStyle = conversa.naoLida
        ? GoogleFonts.poppins(
            color: Colors.grey.shade900, fontSize: 13, fontWeight: FontWeight.w600)
        : GoogleFonts.poppins(
            color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w400);

    return InkWell(
      onTap: () {
        Get.snackbar(
          "Chat",
          "Abrindo chat seguro com ${conversa.cliente}...",
          backgroundColor: Colors.grey.shade900,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade100,
                  child: Icon(Icons.person_outline_rounded, color: Colors.grey.shade500, size: 20),
                ),
                if (conversa.naoLida)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          conversa.evento,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tempoRelativo(conversa.dataHora),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversa.ultimaMensagem,
                    style: messageStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversaModel {
  final String id;
  final String cliente;
  final String evento;
  final String ultimaMensagem;
  final DateTime dataHora;
  final bool naoLida;

  _ConversaModel({
    required this.id,
    required this.cliente,
    required this.evento,
    required this.ultimaMensagem,
    required this.dataHora,
    required this.naoLida,
  });
}
