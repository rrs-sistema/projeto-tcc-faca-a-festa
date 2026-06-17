import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../../controllers/orcamento_controller.dart';
import './../../../../data/models/model.dart';
import './../dialogs/show_responder_orcamento_dialog.dart';
import 'fornecedor_premium_layout.dart';

class OrcamentosSection extends StatelessWidget {
  OrcamentosSection({super.key});

  final controller = Get.find<OrcamentoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lista = controller.orcamentos;
      final emNegociacao = lista
          .where((o) =>
              o.status == StatusOrcamento.pendente || o.status == StatusOrcamento.emNegociacao)
          .toList();

      return PremiumSectionShell(
        title: 'Orçamentos em negociação',
        subtitle: 'Propostas abertas, valores em análise e respostas pendentes.',
        icon: Icons.handshake_outlined,
        color: FornecedorPremiumPalette.amber,
        trailing: emNegociacao.isEmpty
            ? null
            : PremiumPill(
                text: '${emNegociacao.length} aberto${emNegociacao.length == 1 ? '' : 's'}',
                color: FornecedorPremiumPalette.amber,
                icon: Icons.pending_actions_rounded,
              ),
        child: emNegociacao.isEmpty
            ? const PremiumEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Nenhum orçamento em aberto',
                message:
                    'Quando houver uma proposta em negociação, ela aparecerá aqui para acompanhamento comercial.',
                color: FornecedorPremiumPalette.emerald,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < emNegociacao.length; i++) ...[
                    _OrcamentoCard(orcamento: emNegociacao[i]),
                    if (i != emNegociacao.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
      );
    });
  }
}

class _OrcamentoCard extends StatelessWidget {
  final OrcamentoModel orcamento;

  const _OrcamentoCard({required this.orcamento});

  Color get corStatus {
    switch (orcamento.status) {
      case StatusOrcamento.pendente:
        return FornecedorPremiumPalette.amber;
      case StatusOrcamento.emNegociacao:
        return const Color(0xFF2563EB);
      case StatusOrcamento.fechado:
        return FornecedorPremiumPalette.emerald;
      default:
        return FornecedorPremiumPalette.muted;
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
    final valor = orcamento.custoEstimado != null
        ? 'R\$ ${orcamento.custoEstimado!.toStringAsFixed(2).replaceAll('.', ',')}'
        : 'Em análise';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: corStatus.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconeStatus, color: corStatus, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orcamento.nomeSolicitante ?? 'Solicitante',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: FornecedorPremiumPalette.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      orcamento.idCategoria ?? 'Categoria não informada',
                      style: GoogleFonts.poppins(
                          fontSize: 11.7, color: FornecedorPremiumPalette.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  valor,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    color: FornecedorPremiumPalette.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (orcamento.anotacoes != null && orcamento.anotacoes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              orcamento.anotacoes!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: FornecedorPremiumPalette.muted,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final status = PremiumPill(text: orcamento.status.label, color: corStatus);
              final button = OutlinedButton.icon(
                onPressed: () => showResponderOrcamentoDialog(context, orcamento: orcamento),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: Text(
                  'Responder',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FornecedorPremiumPalette.dark,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    status,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: button)
                  ],
                );
              }

              return Row(children: [status, const Spacer(), button]);
            },
          ),
        ],
      ),
    );
  }
}
