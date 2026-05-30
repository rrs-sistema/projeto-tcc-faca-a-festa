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
        return Colors.orange.shade600;
      case 'respondido':
      case 'em_negociacao':
        return Colors.blue.shade600;
      case 'fechado':
        return Colors.green.shade600;
      case 'recusado':
        return Colors.red.shade500;
      case 'cancelada':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'aguardando':
      case 'pendente':
        return Icons.hourglass_empty_rounded;
      case 'respondido':
      case 'em_negociacao':
        return Icons.chat_bubble_outline_rounded;
      case 'fechado':
        return Icons.check_circle_outline_rounded;
      case 'recusado':
        return Icons.cancel_outlined;
      case 'cancelada':
        return Icons.remove_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(solicitacao.status.name);
    final icon = _statusIcon(solicitacao.status.name);
    final dataFmt = DateFormat('dd/MM/yyyy • HH:mm').format(solicitacao.dataCadastro);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.transparent,
          splashColor: color.withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === ÍCONE / STATUS (Minimalista) ===
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),

                // === CONTEÚDO PRINCIPAL ===
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: Solicitante + Badge Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              solicitacao.nomeUsuarioSolicitante,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey.shade900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              solicitacao.status.label.toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (solicitacao.categoriaNome != null &&
                          solicitacao.categoriaNome!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          solicitacao.categoriaNome!,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      if (solicitacao.descricao != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          solicitacao.descricao!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Serviços listados
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: solicitacao.servicos.map<Widget>((s) {
                          final nome = s['nome'] ?? '';
                          final qtd = s['quantidade'] ?? 0;
                          final valor = s['valor_estimado'] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "• $nome (x$qtd)",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "R\$ ${valor.toStringAsFixed(2)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 20, thickness: 0.5, color: Color(0xFFEEEEEE)),

                      // Rodapé: Data + Valor total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(
                                dataFmt,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            solicitacao.valorEstimadoTotal != null
                                ? "Total: R\$ ${Biblioteca.formatarValorDecimal(solicitacao.valorEstimadoTotal)}"
                                : "Aguardando",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color, // Usa a cor do status para dar peso ao valor final
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
    );
  }
}
