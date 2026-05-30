import 'package:app_faca_festa/controllers/app_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/orcamento_controller.dart';
import './../dialogs/show_responder_orcamento_dialog.dart';
import './../../../../data/models/model.dart';

class OrcamentosSection extends StatelessWidget {
  OrcamentosSection({super.key});

  final controller = Get.find<OrcamentoController>();
  final appController = Get.find<AppController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Orçamentos em Negociação",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final lista = controller.orcamentos;
          if (lista.isEmpty) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "Não existem orçamentos em aberto.",
                style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
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
        return Colors.orange.shade700;
      case StatusOrcamento.emNegociacao:
        return Colors.blue.shade700;
      case StatusOrcamento.fechado:
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData get iconeStatus {
    switch (orcamento.status) {
      case StatusOrcamento.pendente:
        return Icons.access_time_rounded;
      case StatusOrcamento.emNegociacao:
        return Icons.handshake_outlined;
      case StatusOrcamento.fechado:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconeStatus, color: corStatus, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        orcamento.nomeSolicitante?.toUpperCase() ?? 'SOLICITANTE',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                orcamento.custoEstimado != null
                    ? "R\$ ${orcamento.custoEstimado!.toStringAsFixed(2)}"
                    : "Em Análise",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          if (orcamento.anotacoes != null && orcamento.anotacoes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              orcamento.anotacoes!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // 🔹 WRAP NO FOOTER PARA PREVENIR OVERFLOW
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  orcamento.status.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: corStatus,
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: () => showResponderOrcamentoDialog(context, orcamento: orcamento),
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text("Responder",
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
