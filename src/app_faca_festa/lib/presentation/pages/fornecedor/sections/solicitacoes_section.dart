import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SolicitacoesSection extends StatelessWidget {
  const SolicitacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Mock de dados locais (futuro: Firestore)
    final solicitacoes = [
      _SolicitacaoModel(
        id: '1',
        cliente: 'Ana Souza',
        evento: 'Casamento Ana & Pedro',
        data: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'pendente',
        valor: 0,
        mensagem: 'Gostaria de um orçamento para decoração floral completa.',
      ),
      _SolicitacaoModel(
        id: '2',
        cliente: 'Lucas Ferreira',
        evento: 'Aniversário 30 anos',
        data: DateTime.now().subtract(const Duration(days: 1)),
        status: 'em_negociacao',
        valor: 850,
        mensagem: 'Negociando pacote com buffet + som.',
      ),
      _SolicitacaoModel(
        id: '3',
        cliente: 'Beatriz Lima',
        evento: 'Chá Revelação',
        data: DateTime.now().subtract(const Duration(days: 2)),
        status: 'fechado',
        valor: 1200,
        mensagem: 'Contrato fechado com pagamento de sinal.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "📩 Solicitações Recentes",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        // 🔹 Lista de solicitações
        ListView.separated(
          itemCount: solicitacoes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = solicitacoes[index];
            return _SolicitacaoCard(solicitacao: s);
          },
        ),

        // 🔹 Botão inferior
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => Get.snackbar(
              "Solicitações",
              "Abrindo lista completa...",
              backgroundColor: const Color(0xFF2E7D32),
              colorText: Colors.white,
            ),
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            label: Text(
              "Ver todas",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SolicitacaoCard extends StatelessWidget {
  final _SolicitacaoModel solicitacao;
  const _SolicitacaoCard({required this.solicitacao});

  Color _statusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orangeAccent;
      case 'em_negociacao':
        return Colors.blueAccent;
      case 'fechado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pendente':
        return Icons.hourglass_empty_rounded;
      case 'em_negociacao':
        return Icons.forum_outlined;
      case 'fechado':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(solicitacao.status);
    final icon = _statusIcon(solicitacao.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          solicitacao.evento,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            solicitacao.mensagem,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              solicitacao.status.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              solicitacao.valor > 0 ? "R\$ ${solicitacao.valor.toStringAsFixed(2)}" : "Aguardando",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          Get.snackbar(
            "Solicitação",
            "Abrindo detalhes de ${solicitacao.evento}...",
            backgroundColor: color,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        },
      ),
    );
  }
}

class _SolicitacaoModel {
  final String id;
  final String cliente;
  final String evento;
  final String status;
  final String mensagem;
  final DateTime data;
  final double valor;

  _SolicitacaoModel({
    required this.id,
    required this.cliente,
    required this.evento,
    required this.status,
    required this.mensagem,
    required this.data,
    required this.valor,
  });
}
