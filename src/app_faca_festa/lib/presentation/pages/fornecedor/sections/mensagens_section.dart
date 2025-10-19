import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './orcamentos_section.dart';

class MensagensSection extends StatelessWidget {
  const MensagensSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Simulação de conversas recentes (mock)
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
      _ConversaModel(
        id: '3',
        cliente: 'Beatriz Lima',
        evento: 'Chá Revelação',
        ultimaMensagem: 'Enviado o contrato por e-mail 😊',
        dataHora: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        naoLida: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =======================================
        // 🔹 CABEÇALHO PRINCIPAL
        // =======================================
        Text(
          "💬 Mensagens e Orçamentos",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        // =======================================
        // 🔹 CONVERSAS RECENTES
        // =======================================
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📨 Conversas Recentes",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  itemCount: conversas.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.6),
                  itemBuilder: (context, index) {
                    final c = conversas[index];
                    return _ConversaTile(conversa: c);
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Get.snackbar(
                      "Mensagens",
                      "Abrindo caixa de entrada completa...",
                      backgroundColor: const Color(0xFF2E7D32),
                      colorText: Colors.white,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32)),
                    label: Text(
                      "Ver todas as conversas",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // =======================================
        // 💰 ORÇAMENTOS RECEBIDOS
        // =======================================
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Subcomponente dinâmico
                const OrcamentosSection(),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Get.toNamed('/orcamentos'),
                    icon: const Icon(Icons.request_quote_rounded, color: Color(0xFF2E7D32)),
                    label: Text(
                      "Ver todos os orçamentos",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    final cor = conversa.naoLida ? Colors.teal.shade700 : Colors.grey.shade600;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.teal.shade100,
            child: Icon(Icons.person, color: Colors.teal.shade700),
          ),
          if (conversa.naoLida)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conversa.evento,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          conversa.ultimaMensagem,
          style: GoogleFonts.poppins(
            color: cor,
            fontSize: 13.5,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Text(
        _tempoRelativo(conversa.dataHora),
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      onTap: () {
        Get.snackbar(
          "Chat",
          "Abrindo conversa com ${conversa.cliente}...",
          backgroundColor: Colors.teal.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
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
