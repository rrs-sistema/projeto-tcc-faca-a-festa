import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/orcamento_controller.dart';
import './../dialogs/show_responder_orcamento_dialog.dart';
import './../../../../data/models/model.dart';

class OrcamentosSection extends StatelessWidget {
  const OrcamentosSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrcamentoController>();

    // Exemplo de ID de fornecedor — use o real no app
    const idFornecedor = 'id_fornecedor_teste';
    controller.escutarOrcamentos(idFornecedor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "📩 Orçamentos Recebidos",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final lista = controller.orcamentos;
          if (lista.isEmpty) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Text(
                "Nenhum orçamento recebido.",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _OrcamentoCard(orcamento: lista[i]),
          );
        }),
      ],
    );
  }
}

class _OrcamentoCard extends StatelessWidget {
  final OrcamentoModel orcamento;
  const _OrcamentoCard({required this.orcamento});

  Color get corStatus {
    switch (orcamento.status) {
      case StatusOrcamento.pendente:
        return Colors.orange.shade600;
      case StatusOrcamento.emNegociacao:
        return Colors.blue.shade600;
      case StatusOrcamento.fechado:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData get iconeStatus {
    switch (orcamento.status) {
      case StatusOrcamento.pendente:
        return Icons.hourglass_bottom_rounded;
      case StatusOrcamento.emNegociacao:
        return Icons.forum_outlined;
      case StatusOrcamento.fechado:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Cabeçalho (nome do serviço)
          Row(
            children: [
              Icon(iconeStatus, color: corStatus, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  orcamento.idOrcamento.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 🔹 Descrição / Observação
          if (orcamento.anotacoes != null && orcamento.anotacoes!.isNotEmpty)
            Text(
              orcamento.anotacoes!,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

          const SizedBox(height: 10),

          // 🔹 Rodapé (valor + status + botão)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Valor
              Text(
                orcamento.custoEstimado != null
                    ? "R\$ ${orcamento.custoEstimado!.toStringAsFixed(2)}"
                    : "Sem valor",
                style: GoogleFonts.poppins(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  orcamento.status.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: corStatus,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(thickness: 0.6),
          const SizedBox(height: 6),

          // 🔹 Botão de resposta
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showResponderOrcamentoDialog(context, orcamento: orcamento),
              icon: const Icon(Icons.reply_rounded, size: 16, color: Colors.teal),
              label: const Text("Responder"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
