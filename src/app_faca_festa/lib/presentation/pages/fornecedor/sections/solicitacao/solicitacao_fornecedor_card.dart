import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SolicitacaoFornecedorCard extends StatelessWidget {
  final dynamic solicitacao;
  const SolicitacaoFornecedorCard({super.key, required this.solicitacao});

  Color _statusColor(String status) {
    switch (status) {
      case 'aguardando':
      case 'pendente':
        return Colors.orangeAccent;
      case 'respondido':
      case 'em_negociacao':
        return Colors.blueAccent;
      case 'fechado':
        return Colors.green;
      case 'recusado':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'aguardando':
      case 'pendente':
        return Icons.hourglass_bottom_rounded;
      case 'respondido':
      case 'em_negociacao':
        return Icons.chat_bubble_outline_rounded;
      case 'fechado':
        return Icons.check_circle_outline_rounded;
      case 'recusado':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(solicitacao.status);
    final icon = _statusIcon(solicitacao.status);
    final dataFmt = DateFormat('dd/MM/yyyy • HH:mm').format(solicitacao.data);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => debugPrint('🟢 Clique na solicitação ${solicitacao.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === ÍCONE / STATUS ===
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),

                  // === CONTEÚDO PRINCIPAL ===
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Cabeçalho: nome do evento + status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                solicitacao.evento,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: Colors.grey.shade900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                solicitacao.status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: color,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // 🔹 Mensagem ou descrição curta
                        Text(
                          solicitacao.mensagem.isNotEmpty
                              ? solicitacao.mensagem
                              : "Sem descrição adicional.",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),
                        // 🔹 Serviços listados
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: solicitacao.servicos.map<Widget>((s) {
                            final nome = s['nome'] ?? '';
                            final qtd = s['quantidade'] ?? 0;
                            final valor = s['valor_estimado'] ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "• $nome (x$qtd)",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "R\$ ${valor.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const Divider(height: 18, thickness: 0.6),

                        // 🔹 Rodapé: Data + Valor total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  dataFmt,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              solicitacao.valor > 0
                                  ? "Total: R\$ ${solicitacao.valor.toStringAsFixed(2)}"
                                  : "Aguardando valor",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
