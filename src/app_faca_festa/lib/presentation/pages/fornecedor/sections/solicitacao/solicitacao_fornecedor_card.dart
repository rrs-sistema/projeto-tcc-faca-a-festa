import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/model.dart';
import '../../components/show_responder_cotacao_bottom_sheet.dart';

class SolicitacaoFornecedorCard extends StatelessWidget {
  final CotacaoModel solicitacao;
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
      case 'cancelada':
        return Colors.red.shade700; // 🔹 cor mais escura para cancelado
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
      case 'cancelada':
        return Icons.remove_circle_outline_rounded; // 🔹 ícone distinto de recusa
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(solicitacao.status.name);
    final icon = _statusIcon(solicitacao.status.name);
    final dataFmt = DateFormat('dd/MM/yyyy • HH:mm').format(solicitacao.dataCadastro);

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
            onTap: () {
              if (solicitacao.status == StatusCotacao.pendente) {
                showResponderCotacaoBottomSheet(
                  context: context,
                  idCotacao: solicitacao.id,
                  categoriaNome: solicitacao.categoriaNome ?? 'Categoria não informada',
                  descricao: solicitacao.descricao ?? 'Sem descrição',
                  nomeSolicitante: solicitacao.nomeUsuarioSolicitante,
                  dataLimite: dataFmt,
                  ofertaDesejada: Biblioteca.toDouble(solicitacao.valorEstimadoTotal.toString()),
                );
              }
            },
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
                                'Solicitante: ${solicitacao.nomeUsuarioSolicitante}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.5,
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
                                solicitacao.status.label.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: color,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (solicitacao.categoriaNome != null &&
                            solicitacao.categoriaNome!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Categoria: ${solicitacao.categoriaNome}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.5,
                                    color: Colors.grey.shade900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (solicitacao.descricao != null) ...[
                          const SizedBox(height: 4),
                          // 🔹 Mensagem ou descrição curta
                          Text(
                            'Descrição: ${solicitacao.descricao}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w200,
                              color: Colors.grey.shade900,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                              solicitacao.valorEstimadoTotal != null
                                  ? "Total: R\$ ${Biblioteca.formatarValorDecimal(solicitacao.valorEstimadoTotal)}"
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
